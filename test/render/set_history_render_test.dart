@Tags(['render'])
library;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/core/widgets/widgets.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/workout/presentation/widgets/set_history_drop.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/render.dart';

/// Sichtprüfung der Satzhistorie im Runner (23.09.2026).
StrengthSession _s(String id, DateTime d, List<LoggedSet> sets) =>
    StrengthSession(
      id: id,
      userId: 'u',
      date: d,
      createdAt: d,
      bodyweight: false,
      duration: const Duration(minutes: 40),
      exercises: [LoggedExercise(exerciseId: 'bench', sets: sets)],
    );

void main() {
  for (final (width, scale) in [(361.0, 1.15), (320.0, 2.0)]) {
    testWidgets('rendert satzhistorie_${width.round()}', (tester) async {
      if (!renderEnabled) return;
      await loadRealFonts();
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sessionsProvider.overrideWithValue(AsyncData([
            _s('a', DateTime(2026, 9, 21), const [
              LoggedSet(reps: 8, weight: 80),
              LoggedSet(reps: 7, weight: 80),
              LoggedSet(reps: 6, weight: 80),
              LoggedSet(reps: 6, weight: 77.5),
            ]),
            _s('b', DateTime(2026, 9, 14), const [
              LoggedSet(reps: 8, weight: 77.5),
              LoggedSet(reps: 8, weight: 77.5),
            ]),
          ])),
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
            home: const Scaffold(
              backgroundColor: AtemColors.base,
              body: Padding(
                padding: EdgeInsets.all(16),
                child: SetHistoryDrop(
                    exerciseId: 'bench', exerciseName: 'Bankdrücken'),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AtemTappable));
      await tester.pumpAndSettle();
      await writePng(tester, key, 'satzhistorie_${width.round()}');
    });
  }
}
