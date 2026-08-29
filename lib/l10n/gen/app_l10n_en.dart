// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get aboutAccess => 'Access';

  @override
  String get aboutAccessLabel => 'Access';

  @override
  String get aboutAccessValue => 'Approved address';

  @override
  String get aboutAppearance => 'Appearance';

  @override
  String get aboutAppearanceValue => 'Dark · no light version';

  @override
  String get aboutDisplayLabel => 'Appearance';

  @override
  String get aboutDisplayValue => 'Dark · no light version';

  @override
  String get aboutLanguages => 'Languages';

  @override
  String get aboutLanguagesLabel => 'Languages';

  @override
  String get aboutLanguagesValue => 'Deutsch · English';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String get accountDelete => 'Delete account';

  @override
  String accountDelete2Body(int y, int m, int n, int e) {
    return '$y years $m months, $n workouts and $e exercises of your own. There is no undo and no grace period.';
  }

  @override
  String get accountDelete2Confirm => 'Delete account';

  @override
  String get accountDelete2Keep => 'Keep';

  @override
  String get accountDelete2Title => 'Delete permanently';

  @override
  String accountDelete2TypeCount(int a, String b) {
    return '$a / $b characters';
  }

  @override
  String get accountDelete2TypeLabel => 'Type “DELETE” to confirm';

  @override
  String get accountDelete2TypeWord => 'DELETE';

  @override
  String get accountDeleteAccess =>
      'Your access remains. You can sign in again afterwards — the app then starts empty, at onboarding.';

  @override
  String get accountDeleteBody =>
      'This deletes everything you have. Today’s numbers:';

  @override
  String get accountDeleteContinue => 'Continue to delete';

  @override
  String get accountDeleteExport => 'Export data first';

  @override
  String get accountDeleteRange => 'Time span';

  @override
  String get accountDeleteSub => 'Six collections · no undo';

  @override
  String get accountDeleting => 'Deleting your account';

  @override
  String accountDeletingStep(String name) {
    return '$name';
  }

  @override
  String get accountDeletingWait => 'Cannot be cancelled. This takes a moment.';

  @override
  String get accountDoneAccessBody =>
      'Your ATEM access still applies. Sign in with the same address and you are back in — with nothing stored, at onboarding.';

  @override
  String get accountDoneAccessTitle => 'One thing remains';

  @override
  String get accountDoneBody =>
      'Your workouts, plans, exercises, appointments and progress are deleted. The sign-in account is removed.';

  @override
  String get accountDoneTitle => 'Account deleted';

  @override
  String get accountDoneToLogin => 'To sign-in';

  @override
  String accountPartialBody(int a, int b) {
    return '$a of $b collections are gone, the sign-in account still exists.';
  }

  @override
  String get accountPartialResume => 'Resume deletion';

  @override
  String get accountPartialTitle => 'Not fully deleted';

  @override
  String get analysisChartLabel => 'Form 0–100';

  @override
  String get analysisCompConsistency => 'Consistency';

  @override
  String get analysisCompFitness => 'Fitness vs. peak';

  @override
  String get analysisCompLoad => 'Load progression';

  @override
  String get analysisCompPenalty => 'Inactivity penalty';

  @override
  String get analysisCompRecency => 'Recency';

  @override
  String get analysisCompToday => 'Today bonus';

  @override
  String analysisCompValue(int v, int max) {
    return '$v / $max';
  }

  @override
  String analysisErrorBody(int n) {
    return 'All $n workouts are there — only the analysis is missing.';
  }

  @override
  String get analysisErrorRetry => 'Recalculate';

  @override
  String get analysisErrorTitle => 'Form cannot be calculated';

  @override
  String get analysisErrorToList => 'Go to list';

  @override
  String get analysisExplainBody =>
      'Five parts add up to at most 103 points, capped at 100. Long breaks cost extra, and the cost accelerates: three days cost 3 points, seven days 21, fourteen days 70.';

  @override
  String get analysisExplainTitle => 'How the form score is built';

  @override
  String analysisHintRecency(int n) {
    return 'What is missing is recency — one workout today adds $n points right away.';
  }

  @override
  String get analysisLegendRug => 'workouts/week';

  @override
  String get analysisLegendWith => 'with training';

  @override
  String get analysisLegendWithout => 'without training';

  @override
  String analysisThinBody(int n, int d) {
    return 'A trend needs $n workouts and $d days of history.';
  }

  @override
  String get analysisThinHave => 'What you already have';

  @override
  String analysisThinProgress(int cur, int req) {
    return '$cur / $req';
  }

  @override
  String get analysisThinTitle => 'Not enough for a trend yet';

  @override
  String get analysisTitle => 'Analysis';

  @override
  String get analysisToday => 'Form today';

  @override
  String analysisWhyConsistency(int days, int span) {
    return '$days training days in $span';
  }

  @override
  String get analysisWhyFitness => 'Share of your own peak';

  @override
  String get analysisWhyLoadNone => 'No load in the last 28 days';

  @override
  String get analysisWhyLoadRatio => 'Last 14 days against the 14 before';

  @override
  String analysisWhyPenalty(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# days without training',
    );
    return '$_temp0';
  }

  @override
  String analysisWhyRecency(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Last workout # days ago',
      one: 'Last workout yesterday',
      zero: 'Trained today',
    );
    return '$_temp0';
  }

  @override
  String get analysisWhyToday => 'Trained today';

  @override
  String get analysisWhyTodayNone => 'No workout today';

  @override
  String get authBetaBadge => 'CLOSED BETA';

  @override
  String authErrorCode(String code) {
    return 'CODE $code';
  }

  @override
  String get authFailedBody => 'Please try again in a moment.';

  @override
  String get authFailedTitle => 'That didn’t work';

  @override
  String get authGoogle => 'Sign in with Google';

  @override
  String get authLegal =>
      'By signing in you accept the Terms of Use and Privacy Policy.';

  @override
  String get authNetworkBody => 'Signing in needs an internet connection.';

  @override
  String get authNetworkTitle => 'No connection';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authSigningIn => 'Signing in …';

  @override
  String balanceBasis(int sets, int n, int total) {
    return '$sets sets · $n of $total strength sessions';
  }

  @override
  String get balanceColLast => 'last';

  @override
  String get balanceColSets => 'Sets';

  @override
  String get balanceColShare => 'Share';

  @override
  String get balanceGapsNote =>
      'Time since the last set on this muscle. No target — the app does not know how often it should be trained.';

  @override
  String get balanceGapsTitle => 'Longest gaps';

  @override
  String balanceLastDays(int n) {
    return '${n}d';
  }

  @override
  String balanceLastDaysLong(int n) {
    return 'last ${n}d';
  }

  @override
  String balanceThin(int n, int min) {
    return 'Not enough basis yet: $n of $min strength sessions with exercises in the last 8 weeks.';
  }

  @override
  String balanceThinProgress(int n, int min, int rest) {
    return '$n / $min · $rest sessions to go';
  }

  @override
  String get balanceTitle => 'Muscle balance';

  @override
  String get balanceWindow => '8 weeks';

  @override
  String barrierDialog(String titel) {
    return '“$titel” — please choose an option';
  }

  @override
  String barrierSheet(String titel) {
    return 'Closes “$titel”';
  }

  @override
  String get commonActivity => 'Activity';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonAddSession => 'Add session';

  @override
  String get commonAll => 'All';

  @override
  String get commonBack => 'Back';

  @override
  String get commonBodyweight => 'Bodyweight';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonCardio => 'Cardio';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCreated => 'Exercise created';

  @override
  String get commonDays => 'Days';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDistance => 'Distance';

  @override
  String get commonDone => 'Done';

  @override
  String get commonDuration => 'Duration';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonEditSession => 'Edit session';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonMinutes => 'Minutes';

  @override
  String get commonNext => 'Next';

  @override
  String get commonNotAvailable => '-';

  @override
  String get commonNotes => 'Notes';

  @override
  String get commonOf => 'of';

  @override
  String get commonOffline => 'Saved locally · syncing';

  @override
  String get commonOfflineSync => 'Saved locally · syncing';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonOptional => 'optional';

  @override
  String get commonPace => 'Pace';

  @override
  String get commonPercentSign => '%';

  @override
  String get commonRecovery => 'Recovery';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonRetrySave => 'Save again';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaved => 'Change saved';

  @override
  String get commonSaving => 'Saving';

  @override
  String commonSecondsShort(int n) {
    return '${n}s';
  }

  @override
  String get commonSelect => 'Select';

  @override
  String get commonSession => 'Session';

  @override
  String get commonSessions => 'Sessions';

  @override
  String get commonStart => 'Start';

  @override
  String get commonStartAgain => 'Start again';

  @override
  String get commonStrength => 'Strength';

  @override
  String get commonTime => 'Time';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonView => 'View';

  @override
  String get commonViewDetails => 'View details';

  @override
  String get commonWeeks => 'Weeks';

  @override
  String get commonWorkout => 'Workout';

  @override
  String compareBasisDate(String date, int n) {
    return '$date · $n days ago';
  }

  @override
  String get compareBasisExercises => 'Same exercises';

  @override
  String compareBasisMedian(int n) {
    return 'Median · $n sessions';
  }

  @override
  String get compareBasisPlan => 'Same plan';

  @override
  String compareEmptyPlan(String plan) {
    return 'First session of plan “$plan”. From the next one on, the comparison appears here.';
  }

  @override
  String get compareEmptyType =>
      'First session of this kind. From the next one on, the comparison appears here.';

  @override
  String get compareLoading => 'Loading comparison';

  @override
  String compareMedian(String value) {
    return 'median $value';
  }

  @override
  String get compareNoneValue => 'no basis';

  @override
  String get compareNoteMedian =>
      'No plan ID, no exercise overlap. Only what is independent of the exercises is compared: duration and load.';

  @override
  String compareNotePlan(String plan) {
    return 'Both sessions follow plan “$plan”. All four values are comparable.';
  }

  @override
  String comparePrev(String value) {
    return 'before $value';
  }

  @override
  String consequenceDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get consequenceForm => 'Form';

  @override
  String get consequenceGone => 'not shown';

  @override
  String get consequenceLoad => 'Load';

  @override
  String get consequenceNew => 'appears';

  @override
  String get consequenceNone => 'This changes nothing in your evaluation.';

  @override
  String get consequencePause => 'Break';

  @override
  String consequenceStep(String from, String to) {
    return '$from → $to';
  }

  @override
  String consequenceStepA11y(String label, String from, String to) {
    return '$label: from $from to $to';
  }

  @override
  String get consequenceTitle => 'What changes';

  @override
  String get dashboardActivityCalendarDurationUnit => 'Movement hours';

  @override
  String get dashboardActivityCalendarEmptyState =>
      'No sessions in this period yet';

  @override
  String get dashboardActivityCalendarMore => 'More';

  @override
  String get dashboardActivityCalendarThisMonth => 'This month';

  @override
  String get dashboardAddWorkoutTitle => 'Add workout';

  @override
  String get dashboardAllSessionsEarlier => 'Earlier';

  @override
  String get dashboardAllSessionsEmpty => 'No sessions yet';

  @override
  String get dashboardAllSessionsTitle => 'All sessions';

  @override
  String get dashboardAllSessionsToday => 'Today';

  @override
  String get dashboardAllSessionsYesterday => 'Yesterday';

  @override
  String dashboardAvatarA11y(String name) {
    return 'Profile of $name';
  }

  @override
  String dashboardBlocks(int n) {
    return '$n blocks';
  }

  @override
  String get dashboardBrand => 'ATEM HYBRID';

  @override
  String get dashboardBrandA11y => 'System active';

  @override
  String dashboardBreathwork(int n) {
    return '$n min breathwork';
  }

  @override
  String get dashboardCalendarAddTraining => 'Add workout';

  @override
  String get dashboardCalendarNextMonth => 'Next month';

  @override
  String get dashboardCalendarPrevMonth => 'Previous month';

  @override
  String get dashboardCalendarTabActivity => 'Activity';

  @override
  String get dashboardCalendarTabPlan => 'Plan';

  @override
  String get dashboardChartA11y =>
      'Weekly trend: load, strain, recovery, Monday to Sunday';

  @override
  String get dashboardChartSection => 'PERFORMANCE · 7 DAYS';

  @override
  String dashboardChartToday(String day, int load) {
    return '$day · LOAD $load';
  }

  @override
  String dashboardDurationMinutes(int n) {
    return '$n min';
  }

  @override
  String dashboardGreetingDay(String name) {
    return 'Hello, $name';
  }

  @override
  String dashboardGreetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String dashboardGreetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String dashboardHybridBalanceAria(String strength, String cardio) {
    return 'Strength $strength percent, Cardio $cardio percent';
  }

  @override
  String get dashboardHybridBalanceDescription =>
      'Shows time distribution between strength and cardio.';

  @override
  String dashboardHybridBalanceSubtitle(int days) {
    return 'Last $days days';
  }

  @override
  String get dashboardHybridBalanceTitle => 'Hybrid Balance';

  @override
  String get dashboardLive => 'LIVE';

  @override
  String dashboardLiveHrv(int hrv, int n) {
    return 'Live HRV $hrv ms · $n min breathwork';
  }

  @override
  String get dashboardLoadingA11y => 'Loading dashboard';

  @override
  String get dashboardLogWorkoutLog => 'Log workout';

  @override
  String get dashboardLogWorkoutLogDesc => 'Record a completed training';

  @override
  String get dashboardLogWorkoutPlan => 'Plan workout';

  @override
  String get dashboardLogWorkoutPlanDesc => 'Plan a training in the calendar';

  @override
  String get dashboardLogWorkoutStart => 'Start workout';

  @override
  String get dashboardLogWorkoutStartDesc => 'Start a training from your plans';

  @override
  String get dashboardLogWorkoutSubtitle => 'Log, start or plan a workout';

  @override
  String get dashboardLogWorkoutTitle => 'Log workout';

  @override
  String dashboardNavA11y(String name, int n, int total) {
    return '$name, tab $n of $total';
  }

  @override
  String get dashboardNavAnalytics => 'HISTORY';

  @override
  String get dashboardNavHome => 'HOME';

  @override
  String get dashboardNavRecovery => 'RECOVERY';

  @override
  String get dashboardNavWorkouts => 'WORKOUTS';

  @override
  String get dashboardNoDataYet => 'No data yet';

  @override
  String get dashboardNotAvailable => 'Data unavailable';

  @override
  String dashboardNotificationsA11y(int n) {
    return '$n unread notifications';
  }

  @override
  String dashboardPhaseA11y(int week, int total, String phase) {
    return 'Week $week of $total, $phase phase';
  }

  @override
  String dashboardPhaseWeek(int week, int total, String phase) {
    return 'Week $week of $total · $phase';
  }

  @override
  String get dashboardPlanCalendarTitle => 'Plan calendar';

  @override
  String get dashboardPrimaryHelper =>
      'Start or continue your current training.';

  @override
  String get dashboardPrimaryResume => 'Resume workout';

  @override
  String get dashboardPrimaryStart => 'Start workout';

  @override
  String get dashboardPrimarySubtitleActive => 'A workout is active.';

  @override
  String get dashboardPrimarySubtitleInactive =>
      'Choose strength, cardio or recovery.';

  @override
  String get dashboardPrimaryTitle => 'Workout';

  @override
  String dashboardProteinA11y(int value, int goal) {
    return 'Nutrition, protein $value of $goal grams';
  }

  @override
  String dashboardProteinGoal(int goal) {
    return ' / ${goal}g goal';
  }

  @override
  String dashboardProteinOf(int value) {
    return 'Protein ${value}g';
  }

  @override
  String get dashboardQuickNutrition => 'Nutrition & fuel';

  @override
  String get dashboardQuickPeriod => 'Periodisation';

  @override
  String get dashboardQuickRecovery => 'Recovery scan';

  @override
  String dashboardQuickSets(String headline, int sets) {
    return '$headline · $sets sets';
  }

  @override
  String dashboardQuickSetsPlain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets last time',
      one: '1 set last time',
      zero: 'No sets logged',
    );
    return '$_temp0';
  }

  @override
  String dashboardQuickSetsPlan(String plan, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$plan · $_temp0';
  }

  @override
  String get dashboardQuickStatsMovementMinutes => 'Movement min.';

  @override
  String get dashboardQuickStatsSessions => 'Sessions';

  @override
  String get dashboardQuickStatsThisWeek => 'This week';

  @override
  String get dashboardQuickWorkout => 'Workout log';

  @override
  String dashboardReadinessA11y(int percent, String status) {
    return 'Readiness $percent percent, $status';
  }

  @override
  String get dashboardReadinessLevelBuilding => 'BUILDING';

  @override
  String get dashboardReadinessLevelFatigued => 'FATIGUED';

  @override
  String get dashboardReadinessLevelFormLoss => 'FORM LOSS';

  @override
  String get dashboardReadinessLevelModerate => 'MODERATE LOAD';

  @override
  String get dashboardReadinessLevelOverreaching => 'OVERREACHING';

  @override
  String get dashboardReadinessLevelPeak => 'PEAK READINESS';

  @override
  String get dashboardReadinessLevelRecovery => 'FOCUS: RECOVERY';

  @override
  String get dashboardReadinessLevelSolid => 'SOLID FORM';

  @override
  String get dashboardReadinessSection => 'ATEM READINESS';

  @override
  String get dashboardReadinessTagFatigued =>
      'Recovery: Low • Cut volume noticeably';

  @override
  String get dashboardReadinessTagFormLoss =>
      'Recovery: Rested • Start building volume again';

  @override
  String get dashboardReadinessTagModerate =>
      'Recovery: Moderate • Reduce volume slightly';

  @override
  String get dashboardReadinessTagOverreaching =>
      'Recovery: Critical • Do not train today';

  @override
  String get dashboardReadinessTagPeak =>
      'Recovery: Optimal • Ready for maximum load';

  @override
  String get dashboardReadinessTagRecovery =>
      'Recovery: Low • Take an active rest day';

  @override
  String get dashboardReadinessTagSolid =>
      'Recovery: Good • Maintain your normal training load';

  @override
  String get dashboardRecentDescription =>
      'Last sessions in chronological order.';

  @override
  String get dashboardRecentEmpty => 'No sessions yet';

  @override
  String get dashboardRecentTitle => 'Recent sessions';

  @override
  String get dashboardRecentViewAll => 'View all';

  @override
  String get dashboardScheduledTitle => 'Planned for today';

  @override
  String get dashboardSeriesLoad => 'LOAD';

  @override
  String get dashboardSeriesRecovery => 'RECOVERY';

  @override
  String get dashboardSeriesStrain => 'STRAIN';

  @override
  String get dashboardSessionNone => 'Nothing planned for today';

  @override
  String get dashboardSessionNoneHint =>
      'Schedule a session or log a free workout.';

  @override
  String dashboardSessionRunning(String time) {
    return 'SESSION RUNNING · $time';
  }

  @override
  String dashboardSessionRunningA11y(String time) {
    return 'Session running, $time, tap to stop';
  }

  @override
  String get dashboardSessionSection => 'TODAY\'S SESSION';

  @override
  String get dashboardSessionStart => 'START SESSION';

  @override
  String get dashboardSessionStartA11y => 'Start session';

  @override
  String get dashboardStartWorkoutNewWorkout => 'New workout';

  @override
  String get dashboardStartWorkoutNewWorkoutDesc =>
      'Start an empty workout and add exercises';

  @override
  String get dashboardStartWorkoutSelectPlan => 'Select plan';

  @override
  String get dashboardStartWorkoutSelectPlanDesc =>
      'Start a training from your plans';

  @override
  String get dashboardStatHrv => 'HRV';

  @override
  String get dashboardStatRhr => 'RESTING HR';

  @override
  String get dashboardStatSleep => 'SLEEP';

  @override
  String get dashboardSubtitle => 'Optimal system level reached';

  @override
  String get dashboardToday => 'Today';

  @override
  String get dashboardTrainingTypesBodyweight => 'Bodyweight';

  @override
  String get dashboardTrainingTypesCardio => 'Cardio';

  @override
  String get dashboardTrainingTypesRecovery => 'Recovery';

  @override
  String get dashboardTrainingTypesStrength => 'Strength training';

  @override
  String get dashboardWeekdays => 'MO,TU,WE,TH,FR,SA,SU';

  @override
  String get deleteConfirm => 'Delete';

  @override
  String get deleteKeep => 'Keep';

  @override
  String get deleteStep1Continue => 'Continue to delete';

  @override
  String get deleteStep2NoUndo => 'There is no undo — only creating it again.';

  @override
  String get deleteStep2Title => 'Delete permanently';

  @override
  String get detailAcwrLabel => 'Load on this day';

  @override
  String detailAcwrZone(String v, String zone) {
    return 'ACWR $v · $zone';
  }

  @override
  String get detailCompareMid => 'Mid-range';

  @override
  String detailCompareTitle(int n) {
    return 'Against your $n runs';
  }

  @override
  String detailCompareTop(int p) {
    return 'Top $p%';
  }

  @override
  String get detailDistance => 'Distance';

  @override
  String get detailDuration => 'Duration';

  @override
  String get detailLoad => 'Load';

  @override
  String get detailNoteAdd => 'Add note';

  @override
  String get detailPace => 'Pace /km';

  @override
  String get detailRecoveryBody =>
      'Recovery keeps the streak but does not drive load progression.';

  @override
  String get detailRecoveryTitle => 'Counts towards consistency';

  @override
  String get detailSaveAsPlan => 'Save as plan';

  @override
  String detailSetsCount(int e, int s) {
    return '$e exercises · $s sets';
  }

  @override
  String get detailSetsMissingBody =>
      'This workout was recorded as duration only. Load and consistency still count, volume stays empty.';

  @override
  String get detailSetsMissingTitle => 'No sets recorded';

  @override
  String get detailVolume => 'Volume';

  @override
  String get dialogDeleteTitle => 'Delete history?';

  @override
  String get dialogEndConfirm => 'End & save';

  @override
  String get dialogEndTitle => 'End workout?';

  @override
  String get directionBetter => 'better';

  @override
  String get directionLonger => 'longer';

  @override
  String get directionSame => 'unchanged';

  @override
  String get directionShorter => 'shorter';

  @override
  String get directionWorse => 'worse';

  @override
  String durationApproxMinutes(int n) {
    return '~$n min';
  }

  @override
  String durationMinutes(int n) {
    return '$n min';
  }

  @override
  String get emptyHistoryBody =>
      'Your history begins with your first completed session.';

  @override
  String get emptyHistoryTitle => 'No history yet';

  @override
  String emptySearchBody(String begriff, int n) {
    return 'No results for “$begriff” with $n active filters.';
  }

  @override
  String get emptySearchCta => 'Reset filters';

  @override
  String get emptySearchTitle => 'No exercise found';

  @override
  String get emptyTodayBody => 'Rest day — or room for a free session.';

  @override
  String get emptyTodayCta => 'Plan a session';

  @override
  String get emptyTodayTitle => 'Nothing planned today';

  @override
  String get entryCollapse => 'Collapse';

  @override
  String get entryExpand => 'Expand';

  @override
  String get entryNoTarget => 'No target set';

  @override
  String entrySummary(String sets, String reps, String rest) {
    return '$sets×$reps · $rest s rest';
  }

  @override
  String get errorBack => 'Back to dashboard';

  @override
  String get errorLoadBody =>
      'The plan couldn’t be fetched. Your existing data is safe.';

  @override
  String get errorLoadTitle => 'Can’t load workout';

  @override
  String get errorOfflineBanner => 'Offline — changes are saved locally';

  @override
  String get errorSectionBody => 'Everything else is up to date.';

  @override
  String get errorSectionRetry => 'Reload';

  @override
  String errorSectionTitle(String sektion) {
    return 'Can’t load $sektion';
  }

  @override
  String get errorsDeleteFailed => 'Error deleting';

  @override
  String get errorsExerciseNameRequired =>
      'Please enter a name for the exercise!';

  @override
  String get errorsExercisesLoading =>
      'Exercises are still loading. Please try again shortly.';

  @override
  String get errorsLoadFailed => 'Loading failed. Please try again.';

  @override
  String get errorsMuscleGroupsRequired =>
      'Please select at least one muscle group!';

  @override
  String get errorsPlanExercisesRequired => 'Please add at least one exercise!';

  @override
  String get errorsPlanNameRequired => 'Please enter a name for the plan!';

  @override
  String get errorsPlanNotFound => 'Plan not found';

  @override
  String get errorsSaveFailed => 'Error saving.';

  @override
  String get errorsSessionNotFound => 'Session not found';

  @override
  String get errorsStartUnavailable => 'Start selection is not available.';

  @override
  String get errorsWorkoutNotFound => 'Workout not found';

  @override
  String get errorsWorkoutStartFailed => 'Error starting workout';

  @override
  String get exerciseCopyNotice =>
      'The curated exercise remains. Your version sits alongside it.';

  @override
  String exerciseCountShort(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String get exerciseCues => 'Cues';

  @override
  String get exerciseCuratedBadge => 'Curated';

  @override
  String get exerciseCuratedBody =>
      'This exercise is the same for everyone and stays unchanged. Want it different? Create your own version.';

  @override
  String get exerciseCuratedCopy => 'Create my own version';

  @override
  String get exerciseCuratedTitle => 'Part of the library';

  @override
  String get exerciseDelete => 'Delete exercise';

  @override
  String exerciseDeleteKeepUnits(int n) {
    return 'Your $n workouts stay complete — sets, weights and load.';
  }

  @override
  String exerciseDeletePlansGap(int n) {
    return 'A gap stays in those $n plans, which you can replace there.';
  }

  @override
  String exerciseDeleteQ(String name) {
    return 'Delete “$name”?';
  }

  @override
  String exerciseDeleteUsage(int p, int s) {
    String _temp0 = intl.Intl.pluralLogic(
      p,
      locale: localeName,
      other: '# plans',
      one: '# plan',
    );
    String _temp1 = intl.Intl.pluralLogic(
      s,
      locale: localeName,
      other: '# workouts',
      one: '# workout',
    );
    return 'This exercise is used in $_temp0 and $_temp1.';
  }

  @override
  String exerciseDifficultyA11y(int n) {
    return 'Difficulty $n of 5';
  }

  @override
  String exerciseDuplicateBody(String name) {
    return 'You already have an exercise called “$name”. Your input is still here.';
  }

  @override
  String get exerciseDuplicateOpen => 'Open existing';

  @override
  String get exerciseDuplicateSuggest => 'Use suggestion';

  @override
  String get exerciseDuplicateTitle => 'Not saved';

  @override
  String get exerciseEditTitle => 'Edit exercise';

  @override
  String get exerciseFieldCues => 'Cues';

  @override
  String get exerciseFieldCuesHint => 'Short reminders, one per line';

  @override
  String get exerciseFieldEquipment => 'Equipment';

  @override
  String get exerciseFieldEquipmentHint => 'Free text, no fixed list';

  @override
  String get exerciseFieldInstructions => 'Instructions';

  @override
  String get exerciseFieldInstructionsHint => 'Free text, up to 500 characters';

  @override
  String get exerciseFieldLevel => 'Level';

  @override
  String get exerciseFieldMuscles => 'Muscles';

  @override
  String exerciseFieldMusclesCount(int n) {
    return '$n selected';
  }

  @override
  String get exerciseFieldName => 'Name';

  @override
  String get exerciseFieldNameHint => 'e.g. Bulgarian split squat';

  @override
  String get exerciseFormSaveError => 'Exercise not saved';

  @override
  String get exerciseFormSaveErrorBody =>
      'Check your connection and try again.';

  @override
  String get exerciseHistoryTitle => 'You with this exercise';

  @override
  String get exerciseInstructions => 'Instructions';

  @override
  String get exerciseLevel1 => 'Entry';

  @override
  String get exerciseLevel2 => 'Easy';

  @override
  String get exerciseLevel3 => 'Medium';

  @override
  String get exerciseLevel4 => 'Advanced';

  @override
  String get exerciseLevel5 => 'Expert';

  @override
  String get exerciseLevelHint => 'Saved as a number, 1–5.';

  @override
  String get exerciseMistakes => 'Common mistakes';

  @override
  String get exerciseMore => 'More details';

  @override
  String exerciseMoreCount(int n) {
    return '$n optional';
  }

  @override
  String get exerciseNewTitle => 'New exercise';

  @override
  String exerciseSaveBlocked(int n) {
    return '$n more details needed';
  }

  @override
  String get exerciseSparseBody => 'You created this exercise yourself.';

  @override
  String get exerciseSparseTitle => 'No instructions yet';

  @override
  String get exercisesBlockAll => 'See all';

  @override
  String get exercisesBlockByMuscle => 'By muscle';

  @override
  String get exercisesBlockSearch => 'Name or muscle';

  @override
  String exercisesBlockTitle(int n) {
    return 'Exercises · $n';
  }

  @override
  String exercisesCount(int n, int k, int e) {
    return '$n exercises · $k curated · $e custom';
  }

  @override
  String get exercisesCreate => 'Create your own exercise';

  @override
  String exercisesEmptyBody(String q) {
    return 'No exercise matches “$q” — in either language.';
  }

  @override
  String get exercisesEmptyOwnBody =>
      'Name, muscles and a level are enough — the rest is optional.';

  @override
  String get exercisesEmptyOwnTitle => 'No exercise of your own yet';

  @override
  String get exercisesEmptyTitle => 'Nothing found';

  @override
  String exercisesFilterActive(String muscle) {
    return '$muscle, filter active';
  }

  @override
  String get exercisesFilterAll => 'All';

  @override
  String exercisesFilterMuscle(String muscle) {
    return 'Filter by $muscle';
  }

  @override
  String get exercisesFilterReset => 'Reset';

  @override
  String exercisesFilterResult(int n, String filter) {
    return '$n exercises · $filter';
  }

  @override
  String get exercisesNoMatchBody => 'Change the search term or the muscle.';

  @override
  String get exercisesNoMatchTitle => 'No matches';

  @override
  String get exercisesOwnTag => 'Custom';

  @override
  String get exercisesSearchHint => 'Search exercises …';

  @override
  String get exercisesTitle => 'Exercises';

  @override
  String get exportBody => 'You choose where it goes afterwards.';

  @override
  String get exportCreate => 'Create file';

  @override
  String get exportCreateCsv => 'Create as CSV';

  @override
  String get exportCreateJson => 'Create as JSON';

  @override
  String get exportDoneNote =>
      'The file is in your downloads folder. The app sends nothing itself.';

  @override
  String get exportDoneShare => 'Share';

  @override
  String get exportFormatNote =>
      'JSON contains everything. CSV contains your workouts as a table, one row per set.';

  @override
  String get exportOffline => 'Not possible offline';

  @override
  String exportProgress(int a, int b, int c, int d, int e, int f) {
    return 'Workouts $a/$b · plans $c/$d · exercises $e/$f';
  }

  @override
  String exportRowDays(int n) {
    return '$n d';
  }

  @override
  String get exportRowExercises => 'Your own exercises';

  @override
  String get exportRowPlans => 'Plans with entries';

  @override
  String get exportRowProfile => 'Profile details';

  @override
  String get exportRowSchedule => 'Appointments';

  @override
  String get exportRowScores => 'Records and form curve';

  @override
  String get exportRowSessions => 'Workouts with sets';

  @override
  String exportSize(String mb) {
    return 'approx. $mb MB · no images, no videos';
  }

  @override
  String get exportSub => 'One file with everything that is yours';

  @override
  String get exportTitle => 'Export data';

  @override
  String get formDiscardBarrier => 'Discard changes';

  @override
  String get formDiscardBody => 'What you entered will be lost.';

  @override
  String get formDiscardConfirm => 'Discard';

  @override
  String get formDiscardKeep => 'Keep editing';

  @override
  String get formDiscardTitle => 'Discard changes?';

  @override
  String formatDistanceKm(num distance) {
    final intl.NumberFormat distanceNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String distanceString = distanceNumberFormat.format(distance);

    return '$distanceString km';
  }

  @override
  String formatDurationHours(int hours) {
    return '${hours}h';
  }

  @override
  String formatDurationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String formatDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get formatDurationZero => '0 min';

  @override
  String get formatPaceNa => '-';

  @override
  String formatPaceValue(int min, int sec) {
    return '$min:$sec min/km';
  }

  @override
  String get gateBody =>
      'The beta is closed and we’re opening spots continuously. You’ll get an email as soon as it’s your turn.';

  @override
  String get gateRecheck => 'Check status again';

  @override
  String get gateRecheckA11y => 'Check beta status again';

  @override
  String get gateRecheckNegative => 'Checked — no spot yet.';

  @override
  String get gateRecheckOffline => 'Can’t check — no connection.';

  @override
  String get gateRechecking => 'Checking …';

  @override
  String gateSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get gateStatus => 'WAITLIST';

  @override
  String get gateStatusA11y => 'Status: waitlist';

  @override
  String get gateSwitchAccount => 'Use another account';

  @override
  String get gateSwitchAccountA11y =>
      'Sign out and sign in with another account';

  @override
  String get gateTitle => 'You’re on the list';

  @override
  String get hapticsSub => 'A short tap on sets and rest';

  @override
  String get hapticsTitle => 'Haptics';

  @override
  String get hapticsUnavailable => 'Your device has no vibration motor.';

  @override
  String historyAll(int n) {
    return 'All $n';
  }

  @override
  String get historyAnalysisOpen => 'Open analysis';

  @override
  String get historyBest => 'Best';

  @override
  String historyCount(int n) {
    return '$n×';
  }

  @override
  String historyCurveA11y(int n, String from, String to) {
    return 'Best set weight across $n sessions, from $from to $to';
  }

  @override
  String get historyCurveLabel => 'Best set weight';

  @override
  String get historyCurveLegend => 'Ring marks the best value';

  @override
  String get historyEmptyBody =>
      'Your first workout appears here once you finish it.';

  @override
  String get historyEmptyTitle => 'Nothing recorded yet';

  @override
  String get historyErrorBody => 'Your workouts could not be loaded.';

  @override
  String get historyErrorTitle => 'History unavailable';

  @override
  String get historyFormLabel => 'Form';

  @override
  String historyFormOf(int v) {
    return '$v/100';
  }

  @override
  String get historyFreq => 'Frequency';

  @override
  String historyFreqValue(String n) {
    return '$n / wk';
  }

  @override
  String get historyLast => 'Last';

  @override
  String historyLeadFrequency(int n, int d) {
    return '$n workouts in $d days';
  }

  @override
  String historyLeadGap(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# days',
      one: '# day',
    );
    return '$_temp0 without training';
  }

  @override
  String historyLeadLast(String weekday, String date, String name) {
    return 'Last $weekday $date · $name';
  }

  @override
  String get historyMonthsLabel => 'Workouts per month';

  @override
  String historyMonthsMedian(int n, int max) {
    return 'Median $n days apart · longest break $max';
  }

  @override
  String historyOnce(String date) {
    return 'performed · $date';
  }

  @override
  String get historyOnceLabel => 'That time';

  @override
  String get historyOnceNote =>
      'No best, no curve, no frequency — one performance yields none of these.';

  @override
  String get historyRecentLabel => 'Recent workouts';

  @override
  String get historyTitle => 'History';

  @override
  String get historyTrendFalling => 'falling';

  @override
  String get historyTrendRising => 'rising';

  @override
  String get historyTrendStable => 'stable';

  @override
  String get historyVolume => 'Volume';

  @override
  String get historyZoneInactive => 'Inactive';

  @override
  String get historyZonePause => 'Paused';

  @override
  String get historyZoneRecent => 'Keeping up';

  @override
  String get historyZoneRhythm => 'In rhythm';

  @override
  String get languageDe => 'German';

  @override
  String get languageEn => 'English';

  @override
  String get languageTitle => 'Language';

  @override
  String get legalError => 'Text not loaded';

  @override
  String get legalExternal => 'Open externally';

  @override
  String get legalImprint => 'Legal notice';

  @override
  String legalImprintBody(String betreiber) {
    return 'Private project of a private individual. Details pursuant to § 5 TMG: $betreiber';
  }

  @override
  String get legalInapp => 'In the app';

  @override
  String get legalPrivacy => 'Privacy';

  @override
  String get legalRetry => 'Try again';

  @override
  String get legalTerms => 'Terms of use';

  @override
  String listEndBody(String date, int n) {
    return 'First workout on $date · $n days ago.';
  }

  @override
  String get listEndTitle => 'End of history';

  @override
  String get listErrorBody => 'Your workouts could not be loaded.';

  @override
  String get listErrorTitle => 'Loading failed';

  @override
  String get listFilterClear => 'Clear period';

  @override
  String listFilterEmptyBody(String typ, String zeitraum, int n) {
    return 'No $typ in $zeitraum — $n in total.';
  }

  @override
  String get listFilterEmptyTitle => 'No workout in this selection';

  @override
  String listGap(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# days',
      one: '# day',
    );
    return '$_temp0 without training';
  }

  @override
  String get listGapLongest => 'longest break on record';

  @override
  String listGapRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String listMonthSummary(String n, int load) {
    return '$n · load $load';
  }

  @override
  String listSecond(int n) {
    return 'workout $n';
  }

  @override
  String get listTitle => 'Workouts';

  @override
  String loadingDone(String sektion) {
    return '$sektion loaded';
  }

  @override
  String get loadingLabel => 'Loading …';

  @override
  String get muscleArms => 'Arms';

  @override
  String get muscleBack => 'Back';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleCalves => 'Calves';

  @override
  String get muscleChest => 'Chest';

  @override
  String get muscleCore => 'Core';

  @override
  String muscleFieldCount(int n, String names) {
    return '$n chosen · $names';
  }

  @override
  String get muscleFieldEmpty => 'None chosen';

  @override
  String get muscleGlutes => 'Glutes';

  @override
  String get muscleHamstrings => 'Hamstrings';

  @override
  String get muscleLegs => 'Legs';

  @override
  String get muscleQuads => 'Quads';

  @override
  String get muscleSheetHint =>
      'Several possible. The first one sets the colour.';

  @override
  String get muscleSheetTitle => 'Choose muscles';

  @override
  String get muscleShoulders => 'Shoulders';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navDashboard => 'Home';

  @override
  String get navExercises => 'Exercises';

  @override
  String get navPlans => 'Plans';

  @override
  String get navProfile => 'Profile';

  @override
  String get navProgress => 'Progress';

  @override
  String get navTraining => 'Training';

  @override
  String get onbCta => 'Let’s go';

  @override
  String get onbCtaLocked => 'Enter your weight to get started.';

  @override
  String get onbCtaLockedA11y => 'Body weight missing';

  @override
  String onbErrorRange(String min, String max, String unit) {
    return 'Please enter a value between $min and $max $unit.';
  }

  @override
  String onbFieldA11y(String unit) {
    return 'Body weight in $unit';
  }

  @override
  String get onbHintSettings =>
      'You can change this later in Profile → Body data.';

  @override
  String get onbKicker => 'ALMOST THERE';

  @override
  String get onbSaving => 'Saving …';

  @override
  String get onbTitle => 'Your body weight';

  @override
  String get onbUnitGroupA11y => 'Choose weight unit';

  @override
  String get onbUnitKg => 'kg';

  @override
  String get onbUnitKgA11y => 'Unit: kilograms';

  @override
  String get onbUnitLbs => 'lbs';

  @override
  String get onbUnitLbsA11y => 'Unit: pounds';

  @override
  String get onbWhy =>
      'ATEM converts every exercise into training load — including bodyweight moves. That takes exactly one number.';

  @override
  String get onboardingRepeat => 'Repeat onboarding';

  @override
  String get onboardingRepeatAction => 'View';

  @override
  String get onboardingRepeatSub => 'The four intro pages again';

  @override
  String pickerAdd(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Add $n exercises',
      one: 'Add 1 exercise',
    );
    return '$_temp0';
  }

  @override
  String get pickerCreate => 'Missing one? Create it';

  @override
  String get pickerNone => 'Nothing chosen';

  @override
  String get pickerTitle => 'Choose exercises';

  @override
  String get planBrokenEntry => 'Exercise deleted';

  @override
  String planBrokenKeepTarget(String ziel) {
    return 'Target kept · $ziel';
  }

  @override
  String planBrokenNotice(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '# entries point',
      one: '# entry points',
    );
    return '$_temp0 to nothing.';
  }

  @override
  String get planBrokenRemove => 'Remove';

  @override
  String get planBrokenReplace => 'Replace';

  @override
  String planCount(int n) {
    return '$n plans';
  }

  @override
  String get planDeleteBarrier => 'Delete plan';

  @override
  String get planDeleteBody =>
      'Your completed sessions stay unchanged — they carry the plan name themselves.';

  @override
  String get planDeleteTitle => 'Delete plan?';

  @override
  String get planEmptyAllowed => 'The plan exists as soon as it has a name.';

  @override
  String get planEntryAdd => 'Add exercise';

  @override
  String get planEntryReps => 'Reps';

  @override
  String get planEntryRepsHint => '“12”, “8-12” and “max” are all allowed.';

  @override
  String get planEntryRest => 'Rest';

  @override
  String get planEntrySets => 'Sets';

  @override
  String get planFormAdd => 'Add exercise';

  @override
  String get planFormEditTitle => 'Edit plan';

  @override
  String planFormGapA11y(int n, String scheme) {
    return 'Gap at position $n: deleted exercise, $scheme';
  }

  @override
  String get planFormGapBody =>
      'The target values remain. Replace it with another exercise.';

  @override
  String get planFormGapTitle => 'Exercise deleted';

  @override
  String get planFormHold => 'Hold';

  @override
  String get planFormItems => 'Exercises';

  @override
  String get planFormItemsFault => 'A plan needs at least one exercise.';

  @override
  String planFormMoveA11y(String name, int n, int total) {
    return '$name, position $n of $total';
  }

  @override
  String get planFormMoveDown => 'Move down';

  @override
  String get planFormMoveUp => 'Move up';

  @override
  String get planFormName => 'Name';

  @override
  String get planFormNameFault => 'A plan needs a name.';

  @override
  String get planFormNameHint => 'e.g. Upper body A';

  @override
  String get planFormNewTitle => 'New plan';

  @override
  String get planFormPickTitle => 'Choose exercise';

  @override
  String get planFormRemove => 'Remove';

  @override
  String planFormRemoveA11y(String name) {
    return 'Remove $name from the plan';
  }

  @override
  String get planFormReplace => 'Replace';

  @override
  String get planFormReps => 'Reps';

  @override
  String get planFormRepsHint => '8-12';

  @override
  String get planFormRest => 'Rest';

  @override
  String get planFormSaveError => 'Plan not saved';

  @override
  String get planFormSaved => 'Plan saved';

  @override
  String get planFormSets => 'Sets';

  @override
  String get planItemMissing => 'No longer available';

  @override
  String planMeta(int n, String type) {
    return '$n exercises · $type';
  }

  @override
  String get planMissingBody =>
      'They were deleted. The plan starts without them.';

  @override
  String planMissingTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exercises are missing',
      one: 'One exercise is missing',
    );
    return '$_temp0';
  }

  @override
  String get planNewTitle => 'New plan';

  @override
  String get profileLocked => 'Via Google · fixed';

  @override
  String get profileLockedWhy =>
      'Your name and email come from your Google account and are only shown here.';

  @override
  String get quickForm => 'Form';

  @override
  String get quickFormFalling => 'falling';

  @override
  String get quickFormFlat => 'steady';

  @override
  String get quickFormRising => 'rising';

  @override
  String quickFormValue(int v) {
    return '$v of 100';
  }

  @override
  String get quickLast => 'Last workout';

  @override
  String quickLastDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0 ago';
  }

  @override
  String get quickLastToday => 'today';

  @override
  String get quickNext => 'Next appointment';

  @override
  String quickNextDays(int n) {
    return 'in $n days';
  }

  @override
  String get quickNextNone => 'Nothing planned';

  @override
  String get quickNextToday => 'today';

  @override
  String get quickNextTomorrow => 'tomorrow';

  @override
  String get quickNoSessions => 'No workout yet';

  @override
  String get regionArms => 'Arms';

  @override
  String get regionBack => 'Back';

  @override
  String get regionChest => 'Chest';

  @override
  String get regionCore => 'Core';

  @override
  String get regionLegs => 'Legs';

  @override
  String get regionShoulders => 'Shoulders';

  @override
  String get repsKeyboard => 'Keyboard';

  @override
  String get repsWheel => 'Wheel';

  @override
  String get repsWheelHint =>
      'The wheel only knows numbers. Use the keyboard for “8-12” or “max”.';

  @override
  String get restBody =>
      'Applies to sets without their own rest in the plan. Takes effect from your next workout.';

  @override
  String get restCustom => 'Custom value';

  @override
  String get restRunning => 'A running workout keeps its rest time.';

  @override
  String restSeconds(int n) {
    return '$n s';
  }

  @override
  String get restSub => 'Default when a workout starts';

  @override
  String get restTitle => 'Rest time';

  @override
  String get sectionAbout => 'About';

  @override
  String get sectionApp => 'App';

  @override
  String get sectionData => 'Your data';

  @override
  String get sectionLegal => 'Legal';

  @override
  String get sectionTraining => 'Training';

  @override
  String get sessionDateAllowedBody =>
      'Moving the day moves your gaps and form curve with it.';

  @override
  String get sessionDateAllowedTitle => 'Changing the date is allowed';

  @override
  String sessionDatePrevious(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+# days',
      one: '+# day',
    );
    return 'Was $date · $_temp0';
  }

  @override
  String get sessionDeleteBarrier => 'Delete session';

  @override
  String get sessionDeleteBody =>
      'It counts towards every analysis. Afterwards it reads:';

  @override
  String get sessionDeleteQ => 'Delete this workout?';

  @override
  String get sessionDeleteTitle => 'Delete session?';

  @override
  String get sessionDeleteWindow => 'You can undo this for 30 seconds.';

  @override
  String sessionDeletedBody(int n) {
    return 'You can undo this for $n seconds.';
  }

  @override
  String sessionDeletedSnack(String alt, String neu) {
    return 'Workout deleted · form $alt → $neu';
  }

  @override
  String sessionDeletedTitle(String name) {
    return '$name deleted';
  }

  @override
  String get sessionDeletedUndo => 'Undo';

  @override
  String get sessionEditDate => 'Date';

  @override
  String sessionEditDateA11y(String date) {
    return 'Change date, currently $date';
  }

  @override
  String get sessionEditDuration => 'Duration in minutes';

  @override
  String get sessionEditNoChange => 'Nothing changed';

  @override
  String get sessionEditSaveError => 'Session not saved';

  @override
  String get sessionEditSaved => 'Session saved';

  @override
  String get sessionEditSets => 'Sets';

  @override
  String get sessionEditTitle => 'Edit workout';

  @override
  String get sessionFieldDatetime => 'Date and time';

  @override
  String get sessionImpactCount => 'Workouts total';

  @override
  String get sessionImpactForm => 'Form today';

  @override
  String get sessionImpactLongest => 'Longest break';

  @override
  String sessionImpactMonth(String month) {
    return 'Workouts in $month';
  }

  @override
  String sessionImpactOfKind(String kind) {
    return '$kind workouts';
  }

  @override
  String get sessionImpactPause => 'Current break';

  @override
  String get sessionImpactPreview => 'Preview — not saved yet.';

  @override
  String get sessionImpactTitle => 'What this changes';

  @override
  String get setsAdd => 'Add sets';

  @override
  String get settingsAboutPrivate => 'Private project, not for commercial use.';

  @override
  String get settingsAboutTheme =>
      'Dark only — ATEM is built for dark surroundings.';

  @override
  String settingsAboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsBodyWeight => 'Body weight';

  @override
  String settingsBodyWeightFault(int min, int max) {
    return 'Between $min and $max kg.';
  }

  @override
  String get settingsBodyWeightHint =>
      'Recalculates every bodyweight exercise, including past ones.';

  @override
  String get settingsBodyWeightNone => 'Not set yet';

  @override
  String get settingsDelete => 'Delete account';

  @override
  String get settingsDeleteBarrier => 'Delete account';

  @override
  String get settingsDeleteConfirmHint => 'Exactly like that, in capitals.';

  @override
  String get settingsDeleteConfirmWord => 'DELETE';

  @override
  String settingsDeleteCounts(int sessions, int plans, int exercises) {
    return '$sessions sessions · $plans plans · $exercises own exercises';
  }

  @override
  String get settingsDeleteExport => 'Export data first';

  @override
  String get settingsDeleteFailed => 'Deletion incomplete';

  @override
  String get settingsDeleteFailedBody =>
      'Some of your data is still there. Try again while you are signed in.';

  @override
  String get settingsDeleteOfflineBody =>
      'Deletion spans several collections. Without a connection half of it would remain.';

  @override
  String get settingsDeleteOfflineTitle => 'Not possible while offline';

  @override
  String get settingsDeleteRunning => 'Deleting …';

  @override
  String get settingsDeleteStep1Body =>
      'Sessions, plans, your own exercises, appointments and your profile will be removed. There is no undo and no time window.';

  @override
  String get settingsDeleteStep1Title => 'Delete account and all data?';

  @override
  String settingsDeleteStep2Body(String word) {
    return 'Type $word to confirm.';
  }

  @override
  String get settingsDeleteStep2Title => 'Really delete permanently?';

  @override
  String get settingsDeletedAccessBody =>
      'ATEM is invite-only; your access is held in a list that belongs to the programme, not to your account. If you sign in again you are back — with no data.';

  @override
  String get settingsDeletedAccessTitle => 'Your access remains';

  @override
  String get settingsDeletedBody => 'Your training data has been removed.';

  @override
  String get settingsDeletedClose => 'Close';

  @override
  String get settingsDeletedTitle => 'Account deleted';

  @override
  String get settingsEntryA11y => 'Profile and settings';

  @override
  String get settingsExportBody =>
      'JSON contains everything. CSV contains your sessions as a table, one row per set.';

  @override
  String get settingsExportCsv => 'Sessions as CSV';

  @override
  String settingsExportDone(int n) {
    return '$n documents exported';
  }

  @override
  String get settingsExportFailed => 'Export failed';

  @override
  String get settingsExportJson => 'Everything as JSON';

  @override
  String get settingsExportRunning => 'Collecting …';

  @override
  String get settingsExportTitle => 'Export data';

  @override
  String get settingsFromGoogle =>
      'Name and picture come from your Google account.';

  @override
  String get settingsHaptics => 'Haptics';

  @override
  String get settingsHapticsHint =>
      'Short feedback on tap and when a rest ends.';

  @override
  String get settingsHapticsOff => 'Haptics off';

  @override
  String get settingsHapticsOn => 'Haptics on';

  @override
  String get settingsImprint => 'Imprint';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageGerman => 'German';

  @override
  String get settingsLanguageHint => 'Applies immediately.';

  @override
  String get settingsLinkFailed => 'Cannot open page';

  @override
  String get settingsOpenA11y => 'Open settings and profile';

  @override
  String get settingsOpensBrowser => 'Opens in your browser';

  @override
  String get settingsPreviewComputing => 'Calculating …';

  @override
  String get settingsPreviewFitness => 'Fitness vs. peak';

  @override
  String get settingsPreviewLoad => 'Load of last session';

  @override
  String get settingsPreviewNone => 'This changes nothing in your evaluations.';

  @override
  String get settingsPreviewTitle => 'What this changes';

  @override
  String get settingsPrivacy => 'Privacy policy';

  @override
  String get settingsReplayOnboarding => 'Replay onboarding';

  @override
  String get settingsReplayOnboardingHint => 'Asks for your body weight again.';

  @override
  String get settingsRest => 'Rest time';

  @override
  String settingsRestFault(int min, int max) {
    return 'Between $min and $max seconds.';
  }

  @override
  String get settingsRestHint =>
      'Suggested when starting a session. Adjustable during training.';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsSectionProfile => 'Profile';

  @override
  String get settingsSectionTraining => 'Training';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutBarrier => 'Sign out';

  @override
  String get settingsSignOutBody =>
      'Your data stays. You can sign in again at any time.';

  @override
  String get settingsSignOutTitle => 'Sign out?';

  @override
  String get settingsSignedInAs => 'Signed in as';

  @override
  String get settingsTerms => 'Terms of use';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsUnits => 'Units';

  @override
  String get settingsUnitsHint => 'Always stored in kilograms.';

  @override
  String get settingsUnitsImperial => 'Imperial';

  @override
  String get settingsUnitsImperialA11y => 'Imperial, pounds';

  @override
  String get settingsUnitsMetric => 'Metric';

  @override
  String get settingsUnitsMetricA11y => 'Metric, kilograms';

  @override
  String settingsWeightChanged(String weight) {
    return 'Body weight changed to $weight kg';
  }

  @override
  String settingsWeightChangedBody(int n) {
    return 'You can undo this for $n seconds.';
  }

  @override
  String sheetFilterActive(int n) {
    return '$n active';
  }

  @override
  String get sheetFilterApply => 'Apply';

  @override
  String get sheetFilterTitle => 'Filters';

  @override
  String get sheetFreeBody =>
      'Start without a plan — add exercises during the workout.';

  @override
  String get sheetGrabberHint => 'Drag to close';

  @override
  String get sheetNoteTitle => 'Set note';

  @override
  String get sheetPickerApply => 'Apply';

  @override
  String get sheetRestLabel => 'Default rest';

  @override
  String get sheetStart => 'Start';

  @override
  String sheetStartTitle(String plan) {
    return 'Start $plan?';
  }

  @override
  String get signout => 'Sign out';

  @override
  String get signoutKeep => 'Data stays';

  @override
  String get splashStarting => 'ATEM is starting …';

  @override
  String get switchOff => 'OFF';

  @override
  String get switchOn => 'ON';

  @override
  String get typeBodyweight => 'Bodyweight';

  @override
  String get typeCardio => 'Cardio';

  @override
  String get typeHybrid => 'Hybrid';

  @override
  String get typeRecovery => 'Recovery';

  @override
  String get typeStrength => 'Strength';

  @override
  String unitKilograms(String v) {
    return '$v kg';
  }

  @override
  String unitKilometers(String v) {
    return '$v km';
  }

  @override
  String get unitSuffixKilograms => 'kg';

  @override
  String get unitSuffixPounds => 'lb';

  @override
  String get unitSuffixSeconds => 's';

  @override
  String get unitsExample => 'How it will look';

  @override
  String get unitsImperial => 'Imperial';

  @override
  String get unitsMetric => 'Metric';

  @override
  String get unitsNote =>
      'Storage stays metric. Only the display is converted.';

  @override
  String get unitsTitle => 'Unit system';

  @override
  String unsavedBody(int c, int a) {
    String _temp0 = intl.Intl.pluralLogic(
      c,
      locale: localeName,
      other: '# entries',
      one: '# entry',
    );
    return 'You changed $_temp0 and added $a.';
  }

  @override
  String get unsavedContinue => 'Keep editing';

  @override
  String get unsavedDiscard => 'Discard';

  @override
  String get unsavedSave => 'Save and close';

  @override
  String get unsavedTitle => 'Keep changes?';

  @override
  String get weightBody =>
      'Scores every bodyweight exercise in your history — today and retroactively.';

  @override
  String weightDelta(String sign, String kg, String pct) {
    return '$sign$kg kg · $sign$pct %';
  }

  @override
  String get weightDirDown => 'lower';

  @override
  String get weightDirRescored => 're-scored';

  @override
  String get weightDirSame => 'unchanged';

  @override
  String get weightDirUp => 'higher';

  @override
  String get weightErrorRange =>
      'Between 66 and 550 lb. No preview until the value is valid.';

  @override
  String get weightHint => 'One decimal · 66–550 lb';

  @override
  String get weightImpactAcwr => 'ACWR';

  @override
  String weightImpactBest(String exercise) {
    return 'Best $exercise';
  }

  @override
  String get weightImpactForm => 'Form today';

  @override
  String get weightImpactLoad => 'Training load 7 d';

  @override
  String get weightImpactNote =>
      'Preview — not saved yet. Your sets, weights and reps stay unchanged — only how they are scored.';

  @override
  String weightImpactRecord(String exercise) {
    return 'Best $exercise';
  }

  @override
  String get weightImpactRescored => 'rescored';

  @override
  String weightImpactScope(int d, int n) {
    return '$d days · $n workouts with bodyweight exercises';
  }

  @override
  String get weightImpactTitle => 'What changes retroactively';

  @override
  String weightPrevious(String alt) {
    return 'Was $alt kg';
  }

  @override
  String get weightSave => 'Save and recalculate';

  @override
  String get weightSaveBusy => 'Recalculating';

  @override
  String get weightSaveNone => 'Unchanged · nothing to save';

  @override
  String weightSavedSnack(String kg, String alt, String neu) {
    return 'Weight $kg kg · form $alt → $neu';
  }

  @override
  String get weightSub => 'Scores your whole history';

  @override
  String get weightTitle => 'Body weight';

  @override
  String get workoutA11yEnd => 'End workout';

  @override
  String workoutA11yFormGuide(String exercise) {
    return 'Open form video for $exercise';
  }

  @override
  String workoutA11yHoldField(int n) {
    return 'Hold time in seconds, set $n';
  }

  @override
  String get workoutA11yLoading => 'Loading workout';

  @override
  String get workoutA11yNextExercise => 'Next exercise';

  @override
  String get workoutA11yNotes => 'Open session notes';

  @override
  String get workoutA11yPause => 'Pause training';

  @override
  String get workoutA11yPrevExercise => 'Previous exercise';

  @override
  String workoutA11yRepsField(int n) {
    return 'Repetitions, set $n';
  }

  @override
  String get workoutA11yRestExtend => 'Extend rest by 30 seconds';

  @override
  String workoutA11yRestRemaining(String time) {
    return 'Rest: $time remaining';
  }

  @override
  String get workoutA11yRestShorten => 'Shorten rest by 15 seconds';

  @override
  String get workoutA11yRestSkip => 'Skip rest';

  @override
  String get workoutA11yResume => 'Resume training';

  @override
  String workoutA11ySetComplete(int n) {
    return 'Complete set $n';
  }

  @override
  String workoutA11ySetType(String type) {
    return 'Set type: $type. Tap to change';
  }

  @override
  String workoutA11ySetUnlock(int n) {
    return 'Unlock set $n';
  }

  @override
  String workoutA11yWeightField(int n) {
    return 'Weight in kilograms, set $n';
  }

  @override
  String workoutBannerActive(String name) {
    return 'Active workout: $name';
  }

  @override
  String get workoutBannerCancel => 'Cancel';

  @override
  String get workoutBannerCancelConfirm =>
      'Really cancel active workout? All progress will be lost.';

  @override
  String get workoutBannerCancelWorkoutConfirm =>
      'Really cancel workout? All progress will be lost.';

  @override
  String get workoutBannerResume => 'Resume';

  @override
  String get workoutCardioDistance => 'Distance (km)';

  @override
  String get workoutCardioDuration => 'Duration (min)';

  @override
  String get workoutCardioLog => 'Log cardio';

  @override
  String get workoutCardioPace => 'Pace';

  @override
  String get workoutCardioRpe => 'Effort (1–5)';

  @override
  String get workoutColHold => 'Hold';

  @override
  String get workoutCopyLastSet => 'Copy last set';

  @override
  String get workoutEditDateError =>
      'Invalid date format. Please use YYYY-MM-DD';

  @override
  String get workoutEditDatePrompt => 'New date (YYYY-MM-DD):';

  @override
  String get workoutExerciseCurrent => 'Current exercise';

  @override
  String get workoutExerciseFinish => 'End workout';

  @override
  String get workoutExerciseNext => 'Next exercise';

  @override
  String workoutExerciseProgress(String completed, int total) {
    return '$completed / $total exercises';
  }

  @override
  String get workoutFeedbackEnterDuration => 'Please enter duration';

  @override
  String get workoutFeedbackExerciseComplete => 'Exercise completed!';

  @override
  String get workoutFeedbackRestartError => 'Error restarting workout';

  @override
  String get workoutFeedbackSaveError => 'Error saving workout';

  @override
  String get workoutFeedbackSaved => 'Workout saved!';

  @override
  String get workoutFreeTitle => 'Free session';

  @override
  String get workoutHold => 'Hold';

  @override
  String get workoutHoldDurationLabel => 'Hold duration (sec)';

  @override
  String get workoutLastPerformance => 'Last time';

  @override
  String get workoutLeaveBody =>
      'Your progress is saved. You can resume later.';

  @override
  String get workoutLeaveKeep => 'Leave and save';

  @override
  String get workoutLeaveStay => 'Keep training';

  @override
  String get workoutLeaveTitle => 'Leave workout?';

  @override
  String get workoutLoggingAddExercise => 'Add exercise';

  @override
  String get workoutLoggingExerciseAlreadyAdded => 'Exercise already added';

  @override
  String get workoutLoggingExercisesOptional => 'Exercises (optional)';

  @override
  String get workoutLoggingReps => 'Reps per set';

  @override
  String get workoutLoggingSet => 'Set';

  @override
  String get workoutLoggingSets => 'Sets';

  @override
  String get workoutLoggingTotalReps => 'Reps';

  @override
  String get workoutNoPreviousData => 'No previous data';

  @override
  String get workoutPostWorkoutComparisonTitle => 'Comparison to last time';

  @override
  String get workoutPostWorkoutEditDuration => 'Adjust training time';

  @override
  String get workoutPostWorkoutExercises => 'Exercises';

  @override
  String get workoutPostWorkoutFallbackName => 'Training';

  @override
  String get workoutPostWorkoutMinutes => 'Minutes';

  @override
  String get workoutPostWorkoutSets => 'Sets';

  @override
  String get workoutPostWorkoutTime => 'Time';

  @override
  String get workoutPostWorkoutTitle => 'Workout completed!';

  @override
  String get workoutPostWorkoutToProgress => 'View progress';

  @override
  String get workoutPostWorkoutVolume => 'Volume';

  @override
  String workoutPreviousReps(int reps) {
    return '$reps reps';
  }

  @override
  String workoutPreviousSet(String weight, int reps) {
    return '$weight kg × $reps';
  }

  @override
  String workoutPreviousWeight(String weight) {
    return '$weight kg';
  }

  @override
  String get workoutQuickBodyweight => 'Bodyweight';

  @override
  String get workoutQuickBodyweightDesc => 'Bodyweight training';

  @override
  String get workoutQuickDate => 'Date *';

  @override
  String get workoutQuickDateRequired => 'Please select a date';

  @override
  String get workoutQuickDifficulty => 'Difficulty';

  @override
  String get workoutQuickDuration => 'Duration (minutes)';

  @override
  String get workoutQuickDurationRequired => 'Please enter a valid duration';

  @override
  String get workoutQuickName => 'Workout name';

  @override
  String get workoutQuickNameRequired => 'Please enter a workout name';

  @override
  String get workoutQuickSaveError => 'Error saving workout';

  @override
  String get workoutQuickTitle => 'Quick workout entry';

  @override
  String get workoutQuickType => 'Type';

  @override
  String get workoutQuickWeights => 'Weights';

  @override
  String get workoutQuickWeightsDesc => 'Gym / Dumbbells';

  @override
  String workoutRecordKg(String weight) {
    return 'PR $weight kg';
  }

  @override
  String get workoutRecoveryDuration => 'Duration (min)';

  @override
  String get workoutRecoveryLog => 'Log recovery';

  @override
  String workoutRelativeTimeDaysAgo(int n) {
    return '$n days ago';
  }

  @override
  String get workoutRelativeTimeOneWeekAgo => '1 week ago';

  @override
  String get workoutRelativeTimeToday => 'today';

  @override
  String workoutRelativeTimeWeeksAgo(int n) {
    return '$n weeks ago';
  }

  @override
  String get workoutRelativeTimeYesterday => 'yesterday';

  @override
  String get workoutRemoveExerciseBody =>
      'The completed sets of this exercise will be lost.';

  @override
  String workoutRemoveExerciseConfirm(String name) {
    return 'Remove $name?';
  }

  @override
  String workoutResumeBody(String n, int sets, int total) {
    return 'You started a workout $n ago. $sets of $total sets are done.';
  }

  @override
  String get workoutResumeContinue => 'Resume';

  @override
  String get workoutResumeDiscard => 'Start over';

  @override
  String get workoutResumeTitle => 'Resume workout?';

  @override
  String get workoutRunnerAddSet => '+ ADD SET';

  @override
  String get workoutRunnerBack => 'Back';

  @override
  String get workoutRunnerEmptyBody =>
      'Add what you are doing. The session grows with it.';

  @override
  String get workoutRunnerEmptyTitle => 'No exercise yet';

  @override
  String get workoutRunnerFormGuide => 'FORM GUIDE';

  @override
  String get workoutRunnerNotAvailable => 'Workout unavailable';

  @override
  String get workoutRunnerNotesDone => 'DONE';

  @override
  String get workoutRunnerNotesHint => 'How does the session feel?';

  @override
  String get workoutRunnerNotesTitle => 'SESSION NOTES';

  @override
  String get workoutRunnerRemoveExercise => 'Remove exercise';

  @override
  String workoutRunnerRemoveExerciseA11y(String name) {
    return 'Remove $name from the session';
  }

  @override
  String get workoutRunnerRestLabel => 'REST';

  @override
  String get workoutRunnerRestMinus => '−15s';

  @override
  String get workoutRunnerRestPlus => '+30s';

  @override
  String get workoutRunnerRestSkip => 'SKIP →';

  @override
  String workoutRunnerRunning(String time) {
    return 'SESSION RUNNING · $time';
  }

  @override
  String get workoutRunnerSaved => 'Session saved';

  @override
  String get workoutRunnerSavedDone => 'DONE';

  @override
  String get workoutRunnerSavedFailed => 'Saving failed';

  @override
  String get workoutRunnerSessionLabel => 'SESSION';

  @override
  String workoutRunnerSetsCompleted(int done, int total) {
    return '$done OF $total SETS COMPLETED';
  }

  @override
  String workoutRunnerSummary(int sets, String time, String volume) {
    return '$sets sets · $time · $volume kg volume';
  }

  @override
  String get workoutRunnerTableDone => 'OK';

  @override
  String get workoutRunnerTableLast => 'LAST TIME';

  @override
  String get workoutRunnerTableReps => 'REPS';

  @override
  String get workoutRunnerTableSet => 'SET';

  @override
  String get workoutRunnerTableWeight => 'KG';

  @override
  String get workoutScreenAddExercise => 'Add exercise';

  @override
  String get workoutScreenAddSet => 'Add set';

  @override
  String get workoutScreenBodyweight => 'Bodyweight';

  @override
  String get workoutScreenCancelWorkout => 'Cancel';

  @override
  String get workoutScreenCardio => 'Cardio';

  @override
  String get workoutScreenCurrentExercise => 'Current exercise';

  @override
  String get workoutScreenDiscardConfirm =>
      'Really discard workout? All progress will be lost.';

  @override
  String get workoutScreenDiscardConfirmTitle => 'Discard workout?';

  @override
  String get workoutScreenDiscardWorkout => 'Discard workout';

  @override
  String get workoutScreenEmptyHint => 'Add exercises to start your workout';

  @override
  String get workoutScreenEndWorkout => 'End workout';

  @override
  String get workoutScreenEndWorkoutAction => 'End';

  @override
  String get workoutScreenEndWorkoutConfirm => 'Really end workout?';

  @override
  String get workoutScreenEndWorkoutConfirmText =>
      'All sets so far will be saved.';

  @override
  String workoutScreenExerciseOf(int current, int total) {
    return 'Exercise $current of $total';
  }

  @override
  String workoutScreenExerciseProgress(String completed, int total) {
    return '$completed / $total exercises';
  }

  @override
  String workoutScreenExercisesButton(String completed, int total) {
    return 'Exercises ($completed/$total)';
  }

  @override
  String get workoutScreenExercisesSheetTitle => 'Exercises';

  @override
  String get workoutScreenFinishWorkout => 'Finish workout';

  @override
  String get workoutScreenFreeWorkout => 'Free workout';

  @override
  String get workoutScreenGoal => 'Goal';

  @override
  String get workoutScreenLogWorkout => 'Log workout';

  @override
  String get workoutScreenMenu => 'Menu';

  @override
  String get workoutScreenNextExercise => 'Next exercise';

  @override
  String get workoutScreenNoActiveWorkout => 'No active workout';

  @override
  String get workoutScreenNoActiveWorkoutText =>
      'Start a training from the calendar or a plan.';

  @override
  String get workoutScreenNoExercisesFound => 'No exercises found';

  @override
  String get workoutScreenRecovery => 'Recovery';

  @override
  String get workoutScreenRest => 'Rest';

  @override
  String get workoutScreenRestTimer => 'Rest';

  @override
  String get workoutScreenSaveWorkout => 'Save workout';

  @override
  String get workoutScreenSearchExercise => 'Search exercise...';

  @override
  String get workoutScreenSwitchToExercise => 'Switch to this exercise';

  @override
  String get workoutScreenTimerAdd => '+10s';

  @override
  String get workoutScreenTimerDone => 'Rest done!';

  @override
  String get workoutScreenTimerPause => 'Pause';

  @override
  String get workoutScreenTimerResume => 'Resume';

  @override
  String get workoutScreenTimerSkip => 'Skip';

  @override
  String get workoutScreenTimerStart => 'Start timer';

  @override
  String get workoutScreenTimerSub => '-10s';

  @override
  String get workoutScreenToPlans => 'Go to plans';

  @override
  String get workoutScreenWeighted => 'Weighted';

  @override
  String get workoutSetLoggerAddSet => 'Add set';

  @override
  String get workoutSetLoggerAtLeastOneSet =>
      'Please log at least one set before continuing';

  @override
  String get workoutSetLoggerCompletedSets => 'Completed sets';

  @override
  String get workoutSetLoggerDecreaseWeight => 'Decrease weight';

  @override
  String get workoutSetLoggerDeleteSet => 'Delete set';

  @override
  String get workoutSetLoggerDeleteSetConfirm => 'Really delete this set?';

  @override
  String get workoutSetLoggerDuplicateLast => 'Copy last set';

  @override
  String get workoutSetLoggerEnterHold => 'Please enter the hold duration';

  @override
  String get workoutSetLoggerEnterReps => 'Please enter the number of reps';

  @override
  String get workoutSetLoggerIncreaseWeight => 'Increase weight';

  @override
  String get workoutSetLoggerLogSet => 'Log set';

  @override
  String get workoutSetLoggerNoSets => 'No sets logged yet';

  @override
  String get workoutSetLoggerReps => 'Reps';

  @override
  String workoutSetLoggerRest(int seconds) {
    return '${seconds}s rest';
  }

  @override
  String get workoutSetLoggerSet => 'Set';

  @override
  String workoutSetLoggerStepModeChanged(int step, String unit) {
    return 'Step size: $step $unit';
  }

  @override
  String get workoutSetLoggerTarget => 'Goal';

  @override
  String workoutSetLoggerTargetReps(int reps) {
    return '$reps reps';
  }

  @override
  String workoutSetLoggerTargetSets(int sets) {
    return '$sets sets';
  }

  @override
  String workoutSetLoggerTitle(int number) {
    return 'Log set $number';
  }

  @override
  String get workoutSetLoggerWeight => 'Weight';

  @override
  String get workoutSetLoggerWeightUnit => 'kg';

  @override
  String get workoutSetTypeDropset => 'Drop set';

  @override
  String get workoutSetTypeFailure => 'Set to failure';

  @override
  String workoutSetTypeLegend(String w, String n, String d, String f) {
    return '$w Warm-up · $n Normal · $d Drop set · $f Failure';
  }

  @override
  String get workoutSetTypeNormal => 'Normal set';

  @override
  String get workoutSetTypeShortDropset => 'D';

  @override
  String get workoutSetTypeShortFailure => 'F';

  @override
  String get workoutSetTypeShortNormal => 'N';

  @override
  String get workoutSetTypeShortWarmup => 'W';

  @override
  String get workoutSetTypeWarmup => 'Warm-up set';

  @override
  String workoutTargetHold(int n) {
    return 'Target hold $n s';
  }

  @override
  String workoutTargetRef(int sets, String reps) {
    return 'Target $sets×$reps';
  }

  @override
  String workoutTargetReps(String reps) {
    return 'Target $reps';
  }

  @override
  String workoutTargetSets(int sets) {
    return 'Target $sets sets';
  }

  @override
  String get workoutsFree => 'Free workout';

  @override
  String get workoutsFreeStart => 'Start free workout';

  @override
  String get workoutsPlanPick => 'Pick a plan';

  @override
  String workoutsPlansAll(int n) {
    return 'All $n';
  }

  @override
  String get workoutsPlansLabel => 'Plans';

  @override
  String workoutsSearchEntry(int n) {
    return 'Search $n exercises';
  }

  @override
  String get workoutsStart => 'Start workout';

  @override
  String get workoutsTitle => 'Workouts';

  @override
  String get workoutsTodayEmptyBody => 'Start freely or pick a plan.';

  @override
  String get workoutsTodayEmptyTitle => 'No workout scheduled';

  @override
  String get workoutsTodayLabel => 'Today';
}
