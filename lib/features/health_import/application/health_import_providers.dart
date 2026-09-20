import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/health_gateway.dart';
import '../../auth/application/auth_providers.dart';
import '../../history/application/history_providers.dart';
import '../../history/domain/training_session.dart';
import '../../weight/application/weight_providers.dart';
import '../../weight/application/weight_sync_providers.dart';
import '../../weight/domain/weight_entry.dart';
import '../data/firestore_health_session_repository.dart';
import '../domain/health_access.dart';
import '../domain/health_session.dart';
import '../domain/health_session_repository.dart';
import '../domain/import_action.dart';
import '../domain/import_inbox.dart';
import '../domain/session_pairing.dart';

final healthSessionRepositoryProvider = Provider<HealthSessionRepository>(
  (ref) => FirestoreHealthSessionRepository(FirebaseFirestore.instance),
);

/// Alle bekannten Uhr-Datensätze des angemeldeten Kontos.
///
/// Ohne Anmeldung eine leere Liste statt eines Fehlers — dieselbe Haltung wie
/// bei der Gewichtsreihe.
final healthSessionsProvider = StreamProvider<List<HealthSession>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(healthSessionRepositoryProvider).watch(userId);
});

/// Was im Eingang steht.
///
/// **Der Eingang rendert nicht, wenn nichts wartet** (Modul 5). Diese Klasse
/// trägt deshalb kein „leer"-Flag: [pending] ist dann schlicht leer, und die
/// Oberfläche hört früher auf.
class HealthInbox {
  const HealthInbox({
    required this.pending,
    required this.declined,
    this.lastRead,
  });

  static const empty = HealthInbox(pending: [], declined: []);

  /// Wartende Datensätze, jüngste zuerst.
  final List<HealthSession> pending;

  /// Abgelehnte — sie liegen am Fuss des Eingangs, nicht im Verlauf.
  /// Abgelehnt ist keine Einheit.
  final List<HealthSession> declined;

  final DateTime? lastRead;

  bool get isEmpty => pending.isEmpty;
}

final healthInboxProvider = Provider<HealthInbox>((ref) {
  final sessions = ref.watch(healthSessionsProvider).value ?? const [];
  final pending = [
    for (final s in sessions)
      if (s.state == HealthSessionState.pending) s,
  ]..sort((a, b) => b.start.compareTo(a.start));
  final declined = [
    for (final s in sessions)
      if (s.state == HealthSessionState.rejected) s,
  ]..sort((a, b) => b.start.compareTo(a.start));

  return HealthInbox(
    pending: pending,
    declined: declined,
    lastRead: ref.watch(healthLastReadProvider).value,
  );
});

/// Die Lesemarke aus dem Profil.
final healthLastReadProvider = FutureProvider<DateTime?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  // Der Eingang ändert sie — deshalb hängt sie am Strom der Datensätze.
  ref.watch(healthSessionsProvider);
  return ref.watch(healthSessionRepositoryProvider).lastRead(userId);
});

/// Liest Health Connect und verbucht, was jemand entschieden hat.
///
/// ## Gelesen wird beim Öffnen, nicht im Hintergrund
///
/// Kein Dienst, keine Benachrichtigung, keine Berechtigung mehr (Board 15,
/// Entscheidung 3). Wer die App öffnet, löst das Lesen aus; wer sie nicht
/// öffnet, verpasst nichts — die Einheit läuft nicht weg.
///
/// ## Gefragt wird nur, wer gefragt hat
///
/// [refresh] öffnet den Systemdialog **nur** mit `askForAccess`. Ein Lesen,
/// das von sich aus fragt, überfällt jeden, der die App aus einem anderen
/// Grund gestartet hat — dieselbe Regel wie beim Gewichtsabgleich.
class HealthImportController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> refresh({bool askForAccess = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _refresh(askForAccess));
  }

  Future<void> _refresh(bool askForAccess) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final gateway = ref.read(healthGatewayProvider);
    if (await gateway.availability() != HealthAvailability.available) return;

    var granted = await gateway.hasSessionAccess() ?? false;
    if (!granted && askForAccess) {
      granted = await gateway.requestSessionAccess();
    }
    if (!granted) return;

    final repo = ref.read(healthSessionRepositoryProvider);
    final known = await repo.fetch(userId);
    final now = DateTime.now();
    final from =
        ImportInbox.readFrom(now, lastRead: await repo.lastRead(userId));

    final measured = await gateway.readSessions(from: from, to: now);
    final fresh = ImportInbox.pending(
      measured: measured,
      // Alles, was ATEM schon kennt — übernommen **oder** abgelehnt. Beide
      // dürfen nicht ein zweites Mal im Eingang landen.
      importedIds: {
        for (final k in known)
          if (k.state != HealthSessionState.pending) k.externalId,
      },
      rejectedIds: const {},
      ownSourceId: await gateway.ownSourceId(),
    );

    for (final session in fresh) {
      // Wartende, die schon liegen, nicht überschreiben: Ihr `seenAt` ist
      // das erste Lesen, nicht das letzte.
      if (known.any((k) => k.externalId == session.id)) continue;
      await repo.save(userId, HealthSession.pending(session, now));
    }

    // Die Marke erst danach — bricht das Schreiben ab, wird beim nächsten
    // Öffnen derselbe Zeitraum noch einmal gelesen. Das ist harmlos (die
    // Kennung macht jeden Datensatz eindeutig), ein Verlust wäre es nicht.
    await repo.markRead(userId, now);
    ref.invalidate(healthLastReadProvider);
  }

  /// Übernehmen: Die Einheit entsteht, der Uhr-Datensatz bleibt liegen.
  Future<void> accept(
    HealthSession session, {
    int? rpe,
    String? note,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final id = await ref.read(sessionRepositoryProvider).saveSession(
          ImportAction.draftOf(
            session: session,
            userId: userId,
            rpe: rpe,
            note: note,
          ),
        );

    await ref.read(healthSessionRepositoryProvider).save(
          userId,
          session.copyWith(
            state: HealthSessionState.accepted,
            sessionId: id,
            decidedAt: DateTime.now(),
          ),
        );
  }

  /// Ablehnen: gemerkt, nicht gelöscht.
  Future<void> decline(HealthSession session) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref.read(healthSessionRepositoryProvider).save(
          userId,
          session.copyWith(
            state: HealthSessionState.rejected,
            decidedAt: DateTime.now(),
            clearSession: true,
          ),
        );
  }

  /// Zusammenführen: Die App-Einheit bekommt **nur einen Verweis**.
  ///
  /// Puls und Kalorien bleiben am Uhr-Datensatz — keine Grösse hat zwei
  /// Quellen, und nur deshalb ist das Lösen verlustfrei (Entscheidung 1
  /// und 9).
  Future<void> merge(HealthSession measured, TrainingSession session) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await ref
        .read(sessionRepositoryProvider)
        .linkHealthSession(session.id, measured.externalId);

    await ref.read(healthSessionRepositoryProvider).save(
          userId,
          measured.copyWith(
            state: HealthSessionState.accepted,
            sessionId: session.id,
            decidedAt: DateTime.now(),
          ),
        );
  }

  /// Verbindung lösen: Der Verweis fällt weg, die Uhr-Einheit geht **zurück
  /// in den Eingang**.
  ///
  /// Nichts wird gelöscht und nichts zurückgerechnet — die Einheit verliert
  /// genau das, was sie aus der Verknüpfung hatte.
  Future<void> unlink(HealthSession measured, String sessionId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await ref
        .read(sessionRepositoryProvider)
        .linkHealthSession(sessionId, null);

    await ref.read(healthSessionRepositoryProvider).save(
          userId,
          measured.copyWith(
            state: HealthSessionState.pending,
            clearSession: true,
          ),
        );
  }

  /// „Doch übernehmen" — zurück in den Eingang.
  Future<void> restore(HealthSession session) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref.read(healthSessionRepositoryProvider).save(
          userId,
          session.copyWith(
            state: HealthSessionState.pending,
            clearSession: true,
          ),
        );
  }
}

final healthImportControllerProvider =
    NotifierProvider<HealthImportController, AsyncValue<void>>(
  HealthImportController.new,
);

/// Was der Abgleich über eine wartende Uhr-Einheit sagt.
///
/// Die Vermutung wird **hier** gerechnet und nicht im Blatt: Sie hängt am
/// ganzen Bestand, nicht am Bildschirm, und sie ist dieselbe, egal wer
/// fragt.
final pairVerdictProvider =
    Provider.family<PairVerdict, HealthSession>((ref, measured) {
  final sessions = ref.watch(sessionsProvider).value ?? const [];
  return SessionPairing.verdict(
    measured: MeasuredSession(
      id: measured.externalId,
      start: measured.start,
      end: measured.end,
      sourceId: measured.sourceId,
    ),
    // Eine Einheit, die schon an einer Uhr-Einheit hängt, ist kein Kandidat
    // mehr — sonst böte die App an, sie ein zweites Mal zu verknüpfen.
    sessions: [
      for (final s in sessions)
        if (s.healthSessionId == null) s,
    ],
  );
});

/// Der Zustand beider Berechtigungszeilen (Board 15, D).
///
/// Er wird **gefragt, nicht gemerkt**: Eine Berechtigung kann in den
/// Systemeinstellungen zurückgenommen werden, ohne dass die App etwas davon
/// erfährt. Ein gespeicherter Zustand wäre also regelmässig gelogen.
final healthAccessProvider = FutureProvider<HealthAccessState>((ref) async {
  final gateway = ref.watch(healthGatewayProvider);
  final availability = await gateway.availability();

  // Ohne erreichbare Quelle keine zwei Fragen — und kein Systemdialog, der
  // ins Leere führte.
  if (availability != HealthAvailability.available) {
    return HealthAccessState.of(
      availability: availability,
      weightGranted: false,
      sessionsGranted: false,
      importedSessions: 0,
      measuredWeights: 0,
    );
  }

  final known = ref.watch(healthSessionsProvider).value ?? const [];
  final series = ref.watch(weightSeriesProvider).value;

  return HealthAccessState.of(
    availability: availability,
    weightGranted: await gateway.hasWeightAccess(),
    sessionsGranted: await gateway.hasSessionAccess(),
    importedSessions: [
      for (final s in known)
        if (s.state == HealthSessionState.accepted) s,
    ].length,
    measuredWeights: series == null
        ? 0
        : [
            for (final e in series.entries)
              if (e.source == WeightSource.healthConnect) e,
          ].length,
    lastRead: ref.watch(healthLastReadProvider).value,
  );
});

/// Eine Zusammenführung, die noch gezeigt werden will (Board 15, B6).
///
/// Der Schreibvorgang ist längst durch, wenn das Blatt sich schliesst — ohne
/// diesen Zustand stünde die Liste einfach mit einer Zeile weniger da. Hier
/// liegt die Momentaufnahme der Uhr-Einheit, damit die Liste die **beiden**
/// Zeilen noch einmal zeigen und sie ineinander laufen lassen kann.
class MergeAnimation {
  const MergeAnimation({required this.sessionId, required this.measured});

  /// Die App-Einheit, die bleibt.
  final String sessionId;

  /// Die Uhr-Einheit, wie sie vor der Entscheidung aussah.
  final HealthSession measured;
}

/// **Höchstens eine zur Zeit.** Wer einen Stapel durchgeht und zweimal
/// zusammenführt, sieht die letzte Bewegung — die einzige, die beim
/// Schliessen des Blatts noch auf dem Bildschirm liegt. Zwei Bewegungen
/// nacheinander abzuspielen hiesse, den Nutzer auf eine Animation warten zu
/// lassen, die er nicht angefordert hat.
class MergeAnimationController extends Notifier<MergeAnimation?> {
  @override
  MergeAnimation? build() => null;

  void arm(String sessionId, HealthSession measured) =>
      state = MergeAnimation(sessionId: sessionId, measured: measured);

  void done() => state = null;
}

final mergeAnimationProvider =
    NotifierProvider<MergeAnimationController, MergeAnimation?>(
  MergeAnimationController.new,
);
