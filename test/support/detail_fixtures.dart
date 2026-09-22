import 'package:atem/core/domain/health_gateway.dart';
import 'package:atem/core/domain/pulse_profile.dart';
import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/exercises/application/exercise_providers.dart';
import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/health_import/application/health_import_providers.dart';
import 'package:atem/features/health_import/domain/health_session.dart';
import 'package:atem/features/health_import/domain/health_session_repository.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/pulse/domain/heart_rate_zones.dart';
import 'package:atem/features/settings/application/settings_providers.dart';
import 'package:atem/features/settings/domain/settings_repository.dart';
import 'package:atem/features/settings/domain/user_settings.dart';

import 'a11y.dart';

/// Die Fixtures des Einheitendetails (Board 16) — jede Art, jeder Zustand.
///
/// Sie stehen an einer Stelle, weil Renderprüfung, Verhaltenstest und
/// Barrierefreiheitsmatrix **dieselben** Einheiten sehen müssen. Getrennt
/// gebaute Fassungen prüften irgendwann verschiedene Dinge.
class DetailSettings implements SettingsRepository {
  DetailSettings(this.current);

  UserSettings current;

  @override
  Stream<UserSettings> watch(String userId) => Stream.value(current);
  @override
  Future<UserSettings> fetch(String userId) async => current;
  @override
  Future<void> save(String userId, UserSettings settings) async {}
}

class DetailHealth implements HealthSessionRepository {
  DetailHealth(this.records, {this.fails = false, this.hangs = false});

  final List<HealthSession> records;
  final bool fails;
  final bool hangs;

  @override
  Stream<List<HealthSession>> watch(String userId) {
    if (hangs) return const Stream.empty();
    if (fails) return Stream.error(StateError('nicht lesbar'));
    return Stream.value(records);
  }

  /// Dieselben Datensätze **ohne Pulsverlauf** — Uhr-Einheiten, die vor dem
  /// Nachtragen gelesen wurden.
  DetailHealth withoutPulse() => DetailHealth([
        for (final r in records)
          HealthSession(
            externalId: r.externalId,
            state: r.state,
            start: r.start,
            end: r.end,
            sourceId: r.sourceId,
            seenAt: r.seenAt,
            calories: r.calories,
            sessionId: r.sessionId,
          ),
      ]);

  @override
  Future<List<HealthSession>> fetch(String userId) async => records;
  @override
  Future<void> save(String userId, HealthSession session) async {}
  @override
  Future<void> delete(String userId, String externalId) async {}
  @override
  Future<DateTime?> lastRead(String userId) async =>
      DateTime(2026, 9, 20, 7, 12);
  @override
  Future<void> markRead(String userId, DateTime at) async {}
}

class DetailSessions extends FakeSessionRepository {
  DetailSessions(this.sessions);

  final List<TrainingSession> sessions;

  @override
  Stream<List<TrainingSession>> watchSessions(String userId) =>
      Stream.value(sessions);
  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async => sessions;
}

class DetailExercises extends FakeExerciseRepository {
  @override
  Stream<List<Exercise>> watchExercises(String userId) => Stream.value(const [
        Exercise(
            id: 'bench', name: 'Bankdrücken', source: ExerciseSource.curated),
        Exercise(
            id: 'press',
            name: 'Schulterdrücken',
            source: ExerciseSource.curated),
        Exercise(id: 'dips', name: 'Dips', source: ExerciseSource.curated),
      ]);
}

final detailZones = HeartRateZones.tryFrom(const [112, 131, 149, 168])!;

UserSettings detailSettings({bool withZones = true}) => UserSettings(
      heartRate: HeartRateSettings(
        hrMax: 186,
        hrMaxSetAt: DateTime(2026, 9, 2),
        zones: withZones ? detailZones : null,
        zonesSetAt: withZones ? DateTime(2026, 9, 12) : null,
      ),
    );

/// Pulsverlauf einer 52-Minuten-Einheit mit der Verteilung des Boards.
PulseProfile detailPulse({int recordedMinutes = 52}) {
  final full = <int, int>{
    100: 6 * 60 + 10,
    120: 11 * 60 + 40,
    140: 21 * 60 + 30,
    160: 9 * 60 + 20,
    175: 3 * 60 + 20,
  };
  if (recordedMinutes >= 52) {
    return PulseProfile(
        secondsByBpm: {...full, 62: 30}, windowSeconds: 52 * 60);
  }
  // C1: 21 von 52 Minuten — nur die mittleren Zonen.
  return const PulseProfile(
    secondsByBpm: {120: 8 * 60 + 10, 140: 10 * 60 + 40, 160: 2 * 60 + 10},
    windowSeconds: 52 * 60,
  );
}

/// Dieselbe Einheit wie [detailPulse], mit Zeitachse — Einheiten, die nach
/// dem 22.09.2026 gelesen wurden. Eine Lücke von Minute 20 bis 29 zeigt die
/// leere Spur mittendrin.
PulseProfile detailPulseWithCurve() => PulseProfile(
      secondsByBpm: {
        100: 6 * 60 + 10,
        120: 11 * 60 + 40,
        140: 21 * 60 + 30,
        160: 9 * 60 + 20,
        175: 3 * 60 + 20,
        62: 30,
      },
      windowSeconds: 52 * 60,
      curveBpmByMinute: {
        for (var m = 0; m <= 19; m++) m: 100 + m * 3,
        // Lücke: die Uhr hat 20 bis 29 nichts gemessen.
        for (var m = 30; m <= 51; m++) m: 175 - (m - 30) * 3,
      },
    );

HealthSession detailRecord({PulseProfile? pulse}) => HealthSession.pending(
      MeasuredSession(
        id: 'hc-1',
        start: DateTime(2026, 9, 18, 18, 40),
        end: DateTime(2026, 9, 18, 19, 38),
        sourceId: 'com.garmin.android.apps.connectmobile',
        averageHeartRate: 118,
        maxHeartRate: 164,
        calories: 412,
        pulse: pulse ?? detailPulse(),
      ),
      DateTime(2026, 9, 20, 7, 12),
    ).copyWith(state: HealthSessionState.accepted, sessionId: 'a1');

final detailBefore = StrengthSession(
  id: 'vor',
  userId: 'u',
  date: DateTime(2026, 9, 11),
  createdAt: DateTime(2026, 9, 11),
  startedAt: DateTime(2026, 9, 11, 18),
  duration: const Duration(minutes: 50),
  bodyweight: false,
  exercises: const [
    LoggedExercise(
        exerciseId: 'bench', sets: [LoggedSet(reps: 8, weight: 77.5)]),
    LoggedExercise(
        exerciseId: 'press', sets: [LoggedSet(reps: 12, weight: 32)]),
  ],
);

final detailMerged = StrengthSession(
  id: 'a1',
  userId: 'u',
  date: DateTime(2026, 9, 18),
  createdAt: DateTime(2026, 9, 18),
  startedAt: DateTime(2026, 9, 18, 18, 42),
  duration: const Duration(minutes: 52),
  rpe: 4,
  bodyweight: false,
  planName: 'Push A',
  notes: 'Zweite Hälfte schwer, Schulter links zickt beim Drücken.',
  healthSessionId: 'hc-1',
  exercises: [
    const LoggedExercise(exerciseId: 'bench', sets: [
      LoggedSet(reps: 8, weight: 80),
      LoggedSet(reps: 8, weight: 80),
      LoggedSet(reps: 8, weight: 80),
    ]),
    const LoggedExercise(exerciseId: 'press', sets: [
      LoggedSet(reps: 10, weight: 32),
      LoggedSet(reps: 10, weight: 32),
      LoggedSet(reps: 10, weight: 32),
      LoggedSet(reps: 10, weight: 32),
    ]),
    const LoggedExercise(exerciseId: 'dips', sets: [
      LoggedSet(reps: 12),
      LoggedSet(reps: 12),
      LoggedSet(reps: 12),
    ]),
  ],
);

final detailRun = CardioSession(
  id: 'run',
  userId: 'u',
  date: DateTime(2026, 9, 20),
  createdAt: DateTime(2026, 9, 20),
  startedAt: DateTime(2026, 9, 20, 9, 4),
  duration: const Duration(minutes: 48),
  distanceKm: 8.42,
  activity: CardioActivity.run,
  fromHealth: true,
  healthSessionId: 'hc-run',
);

final detailRecovery = RecoverySession(
  id: 'rec',
  userId: 'u',
  date: DateTime(2026, 9, 17),
  createdAt: DateTime(2026, 9, 17),
  startedAt: DateTime(2026, 9, 17, 21, 10),
  duration: const Duration(minutes: 30),
);

final detailBare = StrengthSession(
  id: 'bare',
  userId: 'u',
  date: DateTime(2026, 9, 4),
  createdAt: DateTime(2026, 9, 4),
  bodyweight: false,
);

/// Der Uhr-Datensatz der Laufeinheit — Puls und Kalorien, keine Sätze.
HealthSession detailRunRecord() => HealthSession.pending(
      MeasuredSession(
        id: 'hc-run',
        start: DateTime(2026, 9, 20, 9, 4),
        end: DateTime(2026, 9, 20, 9, 52),
        sourceId: 'com.garmin.android.apps.connectmobile',
        calories: 604,
        pulse: const PulseProfile(
          secondsByBpm: {110: 80, 130: 310, 145: 1360, 160: 990, 172: 140},
          windowSeconds: 48 * 60,
        ),
      ),
      DateTime(2026, 9, 20, 10),
    ).copyWith(state: HealthSessionState.accepted);

/// Die Fixture **mit ausgetauschten Quellen** für eine Einheit.
///
/// Ein Provider darf nicht zweimal überschrieben werden — deshalb ersetzt
/// diese Liste die Einträge der Fixture, statt sie zu ergänzen. Die Stellen
/// stehen in `fixtureOverrides`: 4 Übungen, 6 Einheiten, 7 Einstellungen.
List<Object> detailOverrides({
  required TrainingSession session,
  required UserSettings settings,
  required HealthSessionRepository health,
}) =>
    [
      for (var i = 0; i < fixtureOverrides.length; i++)
        if (i != 4 && i != 6 && i != 7) fixtureOverrides[i],
      sessionRepositoryProvider
          .overrideWithValue(DetailSessions([detailBefore, session])),
      settingsRepositoryProvider.overrideWithValue(DetailSettings(settings)),
      exerciseRepositoryProvider.overrideWithValue(DetailExercises()),
      healthSessionRepositoryProvider.overrideWithValue(health),
      currentUserIdProvider.overrideWithValue('u'),
    ];
