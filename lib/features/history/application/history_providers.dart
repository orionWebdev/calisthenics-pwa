import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/firestore_session_repository.dart';
import '../domain/history_summary.dart';
import '../domain/form_series.dart';
import '../domain/history_timeline.dart';
import '../domain/readiness.dart';
import '../domain/training_load.dart';
import '../domain/session_repository.dart';
import '../domain/training_session.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return FirestoreSessionRepository(FirebaseFirestore.instance);
});

/// Alle Einheiten des angemeldeten Nutzers, neueste zuerst.
///
/// Ohne Anmeldung ein leerer Strom statt eines Fehlers: Die Regeln würden
/// ohnehin mit `403` antworten, und „niemand angemeldet" ist kein Defekt. Ob
/// die App überhaupt etwas anzeigen darf, entscheidet der Anmeldezustand
/// weiter oben — nicht dieser Provider.
final sessionsProvider = StreamProvider<List<TrainingSession>>((ref) {
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
  );
});

/// Die Formkurve. Bewusst `autoDispose`: 180 Auswertungen über je 120 Tage
/// müssen nicht im Speicher bleiben, wenn niemand hinsieht.
final formSeriesProvider = Provider.autoDispose<FormSeries>((ref) {
  final sessions = ref.watch(sessionsProvider).value ?? const [];
  final weight = ref.watch(bodyWeightProvider).value ?? 0;
  return FormSeries.compute(
    sessions,
    ref.watch(historyReferenceProvider),
    context: LoadContext(bodyWeightKg: weight),
  );
});
