import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/settings/domain/body_weight_preview.dart';
import 'package:flutter_test/flutter_test.dart';

final _heute = DateTime(2026, 8, 27);

/// Körpergewichtseinheiten — nur bei denen wirkt das Gewicht.
StrengthSession _bodyweight(String id, DateTime date) => StrengthSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      bodyweight: true,
      duration: const Duration(minutes: 45),
      // **`usesBodyweight` steht am Übungseintrag der Einheit**, nicht am
      // Katalog: Von 80 Formen im Produktivbestand tragen es 22. Der Katalog
      // trägt es in keinem einzigen der 154 Dokumente — der Rückfallpfad über
      // `LoadContext.bodyweightExerciseIds` greift also nie.
      exercises: const [
        LoggedExercise(
          exerciseId: 'pull_up',
          usesBodyweight: true,
          sets: [LoggedSet(reps: 10), LoggedSet(reps: 8)],
        ),
      ],
    );

/// Eine Cardio-Einheit — das Körpergewicht geht hier nicht ein.
CardioSession _cardio(String id, DateTime date) => CardioSession(
      id: id,
      userId: 'u',
      date: date,
      createdAt: date,
      duration: const Duration(minutes: 40),
      distanceKm: 8,
    );

List<TrainingSession> _history(TrainingSession Function(String, DateTime) make) =>
    [
      for (var i = 0; i < 30; i++)
        make('s$i', _heute.subtract(Duration(days: i * 3))),
    ];

void main() {
  test('mehr Gewicht heisst mehr Last bei Körpergewichtsübungen', () {
    final (before, after) = BodyWeightPreview.lastSessionLoad(
      _history(_bodyweight),
      currentKg: 78,
      candidateKg: 90,
    );
    expect(after, greaterThan(before));
  });

  test('an Cardio ändert das Körpergewicht nichts', () {
    final (before, after) = BodyWeightPreview.lastSessionLoad(
      _history(_cardio),
      currentKg: 78,
      candidateKg: 90,
    );
    expect(after, before);
  });

  test('eine spürbare Änderung verschiebt den Formwert', () {
    final preview = BodyWeightPreview.compute(
      _history(_bodyweight),
      _heute,
      currentKg: 78,
      candidateKg: 95,
    );
    expect(preview.formBefore, isNotNull);
    expect(preview.formAfter, isNotNull);
  });

  test('dasselbe Gewicht ändert nichts', () {
    final preview = BodyWeightPreview.compute(
      _history(_bodyweight),
      _heute,
      currentKg: 78,
      candidateKg: 78,
    );
    expect(preview.formChanges, isFalse);
    expect(preview.acwrChanges, isFalse);
    expect(preview.fitnessChanges, isFalse);
  });

  test('ohne Historie gibt es nichts zu zeigen', () {
    final preview = BodyWeightPreview.compute(
      const [],
      _heute,
      currentKg: 78,
      candidateKg: 95,
    );
    expect(preview.formChanges, isFalse);
    expect(preview.acwrChanges, isFalse);

    final (before, after) = BodyWeightPreview.lastSessionLoad(
      const [],
      currentKg: 78,
      candidateKg: 95,
    );
    expect(before, 0);
    expect(after, 0);
  });

  test('beide Seiten rechnen gegen denselben Tag', () {
    final sessions = _history(_bodyweight);
    final preview = BodyWeightPreview.compute(
      sessions,
      _heute,
      currentKg: 78,
      candidateKg: 95,
    );
    expect(preview.before.sessions, preview.after.sessions);
    expect(preview.before.daysSinceLast, preview.after.daysSinceLast,
        reason: 'nur der Maßstab ändert sich, nicht der Bestand');
  });
}
