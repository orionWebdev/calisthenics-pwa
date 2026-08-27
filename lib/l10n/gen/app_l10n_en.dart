// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

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
  String get commonActivity => 'Activity';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonAddSession => 'Add session';

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
  String get commonSave => 'Save';

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
  String get commonView => 'View';

  @override
  String get commonViewDetails => 'View details';

  @override
  String get commonWeeks => 'Weeks';

  @override
  String get commonWorkout => 'Workout';

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
  String get dashboardNavAnalytics => 'ANALYSIS';

  @override
  String get dashboardNavHome => 'HOME';

  @override
  String get dashboardNavProfile => 'PROFILE';

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
  String get detailAcwrLabel => 'Load on this day';

  @override
  String detailAcwrZone(String v, String zone) {
    return 'ACWR $v · $zone';
  }

  @override
  String get detailDistance => 'Distance';

  @override
  String get detailDuration => 'Duration';

  @override
  String get detailLoad => 'Load';

  @override
  String get detailPace => 'Pace /km';

  @override
  String get detailRecoveryBody =>
      'Recovery keeps the streak but does not drive load progression.';

  @override
  String get detailRecoveryTitle => 'Counts towards consistency';

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
  String get difficultyLevel1 => 'Beginner';

  @override
  String get difficultyLevel2 => 'Intermediate';

  @override
  String get difficultyLevel3 => 'Advanced';

  @override
  String get difficultyLevel4 => 'Elite';

  @override
  String get difficultyLevel5 => 'Extreme';

  @override
  String difficultyPick(String level, int n) {
    return '$level — level $n of 5';
  }

  @override
  String durationApproxMinutes(int n) {
    return '~$n min';
  }

  @override
  String durationMinutes(int n) {
    return '$n min';
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
  String get exerciseCopyAction => 'Create your own version';

  @override
  String exerciseCopyName(String name) {
    return '$name (mine)';
  }

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
  String get exerciseCuratedA11y => 'Curated, not editable';

  @override
  String get exerciseCuratedBody =>
      'Curated exercises are the same for everyone.';

  @override
  String get exerciseCuratedChip => 'Curated';

  @override
  String get exerciseDeleteBarrier => 'Delete exercise';

  @override
  String get exerciseDeleteBody =>
      'Completed sessions keep their sets but will only show the identifier.';

  @override
  String exerciseDeleteInPlans(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          'It is used in $n plans. A gap with the target values will remain in each.',
      one:
          'It is used in one plan. A gap with the target values will remain there.',
    );
    return '$_temp0';
  }

  @override
  String get exerciseDeleteSecondBody => 'This cannot be undone.';

  @override
  String get exerciseDeleteSecondTitle => 'Delete permanently?';

  @override
  String get exerciseDeleteTitle => 'Delete exercise?';

  @override
  String exerciseDifficultyA11y(int n) {
    return 'Difficulty $n of 5';
  }

  @override
  String get exerciseFormDescription => 'Description';

  @override
  String get exerciseFormDifficulty => 'Difficulty';

  @override
  String get exerciseFormDifficultyFault => 'Choose a level.';

  @override
  String get exerciseFormDifficultyHint => 'The level is stored as a number.';

  @override
  String get exerciseFormEditTitle => 'Edit exercise';

  @override
  String get exerciseFormEquipment => 'Equipment';

  @override
  String get exerciseFormEquipmentHint => 'e.g. dumbbell, pull-up bar';

  @override
  String exerciseFormMuscleChosen(String muscle) {
    return '$muscle, selected';
  }

  @override
  String exerciseFormMuscleToggle(String muscle) {
    return 'Select $muscle';
  }

  @override
  String get exerciseFormMuscles => 'Muscles';

  @override
  String get exerciseFormMusclesFault => 'Choose at least one muscle.';

  @override
  String get exerciseFormMusclesHint =>
      'At least one. It gives the exercise its colour.';

  @override
  String get exerciseFormName => 'Name';

  @override
  String get exerciseFormNameFault =>
      'Without a name you will not find it again.';

  @override
  String get exerciseFormNameHint => 'e.g. Wide pull-up';

  @override
  String get exerciseFormNewTitle => 'New exercise';

  @override
  String get exerciseFormOptionalSection => 'Can wait';

  @override
  String get exerciseFormRequiredSection => 'Required';

  @override
  String get exerciseFormSaveError => 'Exercise not saved';

  @override
  String get exerciseFormSaveErrorBody =>
      'Check your connection and try again.';

  @override
  String get exerciseFormSaved => 'Exercise saved';

  @override
  String get exerciseInstructions => 'Instructions';

  @override
  String get exerciseMistakes => 'Common mistakes';

  @override
  String get exerciseSparseBody => 'You created this exercise yourself.';

  @override
  String get exerciseSparseTitle => 'No instructions yet';

  @override
  String exercisesBlockAll(int n) {
    return 'View all $n';
  }

  @override
  String exercisesCount(int n, int k, int e) {
    return '$n exercises · $k curated · $e custom';
  }

  @override
  String exercisesEmptyBody(String q) {
    return 'No exercise matches “$q” — in either language.';
  }

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
  String get exercisesNew => 'New exercise';

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
  String historyAll(int n) {
    return 'All $n';
  }

  @override
  String get historyAnalysisOpen => 'Open analysis';

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
  String get historyZoneInactive => 'Inactive';

  @override
  String get historyZonePause => 'Paused';

  @override
  String get historyZoneRecent => 'Keeping up';

  @override
  String get historyZoneRhythm => 'In rhythm';

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
  String get muscleGlutes => 'Glutes';

  @override
  String get muscleHamstrings => 'Hamstrings';

  @override
  String get muscleLegs => 'Legs';

  @override
  String get muscleQuads => 'Quads';

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
  String get navSoonBody => 'This area hasn’t been built yet.';

  @override
  String get navSoonTitle => 'Coming soon';

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
  String restSeconds(int n) {
    return '$n s';
  }

  @override
  String get sessionDeleteBarrier => 'Delete session';

  @override
  String get sessionDeleteBody =>
      'It will no longer count towards any evaluation.';

  @override
  String get sessionDeleteTitle => 'Delete session?';

  @override
  String sessionDeletedBody(int n) {
    return 'You can undo this for $n seconds.';
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
  String get sessionEditTitle => 'Edit session';

  @override
  String get sheetFreeBody =>
      'Start without a plan — add exercises during the workout.';

  @override
  String get sheetRestLabel => 'Default rest';

  @override
  String get sheetStart => 'Start';

  @override
  String sheetStartTitle(String plan) {
    return 'Start $plan?';
  }

  @override
  String get splashStarting => 'ATEM is starting …';

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
  String get workoutA11yEnd => 'End workout';

  @override
  String workoutA11yFormGuide(String exercise) {
    return 'Open form video for $exercise';
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
  String get workoutHold => 'Hold';

  @override
  String get workoutHoldDurationLabel => 'Hold duration (sec)';

  @override
  String get workoutLastPerformance => 'Last time';

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
  String get workoutRunnerAddSet => '+ ADD SET';

  @override
  String get workoutRunnerBack => 'Back';

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
  String workoutTargetHold(int seconds) {
    return 'Goal: hold $seconds';
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
