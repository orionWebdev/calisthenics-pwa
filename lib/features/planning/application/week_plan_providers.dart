import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../history/application/history_providers.dart';
import '../data/firestore_week_plan_repository.dart';
import '../domain/week_plan.dart';
import '../domain/week_plan_repository.dart';
import 'training_goal_providers.dart';

final weekPlanRepositoryProvider = Provider<WeekPlanRepository>(
  (ref) => FirestoreWeekPlanRepository(FirebaseFirestore.instance),
);

/// Die Woche des angemeldeten Kontos. Ohne Anmeldung leer statt kaputt.
final weekPlanProvider = StreamProvider<WeekPlan>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(WeekPlan.empty);
  return ref.watch(weekPlanRepositoryProvider).watch(userId);
});

/// Eine abgelehnte Handlung — sie steht am Tag, nicht in einem Toast.
class WeekSaveError {
  const WeekSaveError({
    required this.side,
    required this.weekday,
    required this.kind,
    required this.retry,
    this.entryId,
    this.fromWeekday,
  });

  final WeekSide side;

  /// Der Tag, an dem die Fehlerzeile steht — beim Verschieben der Zieltag.
  final int weekday;
  final WeekFailure kind;
  final String? entryId;

  /// Beim Verschieben: woher der Eintrag kam.
  final int? fromWeekday;
  final void Function() retry;
}

enum WeekFailure { add, move, edit, remove, clear }

/// Was die Seite über die letzte Handlung wissen muss.
class WeekActivity {
  const WeekActivity({this.savedEntryId, this.tick = 0, this.error});

  /// Der Eintrag, der zuletzt geschrieben wurde — für den Speicher-Scan.
  final String? savedEntryId;
  final int tick;
  final WeekSaveError? error;
}

/// Schreibt die Woche — jede Handlung einzeln, optimistisch (Board 19, L).
class WeekPlanController extends Notifier<WeekActivity> {
  @override
  WeekActivity build() => const WeekActivity();

  WeekPlan get current => ref.read(weekPlanProvider).value ?? WeekPlan.empty;

  static final _random = math.Random();

  /// Eine neue Eintragskennung — ohne Punkt, weil sie Teil eines Feldpfads
  /// ist.
  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_random.nextInt(1 << 20).toRadixString(36)}';

  /// Führt [change] aus. [failure] beschreibt, was bei einer Ablehnung am
  /// Tag stehen soll.
  void apply(
    WeekChange change, {
    required WeekSaveError Function(void Function() retry) failure,
    String? savedEntryId,
  }) {
    if (change.writes.isEmpty) return;
    state = WeekActivity(savedEntryId: savedEntryId, tick: state.tick + 1);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    ref
        .read(weekPlanRepositoryProvider)
        .write(userId, change.writes)
        .then<void>((_) {}, onError: (Object _) {
      if (!ref.mounted) return;
      state = WeekActivity(
        savedEntryId: state.savedEntryId,
        tick: state.tick,
        error: failure(() => apply(change,
            failure: failure, savedEntryId: savedEntryId)),
      );
    });
  }

  void dismissError() {
    if (state.error == null) return;
    state = WeekActivity(savedEntryId: state.savedEntryId, tick: state.tick);
  }
}

final weekPlanControllerProvider =
    NotifierProvider<WeekPlanController, WeekActivity>(WeekPlanController.new);

/// **„Heute" — die eine Ableitung** für Hybrid-Widget und Kraft-Tab
/// (Board 19, E).
///
/// Lädt, solange Woche oder Trainingsangaben laden; ein Fehler der Woche ist
/// ein Fehler von „heute". Termine aus dem Bestand kommen aus dem Dashboard;
/// fehlen sie (Fehler, lädt), zählt nur die Woche — ein Termin ist eine
/// Ergänzung, keine Voraussetzung.
final todayPlanProvider = Provider<AsyncValue<List<TodayItem>>>((ref) {
  final week = ref.watch(weekPlanProvider);
  final goal = ref.watch(trainingGoalProvider);
  final date = ref.watch(historyReferenceProvider);
  final appointment = ref.watch(dashboardDataProvider).value?.session;
  if (week.hasError) return AsyncError(week.error!, week.stackTrace!);
  if (!week.hasValue || !goal.hasValue) return const AsyncLoading();
  return AsyncData(todayPlan(
    date,
    week: week.value!,
    goal: goal.value!,
    appointments: [
      if (appointment != null)
        TodayAppointment(
          id: appointment.id,
          title: appointment.title,
          planId: appointment.planId,
        ),
    ],
  ));
});
