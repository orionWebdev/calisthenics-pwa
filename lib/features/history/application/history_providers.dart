import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/firestore_session_repository.dart';
import '../domain/history_summary.dart';
import '../domain/history_timeline.dart';
import '../domain/readiness.dart';
import '../domain/training_load.dart';
import '../domain/session_filter.dart';
import '../domain/session_repository.dart';
import '../domain/training_session.dart';
import 'pending_deletion.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return FirestoreSessionRepository(FirebaseFirestore.instance);
});

/// Alle Einheiten des angemeldeten Nutzers, neueste zuerst.
///
/// Ohne Anmeldung ein leerer Strom statt eines Fehlers: Die Regeln würden
/// ohnehin mit `403` antworten, und „niemand angemeldet" ist kein Defekt. Ob
/// die App überhaupt etwas anzeigen darf, entscheidet der Anmeldezustand
/// weiter oben — nicht dieser Provider.
/// **Kein `StreamProvider`, sondern eine Ableitung darüber.** Ein zweiter
/// Strom müsste die Firestore-Abfrage erneut aufsetzen, sobald sich der
/// Löschzustand ändert — ein Widerruf löste dann eine Neuabfrage aus und die
/// Liste flackerte durch den Ladezustand. Als reine Ableitung passiert
/// stattdessen genau das Richtige: Das Filtern läuft neu, die Abfrage nicht.
///
/// Die Aufrufstellen merken davon nichts: Ein `AsyncValue` verhält sich an
/// `when`, `value` und `hasError` gleich, gleich woher es kommt.
final sessionsProvider = Provider<AsyncValue<List<TrainingSession>>>((ref) {
  final pending = ref.watch(pendingDeletionProvider)?.sessionId;
  return ref.watch(sessionStreamProvider).whenData((sessions) {
    if (pending == null) return sessions;
    return [
      for (final session in sessions)
        if (session.id != pending) session,
    ];
  });
});

/// Der rohe Strom aus Firestore, ohne den Löschfilter.
///
/// Getrennt, damit [sessionsProvider] die schwebende Löschung ausblenden kann,
/// **ohne** dass ein Widerruf eine neue Abfrage auslöst. Die Trennung ist der
/// Grund, warum das Zurückspringen sofort geschieht und nichts nachlädt.
final sessionStreamProvider = StreamProvider<List<TrainingSession>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(sessionRepositoryProvider).watchSessions(userId);
});

/// Alles, was der Verlaufs-Tab braucht — an einer Stelle gerechnet.
///
/// Der Stichtag kommt aus [historyReferenceProvider], damit Tests ihn setzen
/// können, ohne dass jeder Bildschirm ein Datum durchreicht.
final historySummaryProvider = Provider<HistorySummary>((ref) {
  final sessions = ref.watch(sessionsProvider).value ?? const [];
  // Ohne Körpergewicht rechnet jede Körpergewichtsübung mit einer Last von
  // null. Solange das Profil lädt, gilt 0 — der Wert bessert sich, sobald es
  // da ist, und die Rechnung läuft erneut.
  final weight = ref.watch(bodyWeightProvider).value ?? 0;
  return HistorySummary.from(
    sessions,
    ref.watch(historyReferenceProvider),
    context: LoadContext(bodyWeightKg: weight),
  );
});

/// Der Stichtag. In Tests überschreibbar, sonst schlicht heute.
final historyReferenceProvider = Provider<DateTime>((ref) => DateTime.now());

/// Das Körpergewicht aus dem Profil — ohne es rechnet jede
/// Körpergewichtsübung mit einer Last von null.
final bodyWeightProvider = FutureProvider<double?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).bodyWeightKg(userId);
});

/// Die Verlaufsliste: Einheiten, Monatsköpfe und die Lücken dazwischen.
final historyTimelineProvider = Provider<List<TimelineEntry>>((ref) {
  final sessions = ref.watch(sessionsProvider).value ?? const [];
  final weight = ref.watch(bodyWeightProvider).value ?? 0;
  final context = LoadContext(bodyWeightKg: weight);

  // Die Tageslast einmal vorrechnen: Der Monatskopf summiert sie, und ohne
  // Zwischenspeicher liefe die Rechnung je Monat erneut über alle Einheiten.
  final loadByDay = <String, double>{};
  for (final session in sessions) {
    final key = Readiness.dayKey(session.date);
    loadByDay[key] = (loadByDay[key] ?? 0) + TrainingLoad.of(session, context);
  }

  return HistoryTimeline.build(
    sessions,
    ref.watch(historyReferenceProvider),
    loadByDay: loadByDay,
    loadOf: (s) => TrainingLoad.of(s, context),
  );
});


/// Ob der zuletzt gelieferte Stand aus dem lokalen Zwischenspeicher stammt.
///
/// Ein eigener Strom auf derselben Abfrage — er hört auch auf reine
/// Metadaten-Änderungen und meldet deshalb, wenn der Server antwortet, ohne
/// dass sich Daten ändern. Ohne Anmeldung nie „offline": Ohne `userId` gibt
/// es keine Abfrage, deren Herkunft man beurteilen könnte.
final offlineStreamProvider = StreamProvider<bool>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(false);
  return ref.watch(sessionRepositoryProvider).watchFromCache(userId);
});

/// Solange die erste Antwort aussteht, gilt „nicht offline": Ein Band, das
/// beim Start aufblitzt, ist eine Falschmeldung mit Ansage.
final offlineProvider =
    Provider<bool>((ref) => ref.watch(offlineStreamProvider).value ?? false);

/// Der Filter der Einheitenliste.
class SessionFilterController extends Notifier<SessionFilter> {
  @override
  SessionFilter build() => SessionFilter.none;

  /// Nochmal auf dieselbe Art tippen hebt sie auf — sonst müsste man den
  /// „Alle"-Chip suchen.
  void toggleKind(SessionKind kind) =>
      state = state.withKind(state.kind == kind ? null : kind);

  /// „Alle" hebt nur die Art auf, nicht den Zeitraum — der Chip steht in der
  /// Artenreihe und verspricht nichts über den Monat.
  void clearKind() => state = state.withKind(null);

  void setPeriod(int year, int month) => state = state.withPeriod(year, month);

  void clearPeriod() => state = state.withPeriod(null, null);

  void clear() => state = SessionFilter.none;
}

final sessionFilterProvider =
    NotifierProvider<SessionFilterController, SessionFilter>(
  SessionFilterController.new,
);

/// Die gefilterte Verlaufsliste.
///
/// Der Filter greift **vor** dem Bauen der Zeitachse, nicht danach: Monatsköpfe
/// und Lückenstreifen sollen die gefilterte Menge beschreiben, nicht die volle.
/// Eine Lücke „74 Tage" zwischen zwei Krafteinheiten ist etwas anderes als
/// eine zwischen zwei Einheiten überhaupt.
final filteredTimelineProvider = Provider<List<TimelineEntry>>((ref) {
  final filter = ref.watch(sessionFilterProvider);
  if (filter.isEmpty) return ref.watch(historyTimelineProvider);

  final sessions = filter.apply(ref.watch(sessionsProvider).value ?? const []);
  final weight = ref.watch(bodyWeightProvider).value ?? 0;
  final context = LoadContext(bodyWeightKg: weight);

  final loadByDay = <String, double>{};
  for (final session in sessions) {
    final key = Readiness.dayKey(session.date);
    loadByDay[key] = (loadByDay[key] ?? 0) + TrainingLoad.of(session, context);
  }

  return HistoryTimeline.build(
    sessions,
    ref.watch(historyReferenceProvider),
    loadByDay: loadByDay,
    loadOf: (s) => TrainingLoad.of(s, context),
  );
});
