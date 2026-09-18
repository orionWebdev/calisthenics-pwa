@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/exercises/application/exercise_providers.dart';
import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:atem/features/exercises/domain/muscle.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/presentation/widgets/hard_sets_card.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/render.dart';

/// Sichtprüfung der Karte „Harte Sätze" mit echten Schriften.
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/hard_sets_render_test.dart
final _ref = DateTime(2026, 9, 18, 12);
DateTime _ago(int n) => DateTime(_ref.year, _ref.month, _ref.day - n, 18);

StrengthSession _s(int daysAgo, String id, List<int> rpes) => StrengthSession(
      id: 's$daysAgo$id',
      userId: 'u',
      date: _ago(daysAgo),
      createdAt: _ago(daysAgo),
      bodyweight: false,
      exercises: [
        LoggedExercise(exerciseId: id, sets: [
          for (final r in rpes) LoggedSet(reps: 8, rpe: r),
        ]),
      ],
    );

const _exercises = [
  Exercise(
    id: 'bench',
    name: 'Bankdrücken',
    source: ExerciseSource.curated,
    primaryMuscles: [MuscleGroup.chest],
    secondaryMuscles: [MuscleGroup.triceps],
  ),
  Exercise(
    id: 'pull_up',
    name: 'Klimmzug',
    source: ExerciseSource.curated,
    primaryMuscles: [MuscleGroup.back],
    secondaryMuscles: [MuscleGroup.biceps],
  ),
  Exercise(
    id: 'squat',
    name: 'Kniebeuge',
    source: ExerciseSource.curated,
    primaryMuscles: [MuscleGroup.legs],
  ),
];

final _filled = [
  _s(0, 'bench', [8, 8, 9, 7, 6]),
  _s(1, 'pull_up', [8, 8, 8, 5]),
  _s(3, 'squat', [7, 7, 6, 6]),
  _s(8, 'bench', [8, 8]),
  _s(9, 'squat', [8, 8, 8, 8]),
];

final _thin = [
  _s(0, 'bench', [8, 8, 6]),
];

void main() {
  final cases = [
    ('schwelle', _thin, 1.15, 361.0),
    ('gefuellt', _filled, 1.15, 361.0),
    ('gefuellt_200_320', _filled, 2.0, 320.0),
  ];

  for (final (name, sessions, scale, width) in cases) {
    testWidgets('rendert $name', (tester) async {
      if (!renderEnabled) return;
      await loadRealFonts();
      tester.view.physicalSize = Size(width, scale > 1.5 ? 1400 : 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sessionsProvider.overrideWith((_) => AsyncValue.data(sessions)),
          exercisesProvider.overrideWith((_) => Stream.value(_exercises)),
        ],
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AtemTheme.dark,
            locale: const Locale('de'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Scaffold(
              backgroundColor: AtemColors.base,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: HardSetsCard(sessions: sessions, reference: _ref),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await writePng(tester, key, 'hardsets_$name');
    });
  }
}
