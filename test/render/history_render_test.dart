@Tags(['render'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:atem/core/theme/theme.dart';
import 'package:atem/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/presentation/widgets/analysis_section.dart';
import 'package:atem/features/history/presentation/widgets/history_section.dart';
import 'package:atem/features/history/presentation/screens/muscle_balance_screen.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/render.dart';

/// Sichtprüfung von Verlauf, Auswertung, Muskelbalance und Übungsverlauf
/// mit echten Schriften — reich und im dünnen Zustand des Nutzers.
///
///   ATEM_RENDER_DIR=/pfad flutter test test/render/history_render_test.dart
///
/// Je Bildschirm mehrere Aufnahmen einer Honor-Höhe (361 × 780 dp,
/// Schrift 1,15), zwischen den Aufnahmen wird gescrollt.
class _ThinSessions extends FakeSessionRepository {
  static final sessions = <TrainingSession>[
    StrengthSession(
      id: 't1',
      userId: 'u',
      date: DateTime(2026, 8, 25, 18),
      createdAt: DateTime(2026, 8, 25, 18),
      bodyweight: true,
      duration: const Duration(minutes: 26),
      planName: 'Pull - Home',
      exercises: const [
        LoggedExercise(exerciseId: 'archer_push_up', sets: [
          LoggedSet(reps: 8, rawType: 'warmup'),
          LoggedSet(reps: 9),
          LoggedSet(reps: 8),
          LoggedSet(reps: 9),
        ]),
      ],
    ),
    RecoverySession(
      id: 't2',
      userId: 'u',
      date: DateTime(2026, 8, 26, 9),
      createdAt: DateTime(2026, 8, 26, 9),
      duration: const Duration(minutes: 15),
    ),
  ];

  @override
  Stream<List<TrainingSession>> watchSessions(String userId) =>
      Stream.value(sessions);

  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async => sessions;
}

/// Wie `writePng`, aber mit Wiederholung: `toByteData` liefert im
/// Testbinding gelegentlich `null`, wenn der Frame noch nicht gezeichnet ist.
Future<void> _shot(WidgetTester tester, GlobalKey key, String name) async {
  final dir = Platform.environment['ATEM_RENDER_DIR']!;
  for (var attempt = 0; attempt < 4; attempt++) {
    await tester.pump();
    final ok = await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return false;
      Directory(dir).createSync(recursive: true);
      File('$dir/$name.png').writeAsBytesSync(data.buffer.asUint8List());
      return true;
    });
    if (ok == true) return;
  }
}

/// Ein Bestand **im Fenster der Muskelbalance** — sonst rendert die Kachel
/// nicht, und die Split-Zeile hat nur eine Hälfte.
class _RecentSessions extends FakeSessionRepository {
  static final sessions = <TrainingSession>[
    for (var i = 0; i < 6; i++)
      StrengthSession(
        id: 'r$i',
        userId: 'u',
        date: DateTime(2026, 8, 25 - i * 3),
        createdAt: DateTime(2026, 8, 25 - i * 3),
        bodyweight: false,
        duration: const Duration(minutes: 52),
        planName: 'Push A',
        exercises: [
          // Mit Anstrengung je Satz — sonst bleibt „Harte Sätze" gesperrt
          // und das Ausklappen der Muskelzeilen wäre nie zu sehen.
          LoggedExercise(
            exerciseId: 'archer_push_up',
            sets: [
              for (var k = 0; k < 4; k++)
                const LoggedSet(reps: 8, weight: 40, rpe: 8),
            ],
          ),
          LoggedExercise(
            exerciseId: 'pistol_squat',
            sets: [
              for (var k = 0; k < 3; k++)
                const LoggedSet(reps: 6, weight: 20, rpe: 9),
            ],
          ),
        ],
      ),
  ];

  @override
  Stream<List<TrainingSession>> watchSessions(String userId) =>
      Stream.value(sessions);

  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async => sessions;
}

void main() {
  // fixtureOverrides[6] ist die Sitzungsquelle — ersetzen, nicht doppeln.
  final thin = [
    for (var i = 0; i < fixtureOverrides.length; i++)
      i == 6
          ? sessionRepositoryProvider.overrideWithValue(_ThinSessions())
          : fixtureOverrides[i],
  ];

  // fixtureOverrides[6] ist die Sitzungsquelle — ersetzen, nicht doppeln.
  final recent = [
    for (var i = 0; i < fixtureOverrides.length; i++)
      i == 6
          ? sessionRepositoryProvider.overrideWithValue(_RecentSessions())
          : fixtureOverrides[i],
  ];

  final cases = <(String, Widget, List<dynamic>)>[
    (
      'verlauf_split',
      const SingleChildScrollView(child: HistorySection()),
      recent
    ),
    (
      'auswertung_voll',
      const SingleChildScrollView(child: AnalysisSection()),
      recent
    ),
    // Die Abschnitte des One-Pagers scrollen nicht selbst — die Seite tut
    // es. Fürs Bild bekommen sie einen Scroll-Container, sonst läuft ein
    // Abschnitt, der höher als das Bild ist, über.
    (
      'verlauf',
      const SingleChildScrollView(child: HistorySection()),
      fixtureOverrides
    ),
    (
      'verlauf_duenn',
      const SingleChildScrollView(child: HistorySection()),
      thin
    ),
    (
      'auswertung',
      const SingleChildScrollView(child: AnalysisSection()),
      fixtureOverrides
    ),
    (
      'auswertung_duenn',
      const SingleChildScrollView(child: AnalysisSection()),
      thin
    ),
    ('muskelbalance', const MuscleBalanceScreen(), fixtureOverrides),
    (
      'uebung',
      ExerciseDetailScreen(exercise: fixtureExercises.first),
      fixtureOverrides
    ),
  ];

  for (final (name, screen, overrides) in cases) {
    testWidgets('rendert $name', (tester) async {
      if (!renderEnabled) return;
      await loadRealFonts();
      tester.view.physicalSize = const Size(361, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(ProviderScope(
        overrides: overrides.cast(),
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
                textScaler: const TextScaler.linear(1.15),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Scaffold(
              backgroundColor: AtemColors.base,
              body: SafeArea(child: screen),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final scrollables = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down);
      for (var shot = 0; shot < 6; shot++) {
        await _shot(tester, key, '${name}_$shot');
        if (scrollables.evaluate().isEmpty) break;
        final state = tester.state<ScrollableState>(scrollables.first);
        final before = state.position.pixels;
        state.position.jumpTo(
            (before + 640).clamp(0, state.position.maxScrollExtent).toDouble());
        await tester.pumpAndSettle();
        if (state.position.pixels == before) break;
      }
    });
  }
}
