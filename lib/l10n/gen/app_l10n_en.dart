// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get aboutAccessLabel => 'Access';

  @override
  String get aboutAccessValue => 'Approved address';

  @override
  String get aboutDisplayLabel => 'Appearance';

  @override
  String get aboutDisplayValue => 'Dark · no light version';

  @override
  String get aboutLanguagesLabel => 'Languages';

  @override
  String get aboutLanguagesValue => 'Deutsch · English';

  @override
  String get accountDelete => 'Delete account';

  @override
  String accountDelete2Body(int y, int m, int n, int e) {
    return '$y years $m months, $n workouts and $e exercises of your own. There is no undo and no grace period.';
  }

  @override
  String get accountDelete2Title => 'Delete permanently';

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
  String accountDeleteSpan(int y, int m) {
    return '${y}y ${m}m';
  }

  @override
  String get accountRowProgress => 'Progress and records';

  @override
  String get accountRowProfile => 'Profile and settings';

  @override
  String get accountDeleteSub => 'Six collections · no undo';

  @override
  String get accountDeleting => 'Deleting your account';

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
  String get activityBike => 'Cycling';

  @override
  String get activityBikeIndoor => 'Indoor bike';

  @override
  String get activityHike => 'Hiking';

  @override
  String get activityMore => 'More';

  @override
  String get activityOther => 'Other';

  @override
  String activityOwn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return 'Your activities · $_temp0';
  }

  @override
  String get activityRow => 'Rowing';

  @override
  String get activityRun => 'Running';

  @override
  String get activitySwim => 'Swimming';

  @override
  String get activityWalk => 'Walking';

  @override
  String analysisDistBasis(int n, int total) {
    return '$n of $total sessions with distance';
  }

  @override
  String get analysisDistTitle => 'Distance distribution';

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
  String analysisPaceBasis(String value, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n runs',
      one: '1 run',
    );
    return 'vs. own average $value · $_temp0';
  }

  @override
  String analysisPaceThin(int min, String value, String from, String to) {
    return 'No curve below $min sessions of this activity. Average $value, range $from to $to.';
  }

  @override
  String get analysisPaceTitle => 'Pace development';

  @override
  String analysisPctFaster(int n, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Faster than $n of $total of your runs',
      one: 'Faster than 1 of your runs',
    );
    return '$_temp0';
  }

  @override
  String get analysisPctNoothers => 'No comparison with other people.';

  @override
  String analysisWeeklyBasis(String value, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return 'avg. $value km · $_temp0';
  }

  @override
  String get analysisWeeklyCurrent => 'in progress';

  @override
  String get analysisWeeklyTitle => 'Weekly distance';

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
  String get cardioAdd => 'Log session';

  @override
  String get cardioAddFirst => 'Log first session';

  @override
  String get cardioEmptyBody =>
      'Log a run, a ride or a hike. From the second session of the same activity on, pace development appears here.';

  @override
  String get cardioEmptyTitle => 'No endurance session yet';

  @override
  String get cardioLiveStart => 'Track live';

  @override
  String cardioTotalSince(String date) {
    return 'Total · since $date';
  }

  @override
  String cardioWeekBasis(String value) {
    return 'vs. 4-week average $value km';
  }

  @override
  String cardioWeekCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get cardioWeekThin =>
      'Weekly distance from 3 weeks with sessions on. Until then, total distance is shown.';

  @override
  String cardioWeekTitle(int kw) {
    return 'This week · W$kw';
  }

  @override
  String get commonBack => 'Back';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCreated => 'Exercise created';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDone => 'Done';

  @override
  String get commonDuration => 'Duration';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonMinutes => 'Minutes';

  @override
  String get commonNotAvailable => '-';

  @override
  String get commonNotes => 'Notes';

  @override
  String get commonOf => 'of';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonPercentSign => '%';

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
  String get commonUndo => 'Undo';

  @override
  String get commonWeeks => 'Weeks';

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
  String consequenceStepA11y(String label, String from, String to) {
    return '$label: from $from to $to';
  }

  @override
  String dashboardHybridBalanceSubtitle(int days) {
    return 'Last $days days';
  }

  @override
  String get dashboardLoadingA11y => 'Loading dashboard';

  @override
  String dashboardNavA11y(String name, int n, int total) {
    return '$name, tab $n of $total';
  }

  @override
  String get dashboardNotAvailable => 'Data unavailable';

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
  String get detailLoad => 'Load';

  @override
  String get detailSaveAsPlan => 'Save as plan';

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
  String get errorsLoadFailed => 'Loading failed. Please try again.';

  @override
  String get errorsSaveFailed => 'Error saving.';

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
      other: '$p plans',
      one: '$p plan',
    );
    String _temp1 = intl.Intl.pluralLogic(
      s,
      locale: localeName,
      other: '$s workouts',
      one: '$s workout',
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
  String get exerciseLevel1Short => 'ENTRY';

  @override
  String get exerciseLevel2Short => 'EASY';

  @override
  String get exerciseLevel3Short => 'MED.';

  @override
  String get exerciseLevel4Short => 'ADV.';

  @override
  String get exerciseLevel5Short => 'EXP.';

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
  String get exercisesBlockByMuscle => 'By muscle';

  @override
  String exercisesCount(int n, int k, int e) {
    return '$n exercises · $k curated · $e custom';
  }

  @override
  String get exercisesCreate => 'Create your own exercise';

  @override
  String get exercisesEmptyOwnBody =>
      'Name, muscles and a level are enough — the rest is optional.';

  @override
  String get exercisesEmptyOwnTitle => 'No exercise of your own yet';

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
  String get exportDoneNote =>
      'The file is in your downloads folder. The app sends nothing itself.';

  @override
  String get exportDoneShare => 'Share';

  @override
  String get exportFormatNote =>
      'JSON contains everything. CSV contains your workouts as a table, one row per set.';

  @override
  String get exportFormatFull => 'Complete';

  @override
  String get exportFormatSessions => 'Sessions';

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
  String get formActivity => 'Activity';

  @override
  String get formDate => 'Date';

  @override
  String get formDistance => 'Distance · km';

  @override
  String get formDuration => 'Duration · min';

  @override
  String get formHrAvg => 'Avg. HR';

  @override
  String get formHrHint =>
      'Leaving heart rate empty is normal. No analysis requires it.';

  @override
  String get formHrMax => 'Max. HR';

  @override
  String formOptionalCount(int n) {
    return 'Optional · $n fields';
  }

  @override
  String get formPace => 'Pace';

  @override
  String get formPaceComputed => 'calculated';

  @override
  String get formRpe => 'Effort · RPE';

  @override
  String get formRpe1 => 'very easy';

  @override
  String get formRpe3 => 'moderate';

  @override
  String get formRpe5 => 'maximal';

  @override
  String get formToday => 'Today';

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
  String get historyErrorBody => 'Your workouts could not be loaded.';

  @override
  String get historyErrorTitle => 'History unavailable';

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
      other: '$n days',
      one: '$n day',
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
  String get hybridEmptyBody =>
      'This will show how strength and endurance relate for you. Start with either side — it does not matter which.';

  @override
  String get hybridEmptyTitle => 'No session yet';

  @override
  String hybridWeekThin(int min) {
    return 'Readiness from $min workouts on.';
  }

  @override
  String get hybridWeekTitle => 'Your week';

  @override
  String get intensityAbove => 'Above average';

  @override
  String get intensityBelow => 'Below average';

  @override
  String intensityFallbackNote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n runs',
      one: '1 run',
    );
    return 'Neither heart rate nor RPE recorded. Judged by pace against $_temp0.';
  }

  @override
  String get intensityLevel1 => 'Avg. heart rate · from watch data';

  @override
  String get intensityLevel2 => 'Effort · your input';

  @override
  String get intensityLevel3 => 'Pace vs. own average';

  @override
  String get intensityNoneA11y => 'not recorded';

  @override
  String get intensityNoneValue => '—';

  @override
  String intensityZone(int n, String name) {
    return 'Zone $n · $name';
  }

  @override
  String get languageDe => 'German';

  @override
  String get languageEn => 'English';

  @override
  String get languageTitle => 'Language';

  @override
  String lastCardio(String activity, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$activity yesterday',
      zero: '$activity today',
    );
    return '$_temp0';
  }

  @override
  String lastNone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'No session for $n days',
      one: 'No session for 1 day',
    );
    return '$_temp0';
  }

  @override
  String lastRecovery(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Recovery yesterday',
      zero: 'Recovery today',
    );
    return '$_temp0';
  }

  @override
  String lastStrength(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Strength yesterday',
      zero: 'Strength today',
    );
    return '$_temp0';
  }

  @override
  String get legalError => 'Text not loaded';

  @override
  String get legalImprint => 'Legal notice';

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
      other: '$n days',
      one: '$n day',
    );
    return '$_temp0 without training';
  }

  @override
  String get listGapLongest => 'longest break on record';

  @override
  String get listOpenDetail => 'opens details';

  @override
  String listGapOpen(String from) {
    return '$from – today';
  }

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
  String get liveDistanceManual => 'Distance by hand · km';

  @override
  String get liveDistanceSource => 'from display';

  @override
  String get liveNogps =>
      'No GPS, no location permission. Distance comes from the machine display and can be corrected any time.';

  @override
  String get livePause => 'Pause';

  @override
  String liveStarted(String time) {
    return 'Started $time';
  }

  @override
  String get liveStatePaused => 'Paused';

  @override
  String get liveStateRunning => 'Running';

  @override
  String get liveStop => 'Finish';

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
  String get navPlans => 'Plans';

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
  String get planBrokenRemove => 'Remove';

  @override
  String get planBrokenReplace => 'Replace';

  @override
  String planCount(int n) {
    return '$n plans';
  }

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
  String get planFormEditTitle => 'Edit plan';

  @override
  String planFormGapA11y(int n, String scheme) {
    return 'Gap at position $n: deleted exercise, $scheme';
  }

  @override
  String get planFormGapTitle => 'Exercise deleted';

  @override
  String get planFormHold => 'Hold';

  @override
  String get planFormItems => 'Exercises';

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
  String get planFormNameHint => 'e.g. Upper body A';

  @override
  String get planFormNewTitle => 'New plan';

  @override
  String planFormRemoveA11y(String name) {
    return 'Remove $name from the plan';
  }

  @override
  String get planFormSaveError => 'Plan not saved';

  @override
  String get planItemMissing => 'No longer available';

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
  String get ratioNoshift => 'no 4-week average';

  @override
  String get ratioShiftDown => 'less';

  @override
  String get ratioShiftUp => 'more';

  @override
  String get recoveryAdd => 'Log';

  @override
  String recoveryGap(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'No recovery for $n days',
      one: 'No recovery for 1 day',
    );
    return '$_temp0';
  }

  @override
  String get recoveryKindMobility => 'Mobility';

  @override
  String get recoveryKindSauna => 'Sauna';

  @override
  String get recoveryKindStretch => 'Stretching';

  @override
  String get recoveryKindYoga => 'Yoga';

  @override
  String recoveryLast(String when, String kind, int n) {
    return '$when · $kind · $n min';
  }

  @override
  String get recoveryNever => 'No recovery logged';

  @override
  String get recoveryNoload =>
      'Breaks the inactivity penalty but carries no load. Form does not rise from it.';

  @override
  String get recoveryTitle => 'Recovery';

  @override
  String get recoveryTabEmptyTitle => 'No recovery yet';

  @override
  String get recoveryTabEmptyBody =>
      'Yoga, sauna, stretching or mobility — it breaks the inactivity, without carrying load.';

  @override
  String get recoveryTabKinds => 'By kind';

  @override
  String get recoveryTabAll => 'All sessions';

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
  String get segAnalysis => 'Analysis';

  @override
  String get segHistory => 'History';

  @override
  String get segSessions => 'Sessions';

  @override
  String get segTrain => 'Train';

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
      other: '+$n days',
      one: '+$n day',
    );
    return 'Was $date · $_temp0';
  }

  @override
  String get sessionDeleteBody =>
      'It counts towards every analysis. Afterwards it reads:';

  @override
  String get sessionDeleteQ => 'Delete this workout?';

  @override
  String get sessionDeleteWindow => 'You can undo this for 6 seconds.';

  @override
  String sessionDeletedSnack(String alt, String neu) {
    return 'Workout deleted · workouts $alt → $neu';
  }

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
  String get sessionEditTitle => 'Edit workout';

  @override
  String get sessionFieldDatetime => 'Date and time';

  @override
  String get sessionImpactCount => 'Workouts total';

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
  String get settingsDeletedAccessTitle => 'Your access remains';

  @override
  String get settingsEntryA11y => 'Profile and settings';

  @override
  String settingsExportDone(int n) {
    return '$n documents exported';
  }

  @override
  String get settingsExportFailed => 'Export failed';

  @override
  String get settingsExportRunning => 'Collecting …';

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
  String get settingsTitle => 'Settings';

  @override
  String get sheetFreeBody =>
      'Start without a plan — add exercises during the workout.';

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
  String get signoutKeep => 'Data stays';

  @override
  String get splashStarting => 'ATEM is starting …';

  @override
  String get switchOff => 'OFF';

  @override
  String get switchOn => 'ON';

  @override
  String get tabCardio => 'Cardio';

  @override
  String get tabHybrid => 'Hybrid';

  @override
  String get tabStrength => 'Strength';

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
      other: '$c entries',
      one: '$c entry',
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
  String get weightSub => 'The basis of every bodyweight calculation';

  @override
  String get weightTitle => 'Body weight';

  @override
  String get workoutA11yEnd => 'End workout';

  @override
  String workoutA11yFormGuide(String exercise) {
    return 'Open instructions for $exercise';
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
  String get workoutColHold => 'Hold';

  @override
  String workoutExerciseProgress(String completed, int total) {
    return '$completed / $total exercises';
  }

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
  String get workoutLoggingSets => 'Sets';

  @override
  String get workoutPostWorkoutSets => 'Sets';

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
  String workoutRecordKg(String weight) {
    return 'PR $weight kg';
  }

  @override
  String workoutRelativeTimeDaysAgo(int n) {
    return '$n days ago';
  }

  @override
  String workoutRelativeTimeWeeksAgo(int n) {
    return '$n weeks ago';
  }

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
  String get workoutRunnerEmptyBody =>
      'Add what you are doing. The session grows with it.';

  @override
  String get workoutRunnerEmptyTitle => 'No exercise yet';

  @override
  String get workoutRunnerFormGuide => 'FORM GUIDE';

  @override
  String get workoutRunnerNotAvailable => 'Workout unavailable';

  @override
  String get workoutRunnerRemoveExercise => 'Remove exercise';

  @override
  String workoutRunnerRemoveExerciseA11y(String name) {
    return 'Remove $name from the session';
  }

  @override
  String get workoutRunnerRestLabel => 'REST';

  @override
  String get workoutRunnerRestMinus => '−15';

  @override
  String get workoutRunnerRestPlus => '+30';

  @override
  String get workoutRunnerRestSkip => 'SKIP';

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
  String get workoutScreenAddSet => 'Add set';

  @override
  String get workoutScreenDiscardConfirm =>
      'Really discard workout? All progress will be lost.';

  @override
  String get workoutScreenDiscardConfirmTitle => 'Discard workout?';

  @override
  String get workoutScreenDiscardWorkout => 'Discard workout';

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
  String workoutSetLoggerRest(int seconds) {
    return '${seconds}s rest';
  }

  @override
  String workoutSetLoggerStepModeChanged(int step, String unit) {
    return 'Step size: $step $unit';
  }

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
  String workoutTargetReps(String reps) {
    return 'Target $reps';
  }

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
  String get workoutsStart => 'Start workout';

  @override
  String get workoutsTodayEmptyBody => 'Start freely or pick a plan.';

  @override
  String get workoutsTodayEmptyTitle => 'No workout scheduled';

  @override
  String get workoutsTodayLabel => 'Today';

  @override
  String analysisPaceBasisOther(String value, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return 'vs. own average $value · $_temp0';
  }

  @override
  String analysisPctFasterOther(int n, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Faster than $n of $total of your sessions',
      one: 'Faster than 1 of your sessions',
    );
    return '$_temp0';
  }

  @override
  String intensityFallbackNoteOther(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return 'Neither heart rate nor RPE recorded. Judged by pace against $_temp0 of the same activity.';
  }

  @override
  String get intensityZoneName1 => 'recovery';

  @override
  String get intensityZoneName2 => 'base';

  @override
  String get intensityZoneName3 => 'threshold';

  @override
  String get intensityZoneName4 => 'hard';

  @override
  String get intensityZoneName5 => 'maximal';

  @override
  String intensityBasisA11y(String basis) {
    return 'Basis: $basis';
  }

  @override
  String intensityBasisPace(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return 'Pace vs. own average from $_temp0';
  }

  @override
  String intensityRpeValue(int n) {
    return '$n / 5';
  }

  @override
  String get formRpe2 => 'easy';

  @override
  String get formRpe4 => 'hard';

  @override
  String get formModeLog => 'Log afterwards';

  @override
  String get formModeLive => 'Live';

  @override
  String get cardioFormTitle => 'Log endurance';

  @override
  String get formKind => 'Type';

  @override
  String get formDurationRequired => 'Duration missing';

  @override
  String get formActivityRequired => 'Activity missing';

  @override
  String get formDistanceInvalid => 'Invalid distance';

  @override
  String cardioSavedSnack(String activity) {
    return 'Session saved · $activity';
  }

  @override
  String get recoverySavedSnack => 'Recovery saved';

  @override
  String get liveResume => 'Resume';

  @override
  String get liveStopTooShort =>
      'Finish not possible — session under one minute.';

  @override
  String get livePaceRunning => 'live';

  @override
  String liveRunningNotice(String time) {
    return 'Live clock running · $time';
  }

  @override
  String liveDurationA11y(String time, String state) {
    return 'Duration $time, $state';
  }

  @override
  String analysisWeeklyA11y(String from, String to) {
    return 'Weekly distance of the last 8 weeks, from $from to $to.';
  }

  @override
  String analysisWeeklyGapA11y(int kw) {
    return 'Week $kw without a session';
  }

  @override
  String analysisWeeklyWeek(int kw) {
    return 'W$kw';
  }

  @override
  String analysisPctThis(String date) {
    return 'This session · $date';
  }

  @override
  String get analysisPctSlowest => 'slowest';

  @override
  String get analysisPctFastest => 'fastest';

  @override
  String analysisPaceRange(String value, String from, String to) {
    return 'Average $value · range $from to $to';
  }

  @override
  String distBucketBelow(String v) {
    return '< $v km';
  }

  @override
  String distBucketRange(String a, String b) {
    return '$a–$b km';
  }

  @override
  String distBucketAbove(String v) {
    return '> $v km';
  }

  @override
  String get cardioAllSessions => 'All sessions';

  @override
  String cardioWeekA11y(String km, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return '$km kilometres this week, from $_temp0';
  }

  @override
  String cardioWeekShiftA11y(String delta, String dir, String avg) {
    return '$delta $dir than the 4-week average of $avg';
  }

  @override
  String cardioTotalA11y(String km, String date, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return '$km kilometres in total since $date, from $_temp0';
  }

  @override
  String hybridWeekSummary(int n, int min) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return '$_temp0 · $min min';
  }

  @override
  String get ratioOpenStrength => 'Opens strength history';

  @override
  String get ratioOpenCardio => 'Opens endurance analysis';

  @override
  String ratioShiftA11y(String value, String dir) {
    return '$value percentage points $dir than the 4-week average';
  }

  @override
  String get hybridEmptyStrength => 'Start strength training';

  @override
  String get hybridEmptyCardio => 'Log endurance';

  @override
  String get whenToday => 'Today';

  @override
  String get whenYesterday => 'Yesterday';

  @override
  String whenLast(String date) {
    return 'Last $date';
  }

  @override
  String get recoveryFormTitle => 'Log recovery';

  @override
  String tempoPerKm(String value) {
    return '$value /km';
  }

  @override
  String tempoKmh(String value) {
    return '$value km/h';
  }

  @override
  String cardioListCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get intensityTitle => 'Intensity';

  @override
  String acwrLabel(String v) {
    return 'Load · ACWR $v';
  }

  @override
  String get acwrBandLow => 'undertrained';

  @override
  String get acwrBandOptimal => 'optimal';

  @override
  String get acwrBandHigh => 'elevated';

  @override
  String get acwrBandDanger => 'critical';

  @override
  String get acwrBandNoteLow =>
      'Zone undertrained — acute load is below chronic load.';

  @override
  String get acwrBandNoteOptimal =>
      'Zone optimal — acute load matches chronic load.';

  @override
  String get acwrBandNoteHigh =>
      'Zone elevated — acute load exceeds chronic load.';

  @override
  String get acwrBandNoteDanger =>
      'Zone critical — acute load far above chronic load.';

  @override
  String acwrScaleA11y(String v, String zone, String from, String to) {
    return 'Load $v, zone $zone, range $from to $to.';
  }

  @override
  String historyMonthOpenA11y(String month, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return '$month, $_temp0, opens the list';
  }

  @override
  String get exerciseAddToPlan => 'Add to plan';

  @override
  String exerciseAddedToPlan(String plan) {
    return 'Added to “$plan”';
  }

  @override
  String exerciseRequiredA11y(int n) {
    return '$n of 3 required fields filled';
  }

  @override
  String exerciseMoreFilled(int n) {
    return '$n filled';
  }

  @override
  String get sessionFieldKind => 'Type';

  @override
  String get sessionKindNote =>
      'The type determines which values appear below.';

  @override
  String get sessionPaceNote => 'Pace is calculated and cannot be entered.';

  @override
  String get exercisesFilterOrigin => 'Origin';

  @override
  String get formReadiness => 'Readiness';

  @override
  String get formReadinessHint => 'Before the session. Optional.';

  @override
  String get formReadiness1 => 'drained';

  @override
  String get formReadiness2 => 'tired';

  @override
  String get formReadiness3 => 'okay';

  @override
  String get formReadiness4 => 'good';

  @override
  String get formReadiness5 => 'fresh';

  @override
  String get formFeeling => 'How it felt';

  @override
  String get formFeeling1 => 'wiped';

  @override
  String get formFeeling2 => 'tired';

  @override
  String get formFeeling3 => 'okay';

  @override
  String get formFeeling4 => 'good';

  @override
  String get formFeeling5 => 'strong';

  @override
  String get formFocus => 'Focus';

  @override
  String get formFocusHint => 'What the session worked. Does not replace sets.';

  @override
  String get focusPush => 'Push';

  @override
  String get focusPull => 'Pull';

  @override
  String get focusLegs => 'Legs';

  @override
  String get focusUpperBody => 'Upper body';

  @override
  String get focusLowerBody => 'Lower body';

  @override
  String get focusFullBody => 'Full body';

  @override
  String get focusCore => 'Core';

  @override
  String get focusOther => 'Other';

  @override
  String get strengthFormTitle => 'Log strength session';

  @override
  String get strengthFormNoSets =>
      'This session carries no sets. It counts in minutes, not volume — and appears in no muscle distribution.';

  @override
  String get strengthSavedSnack => 'Strength session saved';

  @override
  String get hybridTimeTitle => 'Training time';

  @override
  String get hybridTimeGroup => 'Training time window';

  @override
  String get hybridTimeDays28 => '28 days';

  @override
  String hybridTimeUnits(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workouts',
      one: '1 workout',
    );
    return '$_temp0';
  }

  @override
  String hybridTimeWithoutDuration(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workouts without duration not included',
      one: '1 workout without duration not included',
    );
    return '$_temp0';
  }

  @override
  String get hybridTimeNote =>
      'No target ratio — the app does not know how much cardio or recovery is right.';

  @override
  String hybridTimeRowA11y(String track, int minutes, int n, int percent) {
    return '$track: $minutes minutes, $n workouts, $percent percent';
  }

  @override
  String hybridTimeEmpty(int days) {
    return 'No workout with a duration in the last $days days.';
  }

  @override
  String get hybridHeatmapTitle => 'Training days';

  @override
  String hybridHeatmapWindow(int weeks) {
    return '$weeks weeks';
  }

  @override
  String hybridHeatmapBasis(int trained, int total) {
    return '$trained of $total days trained';
  }

  @override
  String hybridHeatmapByTrack(int strength, int cardio, int recovery) {
    return '$strength strength · $cardio cardio · $recovery recovery';
  }

  @override
  String get hybridHeatmapLegendNone => 'no training';

  @override
  String get hybridHeatmapLegendMixed => 'several';

  @override
  String hybridHeatmapWeekA11y(int week, int days, String detail) {
    return 'Week $week: $days training days. $detail';
  }

  @override
  String hybridHeatmapWeekNoneA11y(int week) {
    return 'Week $week: no training';
  }

  @override
  String hybridHeatmapMixed(String weekday) {
    return '$weekday several kinds';
  }

  @override
  String get analysisMaxTitle => 'Estimated max';

  @override
  String get analysisMaxHint =>
      'Epley: weight × (1 + reps ÷ 30), best estimate per workout. An estimate, not a test.';

  @override
  String analysisMaxBasis(int n, String best) {
    return '$n workouts · best $best kg';
  }

  @override
  String analysisMaxDelta(String delta) {
    return '$delta kg since the first workout';
  }

  @override
  String analysisMaxDeltaA11y(String direction, String delta) {
    return '$direction $delta kilograms since the first workout';
  }

  @override
  String get analysisMaxNoDelta => 'no comparison available';

  @override
  String analysisMaxThinBody(int n, int reps) {
    return 'From $n workouts per exercise with weight and at most $reps reps per set.';
  }

  @override
  String analysisMaxProgress(String name, int cur, int req) {
    return '$name: $cur of $req workouts';
  }

  @override
  String analysisMaxChartA11y(String name, String first, String last, int n) {
    return '$name: estimated max from $first to $last kilograms over $n workouts';
  }

  @override
  String get analysisMaxExerciseGroup => 'Exercise for the estimated max';

  @override
  String balanceSetsShort(int n) {
    return '$n s';
  }

  @override
  String balanceGapDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get balanceThinNote =>
      'A share from only a few workouts swings more than it says. The tile therefore shows how far there is to go instead of drawing a distribution.';

  @override
  String balanceTileA11y(String title, String basis, String window) {
    return '$title, $basis, $window';
  }

  @override
  String get balanceLoading => 'Loading muscle balance';

  @override
  String get balanceErrorTitle => 'Muscle balance unavailable';

  @override
  String get balanceErrorBody => 'The workouts could not be loaded right now.';

  @override
  String historyFreqBasis(int n, int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weeks',
      one: '1 week',
    );
    return '$n× in $_temp0';
  }

  @override
  String get historyVolumeSub => 'last session';

  @override
  String historyCurveCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get historyCurveRepsLabel => 'Reps per session';

  @override
  String historyRepsValue(int n) {
    return '$n reps';
  }

  @override
  String historySetsA11y(int sets, int reps) {
    return '$sets times $reps';
  }

  @override
  String historySetsOnlyA11y(int sets) {
    String _temp0 = intl.Intl.pluralLogic(
      sets,
      locale: localeName,
      other: '$sets sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String historyKgA11y(String v) {
    return '$v kilograms';
  }

  @override
  String historyRepsA11y(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n reps',
      one: '1 rep',
    );
    return '$_temp0';
  }

  @override
  String historyFreqA11y(String n) {
    return '$n per week';
  }

  @override
  String historyDateA11y(String date) {
    return 'on $date';
  }

  @override
  String historyTileA11y(String label, String value, String detail) {
    return '$label, $value, $detail';
  }

  @override
  String historyCountA11y(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'performed $n times',
      one: 'performed once',
    );
    return '$_temp0';
  }

  @override
  String historyCurveBestA11y(String best) {
    return 'best $best';
  }

  @override
  String historyCurveRepsA11y(int n, String from, String to) {
    return 'Reps per session across $n sessions, from $from to $to';
  }

  @override
  String thresholdProgress(int cur, int req) {
    return '$cur of $req';
  }

  @override
  String get focusDistTitle => 'Focus';

  @override
  String get focusDistWindow => '8 weeks';

  @override
  String get focusDistWhat =>
      'What your strength workouts targeted — push, pull, legs and more, as a share with its basis.';

  @override
  String focusDistCondition(int n) {
    return 'From $n workouts with a focus';
  }

  @override
  String focusDistCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workouts',
      one: '1 workout',
    );
    return '$_temp0';
  }

  @override
  String focusDistRowA11y(String focus, int n, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workouts',
      one: '1 workout',
    );
    return '$focus, $_temp0, $percent percent';
  }

  @override
  String focusDistBasis(int withFocus, int total) {
    return '$withFocus of $total workouts with a focus';
  }

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressWindow => '4 weeks';

  @override
  String get progressWhat =>
      'This lists the exercises where you set a new best in the last 4 weeks — by weight, reps or hold time.';

  @override
  String get progressCondition => 'From the second time you do an exercise';

  @override
  String get progressNone => 'No new best in the last 4 weeks.';

  @override
  String progressBasis(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exercises',
      one: '1 exercise',
    );
    String _temp1 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m workouts',
      one: '1 workout',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String progressOn(String date) {
    return 'on $date';
  }

  @override
  String progressReps(String v) {
    return '$v reps';
  }

  @override
  String progressSeconds(String v) {
    return '$v s';
  }

  @override
  String progressBefore(String v) {
    return 'before $v';
  }

  @override
  String progressRowA11y(
      String name, String value, String before, String delta, String date) {
    return '$name, $value, before $before, $delta more, on $date';
  }

  @override
  String get progressOpensExercise => 'opens exercise';

  @override
  String progressA11yReps(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n reps',
      one: '1 rep',
    );
    return '$_temp0';
  }

  @override
  String progressA11ySeconds(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String progressA11yKg(String v) {
    return '$v kilograms';
  }

  @override
  String get weeklySetsTitle => 'Sets per week';

  @override
  String get weeklySetsWhat =>
      'How many sets you do week by week — and whether this week is more or less than usual.';

  @override
  String get weeklySetsCondition => 'From your first workout with sets';

  @override
  String weeklySetsSessions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workouts',
      one: '1 workout',
    );
    return '$_temp0';
  }

  @override
  String weeklySetsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'sets',
      one: 'set',
    );
    return '$_temp0';
  }

  @override
  String weeklySetsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String weeklySetsPending(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Comparison after 2 full weeks · $n to go',
      one: 'Comparison after 2 full weeks · 1 to go',
    );
    return '$_temp0';
  }

  @override
  String weeklySetsWithoutSets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workouts without sets not counted',
      one: '1 workout without sets not counted',
    );
    return '$_temp0';
  }

  @override
  String weeklySetsHeadA11y(String sets, String sessions) {
    return 'This week, $sets in $sessions';
  }

  @override
  String weeklySetsShiftA11y(String delta, String direction, String avg) {
    return '$delta $direction than the 4-week average of $avg';
  }

  @override
  String weeklySetsShiftEqualA11y(String avg) {
    return 'the same as the 4-week average of $avg';
  }

  @override
  String weeklySetsStripA11y(String weeks) {
    return 'Sets per week: $weeks';
  }

  @override
  String weeklySetsWeekA11y(int week, int n) {
    return 'Week $week: $n';
  }

  @override
  String weeklySetsBeforeStartA11y(int week) {
    return 'Week $week: before your first workout';
  }

  @override
  String weeklySetsAxis(int week) {
    return 'Wk $week';
  }

  @override
  String get analysisMaxWhat =>
      'How your strongest sets develop per exercise, estimated with Epley.';

  @override
  String analysisMaxCondition(int n, int reps) {
    return 'From $n workouts with weight, up to $reps reps';
  }

  @override
  String get analysisMaxBodyweightNote =>
      'Bodyweight exercises without added weight do not count here — their progress is listed under “Progress”.';

  @override
  String get wellnessTrendTitle => 'Before and after';

  @override
  String wellnessTrendWindow(int weeks) {
    return '$weeks weeks';
  }

  @override
  String get wellnessTrendWhat =>
      'Readiness before and feeling after each strength workout, side by side.';

  @override
  String wellnessTrendCondition(int n) {
    return 'From $n workouts with both entries';
  }

  @override
  String get wellnessTrendLegend => 'top before · bottom after';

  @override
  String wellnessTrendHigher(int n) {
    return '$n higher after';
  }

  @override
  String wellnessTrendSame(int n) {
    return '$n the same';
  }

  @override
  String wellnessTrendLower(int n) {
    return '$n lower after';
  }

  @override
  String wellnessTrendCountsA11y(int higher, int same, int lower) {
    return 'Higher after: $higher. The same: $same. Lower after: $lower.';
  }

  @override
  String wellnessTrendBasis(int n, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total workouts',
      one: '1 workout',
    );
    return '$n of $_temp0 with both answers';
  }

  @override
  String wellnessTrendOnlyOne(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workouts with only one answer are not included',
      one: '1 workout with only one answer is not included',
    );
    return '$_temp0';
  }

  @override
  String wellnessTrendPair(
      String date, int before, String beforeWord, int after, String afterWord) {
    return '$date: before $before $beforeWord, after $after $afterWord';
  }

  @override
  String wellnessTrendRowA11y(String pairs) {
    return 'Before and after per workout, oldest first. $pairs';
  }

  @override
  String wellnessTrendOpenExercise(String label) {
    return '$label, opens exercise';
  }

  @override
  String get segPlans => 'Plans';

  @override
  String get planCatalogBody =>
      'Plans by ATEM will appear here soon, free and as Premium. Your own plans are above.';

  @override
  String monthsWindow(int n) {
    return '$n months';
  }

  @override
  String monthsBasis(int n, int days, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workouts',
      one: '1 workout',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 on $_temp1 · since $date';
  }

  @override
  String monthsEntryA11y(String month, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workouts',
      one: '1 workout',
      zero: 'no workout',
    );
    return '$month: $_temp0';
  }

  @override
  String monthsNotMeasuredA11y(String month) {
    return '$month: not recorded';
  }

  @override
  String planCardA11y(String name, int n, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exercises',
      one: '1 exercise',
    );
    return '$name, $_temp0, about $minutes minutes, opens plan';
  }

  @override
  String planCardStartA11y(String name) {
    return 'Start: $name';
  }

  @override
  String explainOpenA11y(String title) {
    return 'Explanation for $title, expand';
  }

  @override
  String explainCloseA11y(String title) {
    return 'Explanation for $title, collapse';
  }

  @override
  String get balanceExplain =>
      'Share of sets per muscle over the last 8 weeks, counted across strength workouts with exercises. Cardio, recovery and workouts without exercises add nothing. No target ratio — the app does not know how much back is right.';

  @override
  String get monthsExplain =>
      'Workouts per calendar month. A dash means: measured, no workout. Empty means: before your first workout.';

  @override
  String get historyExplain =>
      'Latest, best, frequency and volume from your workouts with this exercise. The curve appears from 5 sessions — fewer points would make a straight line look like a trend.';

  @override
  String get progressExplainMeasure =>
      'Each exercise is compared with the best value of all earlier sessions: weight if you ever used extra load, otherwise reps, otherwise hold time. Warm-up sets do not count.';

  @override
  String get weeklySetsExplainAverage =>
      'Compared with the average of the 4 full weeks before — only weeks since your first strength workout count. Warm-up sets do not count. No target.';

  @override
  String get focusDistExplainWithout =>
      'The share only counts workouts where you picked a focus at the start — workouts without a focus are not included. No target ratio.';

  @override
  String get wellnessTrendExplain =>
      'Top is your readiness before the workout, bottom how you felt after, each from 1 to 5. “Higher” only means higher, not better. Workouts with only one of the two answers are not included.';

  @override
  String get hybridTimeExplain =>
      'How your training minutes split across strength, cardio and recovery — this week or over the last 28 days. Minutes are the only measure all three tracks share.';

  @override
  String get hybridHeatmapExplain =>
      'Each tile is a day, each column a week. The colour shows what you trained that day. Breaks are not penalised.';

  @override
  String hybridHeatmapOfDays(int total) {
    return 'of $total days trained';
  }

  @override
  String get hybridTimeWeek => 'This week';

  @override
  String hybridTimeSets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String hybridTimeTonnage(String t) {
    return '$t t volume';
  }

  @override
  String hybridTimeBasisShort(int minutes, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workouts',
      one: '1 workout',
    );
    return '$minutes min · $_temp0';
  }

  @override
  String get hybridTimeEmptyWeek => 'No workout with a duration this week yet.';

  @override
  String get hybridTimeShiftExplain =>
      'The arrows in “This week” compare the share with the average of the four weeks before, in percentage points. They appear once your workouts reach back four weeks.';

  @override
  String hybridTimeRowShiftA11y(
      String track, int minutes, int n, int percent, String shift) {
    return '$track: $minutes minutes, $n workouts, $percent percent, $shift';
  }

  @override
  String weeklySetsWindow(int weeks) {
    return '$weeks weeks';
  }

  @override
  String get infoTitle => 'Info';

  @override
  String get infoSub => 'Legal notices and app details';

  @override
  String infoVersionLine(String version) {
    return 'Version $version';
  }

  @override
  String workoutPreviousShort(String weight, int reps) {
    return '$weight×$reps';
  }

  @override
  String workoutValueEditA11y(String field, int set, String value) {
    return '$field, set $set, $value, tap to change';
  }

  @override
  String get workoutValueEmpty => 'no value';

  @override
  String get workoutSetTypeLegendTitle => 'Set types';

  @override
  String get workoutFormGuideDescription => 'In short';

  @override
  String get workoutRunnerTableHold => 'HOLD';

  @override
  String stepPadTitleWeight(int n) {
    return 'WEIGHT · SET $n';
  }

  @override
  String stepPadTitleReps(int n) {
    return 'REPS · SET $n';
  }

  @override
  String stepPadTitleHold(int n) {
    return 'HOLD · SET $n';
  }

  @override
  String get stepPadFieldWeight => 'Weight in kilograms';

  @override
  String get stepPadFieldReps => 'Repetitions';

  @override
  String get stepPadFieldHold => 'Hold time in seconds';

  @override
  String stepPadPrevious(String value) {
    return 'Last time: $value';
  }

  @override
  String stepPadDelta(String value, String unit) {
    return '$value $unit VS LAST TIME';
  }

  @override
  String stepPadDeltaA11y(String value, String unit) {
    return '$value $unit compared with last time';
  }

  @override
  String get stepPadKeyboard => 'KEYBOARD';

  @override
  String get stepPadRuler => 'SLIDER';

  @override
  String stepPadKeyboardA11y(String field) {
    return 'Keyboard instead of slider, $field';
  }

  @override
  String stepPadRulerA11y(String field) {
    return 'Slider instead of keyboard, $field';
  }

  @override
  String stepPadHint(String step) {
    return 'DRAG TO SET · STEP $step';
  }

  @override
  String get stepPadApply => 'APPLY';

  @override
  String stepPadStepKg(String step) {
    return '$step kg';
  }

  @override
  String stepPadStepSeconds(String step) {
    return '$step s';
  }

  @override
  String stepPadStepPlain(String step) {
    return '$step';
  }

  @override
  String stepPadStepA11y(String step, String field) {
    return 'Step $step, $field';
  }

  @override
  String stepPadSliderA11y(String field) {
    return '$field, drag to set';
  }

  @override
  String get stepPadIncrease => 'Increase value';

  @override
  String get stepPadDecrease => 'Decrease value';

  @override
  String stepPadQuickA11y(String value) {
    return 'Change by $value';
  }

  @override
  String get stepPadClose => 'Close input';

  @override
  String get workoutRunnerTableSetShort => 'TYPE';

  @override
  String get workoutRunnerTableLastShort => 'LAST';

  @override
  String get workoutRunnerTableHoldShort => 'SEC';

  @override
  String get stepPadUnitWeight => 'KG';

  @override
  String get stepPadUnitReps => 'REPS';

  @override
  String get stepPadUnitHold => 'SEC';

  @override
  String get workoutValueNone => '—';

  @override
  String get exerciseUnilateralLabel => 'Trained per side';

  @override
  String get exerciseUnilateralHint =>
      'For one-sided exercises like a single-dumbbell curl or a lunge — the runner then asks for left or right on every set.';

  @override
  String exerciseUnilateralA11y(String label, String state) {
    return '$label, $state';
  }

  @override
  String get exerciseUnilateralMeta => 'per side';

  @override
  String get hardSetsTitle => 'Hard sets';

  @override
  String hardSetsWindow(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String hardSetsCondition(int n) {
    return 'From $n sets with effort';
  }

  @override
  String get hardSetsExplainWhat =>
      'A hard set is one with effort 7 or more on the 1 to 10 scale. The rating is optional and chosen when you check off a set.';

  @override
  String get hardSetsExplainWhy =>
      'Sets are counted, not kilograms: a bodyweight pull-up counts the same as a barbell set.';

  @override
  String get hardSetsExplainSides =>
      'For one-sided exercises, one set left and one set right count as one set together.';

  @override
  String hardSetsExplainNoTarget(int days) {
    return 'No target — the app does not know how many hard sets are right. The arrows compare with the $days days before.';
  }

  @override
  String hardSetsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'hard sets',
      one: 'hard set',
    );
    return '$_temp0';
  }

  @override
  String hardSetsBasis(int hard, int total, int rpe) {
    return '$hard hard of $total sets · $rpe rated';
  }

  @override
  String hardSetsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hard sets',
      one: '1 hard set',
    );
    return '$_temp0';
  }

  @override
  String hardSetsHeadA11y(String count, int days) {
    return '$count in $days days';
  }

  @override
  String hardSetsShiftA11y(int n, String direction, int days) {
    return '$n $direction than in the $days days before';
  }

  @override
  String hardSetsShiftEqualA11y(int days) {
    return 'as many as in the $days days before';
  }

  @override
  String get workoutSideLeftShort => 'L';

  @override
  String get workoutSideRightShort => 'R';

  @override
  String get workoutSideLeft => 'left';

  @override
  String get workoutSideRight => 'right';

  @override
  String workoutSideA11y(String side, int n, String other) {
    return 'Side $side, set $n. Tap to switch to $other';
  }

  @override
  String workoutSideDoneA11y(String side, int n) {
    return 'Side $side, set $n';
  }

  @override
  String workoutRpeQuestion(int n) {
    return 'How hard was set $n?';
  }

  @override
  String workoutRpeGroupA11y(int n) {
    return 'Effort of set $n';
  }

  @override
  String workoutRpeRangeA11y(int from, int to) {
    return 'RPE $from to $to';
  }

  @override
  String get workoutRpeNone => 'no rating';

  @override
  String workoutRpeNoneA11y(int n) {
    return 'No effort rating for set $n';
  }

  @override
  String get workoutRpeShowLow => 'Show 1–5';

  @override
  String get workoutRpeHideLow => 'Hide 1–5';

  @override
  String get workoutRpeShowLowA11y => 'Show levels 1 to 5';

  @override
  String get workoutRpeHideLowA11y => 'Hide levels 1 to 5';

  @override
  String get workoutRpeWordMax => 'max';

  @override
  String workoutRpeWordReserve(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n reps left',
      one: '1 rep left',
    );
    return '$_temp0';
  }

  @override
  String get workoutRpeWordReserveMany => '5+ left';

  @override
  String get workoutRpeWordEasy => 'easy';

  @override
  String get workoutRpeMaxA11y => 'no more reps possible';

  @override
  String workoutRpeReserveA11y(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n more reps possible',
      one: '1 more rep possible',
    );
    return '$_temp0';
  }

  @override
  String get workoutRpeReserveManyA11y => '5 or more reps possible';

  @override
  String workoutRpeLevelA11y(int level, String word) {
    return 'RPE $level, $word';
  }

  @override
  String workoutRpeBadge(int rpe) {
    return 'RPE $rpe';
  }

  @override
  String get workoutHardSet => 'hard set';

  @override
  String workoutRpeBadgeA11y(int n, int rpe) {
    return 'Set $n, RPE $rpe. Tap to change';
  }

  @override
  String workoutRpeBadgeHardA11y(int n, int rpe) {
    return 'Set $n, RPE $rpe, hard set. Tap to change';
  }

  @override
  String get workoutSidesLabel => 'Sides';

  @override
  String get workoutSidesBoth => 'Both';

  @override
  String get workoutSidesSplit => 'Separate';

  @override
  String get workoutSidesBothA11y => 'Both sides, sets without a side';

  @override
  String get workoutSidesSplitA11y =>
      'Separate, left and right as their own sets';

  @override
  String workoutSidesGroupA11y(String name) {
    return 'Sides for exercise $name';
  }

  @override
  String get platesToggle => 'Plates';

  @override
  String get platesToggleShowA11y => 'Show plates per side';

  @override
  String get platesToggleHideA11y => 'Hide plates';

  @override
  String get platesBarLabel => 'BAR';

  @override
  String platesBarKg(String kg) {
    return '$kg kg';
  }

  @override
  String platesBarA11y(String kg) {
    return '$kg kilogram bar';
  }

  @override
  String platesTimes(String count, String plate) {
    return '$count × $plate';
  }

  @override
  String platesPerSide(String plates, String bar) {
    return 'per side: $plates · bar $bar kg';
  }

  @override
  String platesEmptyBar(String bar) {
    return 'Empty bar · $bar kg';
  }

  @override
  String platesBelowBar(String bar) {
    return 'Lighter than the bar ($bar kg)';
  }

  @override
  String platesRemainder(String rest, String loaded) {
    return '$rest kg cannot be loaded — nearest value $loaded kg';
  }

  @override
  String platesA11yPlate(int count, String plate) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times $plate',
      one: 'one $plate',
    );
    return '$_temp0';
  }

  @override
  String platesA11y(String plates, String bar) {
    return 'Plates per side: $plates. Bar $bar kilograms';
  }

  @override
  String platesA11yEmptyBar(String bar) {
    return 'Empty bar, $bar kilograms, no plates';
  }

  @override
  String platesA11yBelowBar(String bar) {
    return 'Lighter than the $bar kilogram bar, no plates possible';
  }

  @override
  String platesA11yRemainder(String rest, String loaded) {
    return 'Remaining $rest kilograms cannot be loaded, nearest value $loaded kilograms';
  }

  @override
  String get plansOwnLabel => 'Your plans';

  @override
  String get trainFreeBody => 'Begin without a plan';

  @override
  String get trainPlanBody => 'From your plans';

  @override
  String workoutRirBadge(int rir) {
    return '$rir RIR';
  }

  @override
  String workoutRirBadgeA11y(int n, int rir) {
    String _temp0 = intl.Intl.pluralLogic(
      rir,
      locale: localeName,
      other: '$rir reps in reserve',
      one: '1 rep in reserve',
      zero: 'no reps in reserve',
    );
    return 'Set $n, $_temp0. Tap to change';
  }

  @override
  String workoutRirBadgeHardA11y(int n, int rir) {
    String _temp0 = intl.Intl.pluralLogic(
      rir,
      locale: localeName,
      other: '$rir reps in reserve',
      one: '1 rep in reserve',
      zero: 'no reps in reserve',
    );
    return 'Set $n, $_temp0, hard set. Tap to change';
  }

  @override
  String workoutRirLevelA11y(int level, String word) {
    return 'RIR $level, $word';
  }

  @override
  String workoutRirRangeA11y(int from, int to) {
    return 'RIR $from to $to';
  }

  @override
  String get workoutRirShowLow => 'Show 5–9';

  @override
  String get workoutRirHideLow => 'Hide 5–9';

  @override
  String get workoutRirShowLowA11y => 'Show levels 5 to 9 in reserve';

  @override
  String get workoutRirHideLowA11y => 'Hide levels 5 to 9 in reserve';

  @override
  String get settingsEffortScale => 'Effort per set';

  @override
  String get settingsEffortScaleRpe => 'RPE';

  @override
  String get settingsEffortScaleRir => 'RIR';

  @override
  String get settingsEffortScaleValue => 'RPE — higher is harder';

  @override
  String get settingsEffortScaleValueRir => 'RIR — lower is harder';

  @override
  String get settingsEffortScaleGroupA11y => 'Scale for effort per set';

  @override
  String get settingsEffortScaleRpeA11y =>
      'RPE, effort from 1 to 10, higher means harder';

  @override
  String get settingsEffortScaleRirA11y =>
      'RIR, reps in reserve, lower means harder';

  @override
  String get settingsEffortScaleExplain =>
      'The same entry, counted the other way. RPE 8 is 2 RIR: two reps were left in the tank. What is stored never changes — switching only changes the display, including for past sets, and you can switch back at any time.';

  @override
  String get hardSetsExplainWhatRir =>
      'A hard set is one with at most 3 reps in reserve. The entry is optional and is chosen when you tick off a set in the runner.';

  @override
  String get analysisLockedBadge => 'Locked';

  @override
  String analysisLockedA11y(String title, String condition, int cur, int req) {
    return '$title: locked. $condition. $cur of $req.';
  }

  @override
  String sectionBarA11y(String name, int n, int total) {
    return 'Topic $name, $n of $total. Opens the topic list.';
  }

  @override
  String get sectionJumpTitle => 'Jump to';

  @override
  String sectionJumpA11y(String name, int n, int total) {
    return 'Jump to $name, $n of $total';
  }

  @override
  String sectionArrivedA11y(String name, int n, int total) {
    return '$name, $n of $total';
  }

  @override
  String get sectionHere => 'HERE';

  @override
  String get trainTodayKicker => 'Planned today';

  @override
  String get trainCatalog => 'Exercise catalog';

  @override
  String get trainLogLater => 'Log a past session';

  @override
  String get historyTotalLabel => 'Sessions logged';

  @override
  String historyTotalSince(String date) {
    return 'since $date';
  }

  @override
  String get plansAtemLabel => 'ATEM plans';

  @override
  String get trainFreeTitle => 'Start free';

  @override
  String get workoutEffortAdd => 'Add effort';

  @override
  String workoutEffortAddA11y(int n) {
    return 'Set $n, add effort';
  }

  @override
  String get settingsEffortScaleRpeLong => 'RPE · Exertion';

  @override
  String get settingsEffortScaleRirLong => 'RIR · Reps in reserve';

  @override
  String balanceCondition(int n) {
    return 'From $n workouts with exercises';
  }

  @override
  String get weightBlockTitle => 'Weight';

  @override
  String get weightUnitKg => 'KG';

  @override
  String weightEntries(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n entries',
      one: '1 entry',
    );
    return '$_temp0';
  }

  @override
  String weightBasis(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n entries',
      one: '1 entry',
    );
    return '$_temp0 since $date';
  }

  @override
  String weightChangeUp(String delta, String date, int days) {
    return '$delta kg since $date · $days days ago';
  }

  @override
  String weightChangeDown(String delta, String date, int days) {
    return '$delta kg since $date · $days days ago';
  }

  @override
  String weightChangeUpA11y(String delta, String date, int days) {
    return '$delta kilograms more since $date, $days days ago';
  }

  @override
  String weightChangeDownA11y(String delta, String date, int days) {
    return '$delta kilograms less since $date, $days days ago';
  }

  @override
  String weightAnchor(String date, String kg) {
    return '$date · $kg kg';
  }

  @override
  String weightLastEntryDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Last entry $n days ago',
      one: 'Last entry yesterday',
      zero: 'Last entry today',
    );
    return '$_temp0';
  }

  @override
  String get weightEnterCta => 'Log entry';

  @override
  String get weightStartCta => 'Start';

  @override
  String get weightSingleValueTitle => 'Log your first history value';

  @override
  String weightSingleValueNote(String date) {
    return 'From setup, $date — no second entry yet.';
  }

  @override
  String weightSingleValueFirst(String date) {
    return 'First entry, $date — no second entry yet.';
  }

  @override
  String get weightSingleValueSeed =>
      'Carried over from settings — no history entry yet.';

  @override
  String get weightSingleValueWhy =>
      'No history, no curve: one value does not make a series.';

  @override
  String weightGapNote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weeks without an entry',
      one: '1 week without an entry',
    );
    return '$_temp0';
  }

  @override
  String weightLastKnown(String date) {
    return 'LAST KNOWN · $date';
  }

  @override
  String get weightLoadError => 'History could not be refreshed.';

  @override
  String get weightRange3m => '3 mo';

  @override
  String get weightRange6m => '6 mo';

  @override
  String get weightRange1y => '1 yr';

  @override
  String get weightRangeAll => 'All';

  @override
  String get weightRangeGroup => 'Range';

  @override
  String weightRangeA11y(String range) {
    return 'Range $range, selected';
  }

  @override
  String get weightSheetTitle => 'LOG WEIGHT';

  @override
  String get weightSheetEditTitle => 'EDIT ENTRY';

  @override
  String weightDateToday(String date) {
    return 'Today · $date';
  }

  @override
  String get weightDatePick => 'Choose date';

  @override
  String weightDateChipA11y(String date) {
    return 'Date, $date. Change.';
  }

  @override
  String weightSameDayNote(String kg) {
    return 'Already logged today: $kg kg. A second entry replaces it.';
  }

  @override
  String weightPadPrevious(String kg, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days DAYS AGO',
      one: '1 DAY AGO',
      zero: 'TODAY',
    );
    return 'LAST $kg KG · $_temp0';
  }

  @override
  String get weightUpdateCta => 'Update';

  @override
  String weightRetroTitle(String from, String to) {
    return 'AFFECTS $from – $to';
  }

  @override
  String get weightRetroScope => 'UNTIL THE NEXT ENTRY · NOT THE WHOLE HISTORY';

  @override
  String weightRetroSets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n bodyweight sets',
      one: '1 bodyweight set',
    );
    return '$_temp0';
  }

  @override
  String get weightRetroNone => 'No bodyweight sets in this range';

  @override
  String weightConfirmSnack(String kg, String date) {
    return 'Weight $kg kg · logged $date';
  }

  @override
  String get weightDeleteEntry => 'Delete entry';

  @override
  String get weightDeleteTitle => 'Delete entry?';

  @override
  String weightDeleteBody(String date, String kg) {
    return '$date · $kg kg. Those days will fall back to the previous value.';
  }

  @override
  String get weightDeleteConfirm => 'Delete for good';

  @override
  String weightDeletedSnack(String date) {
    return 'Entry from $date deleted';
  }

  @override
  String get weightSourceTyped => 'Manual entry';

  @override
  String get weightSourceMeasured => 'From Health Connect';

  @override
  String get weightSourceSettings => 'Carried over from settings';

  @override
  String get weightExplainBody =>
      'Shows your body weight over time — what was, not a goal.';

  @override
  String get weightExplainChange =>
      'The change always compares with the previous entry.';

  @override
  String get weightExplainGaps =>
      'Gaps are not bridged: no line without a real entry behind it.';

  @override
  String get weightExplainSources =>
      'Filled dot: manual entry. Hollow dot: from Health Connect.';

  @override
  String get weightExplainLoad =>
      'The training load of a session uses the weight last known on its day.';

  @override
  String get weightHistoryOpen => 'Open history';

  @override
  String weightRowA11y(String date, String kg, String source) {
    return '$date, $kg kilograms, $source. Edit.';
  }

  @override
  String weightChartA11y(int n, String from, String to) {
    return 'History across $n entries, from $from to $to kilograms';
  }

  @override
  String weightChartGapA11y(int n, int weeks, String from, String to) {
    return 'History across $n entries with a gap of $weeks weeks, from $from to $to kilograms';
  }

  @override
  String weightChartThinA11y(int n, String from, String to) {
    return '$n entries without a connected curve, from $from to $to kilograms';
  }

  @override
  String weightCardA11y(String kg, String basis, String change) {
    return 'Weight, $kg kilograms, $basis, $change';
  }

  @override
  String weightCardSingleA11y(String kg) {
    return 'Weight, $kg kilograms, no second entry yet';
  }

  @override
  String get weightCardOpenHint => 'Opens the history';

  @override
  String weightSettingsMeta(String date, String source) {
    return 'Last $date · $source';
  }

  @override
  String get weightHistoryTitle => 'Weight history';

  @override
  String get weightLoadingA11y => 'Loading weight history';

  @override
  String hcInboxTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions from Health Connect',
      one: '1 session from Health Connect',
    );
    return '$_temp0';
  }

  @override
  String hcInboxMeta(String time) {
    return 'Read $time · awaiting review';
  }

  @override
  String get hcInboxAction => 'Review';

  @override
  String get hcRowUnreviewed => 'Unreviewed · not counted yet';

  @override
  String hcSheetTitle(int i, int n) {
    return 'Review session · $i of $n';
  }

  @override
  String get hcFieldDuration => 'Duration';

  @override
  String get hcFieldHrAvg => 'Avg. HR';

  @override
  String get hcFieldHrMax => 'Max';

  @override
  String hcMoreDeviceValues(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'More values from the device · $n',
      one: '1 more value from the device',
    );
    return '$_temp0';
  }

  @override
  String get hcAccept => 'Add to history';

  @override
  String get hcAcceptWithoutEffort => 'Add without effort';

  @override
  String get hcDecline => 'Don\'t add';

  @override
  String get hcNoEffortNote =>
      'Without effort this session is missing from training load — it is not estimated.';

  @override
  String get hcContinueLater => 'Continue later';

  @override
  String get hcDeclinedSection => 'Declined';

  @override
  String hcDeclinedMeta(String date) {
    return 'Declined on $date';
  }

  @override
  String get hcDeclinedRestore => 'Add after all';

  @override
  String get hcDeclinedNote => 'Will not be suggested again on the next read.';

  @override
  String get hcOriginWatch => 'from the watch';

  @override
  String get hcOriginBoth => 'app + watch';

  @override
  String get hcOriginMissingEffort => 'without effort';

  @override
  String get hcReadError => 'Health Connect unavailable';

  @override
  String hcReadErrorMeta(String date) {
    return 'Last read $date';
  }

  @override
  String get hcRetry => 'Retry';

  @override
  String get hcReading => 'Reading Health Connect';

  @override
  String hcRowA11y(String title, String meta) {
    return '$title, $meta, from the watch, unreviewed, not counted yet. Review.';
  }

  @override
  String hcInboxA11y(String count, String time) {
    return '$count awaiting review, read $time. Review.';
  }

  @override
  String get hcPairQuestion => 'Does this belong to your strength session?';

  @override
  String get hcPairAppRow => 'Your app session';

  @override
  String get hcPairWatchRow => 'From the watch';

  @override
  String hcPairOverlap(int x, int y, int d) {
    return 'Overlap $x of $y min of the shorter session · starts $d min apart';
  }

  @override
  String get hcPairMerge => 'Merge';

  @override
  String get hcPairKeepApart => 'Keep separate';

  @override
  String get hcMergeStage1Title => 'Merge — what changes';

  @override
  String get hcUnlinkStage1Title => 'Unlink — what changes';

  @override
  String hcMergeStays(String value) {
    return '$value stays';
  }

  @override
  String hcMergeGains(String value) {
    return 'becomes $value';
  }

  @override
  String get hcMergeLoses => 'is removed';

  @override
  String hcMergeDurationNote(int app, int watch) {
    return 'Duration stays with the app: $app min. The watch reports $watch min.';
  }

  @override
  String get hcMergedSnack => 'Merged · heart rate added';

  @override
  String get hcUnlinkedSnack => 'Unlinked · watch session back in the inbox';

  @override
  String get hcAmbiguousNote =>
      'Several app sessions fall in this window. ATEM does not assign when the match is not unique.';

  @override
  String get hcAmbiguousPick => 'Choose';

  @override
  String get hcAmbiguousStandalone => 'Review as its own session';

  @override
  String get hcUnlink => 'Unlink';

  @override
  String get hcSourcesLabel => 'Sources';

  @override
  String get hcSourceApp => 'App · sets, duration, effort';

  @override
  String hcSourceWatch(String device) {
    return '$device · heart rate, calories';
  }

  @override
  String hcWatchReports(String start, String end, int min) {
    return 'Watch reports $start–$end · $min min';
  }

  @override
  String get hcFieldSets => 'Sets';

  @override
  String get hcFieldEffort => 'Effort';

  @override
  String get hcFieldWatchSession => 'Watch session';

  @override
  String get hcBackToInbox => 'back to the inbox';

  @override
  String get hcPermSection => 'Health Connect';

  @override
  String get hcPermWeight => 'Body weight';

  @override
  String get hcPermSessions => 'Exercise sessions';

  @override
  String get hcPermGrant => 'Grant';

  @override
  String get hcPermInstall => 'Install';

  @override
  String get hcStateDenied => 'Not granted';

  @override
  String get hcPermMissingNote =>
      'Health Connect is not set up on this device. ATEM works without it — weight and sessions are kept by hand.';

  @override
  String get hcPermNoneNote =>
      'Nothing granted. ATEM reads only once you allow it per data type.';

  @override
  String get hcPermPartialNote =>
      'Weight is read, sessions are not. The inbox in your history appears with the second grant.';

  @override
  String hcPermRevokedNote(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n imported sessions stay as they are.',
      one: '1 imported session stays as it is.',
    );
    return '$_temp0 New ones are no longer read.';
  }

  @override
  String get hcOriginBothSpoken => 'app and watch';

  @override
  String get hcUndatedQuestion => 'Does this belong to one of your sessions?';

  @override
  String get hcUndatedNote =>
      'ATEM does not know the time of day for these sessions and therefore suggests nothing.';

  @override
  String get detailBack => 'History';

  @override
  String get detailKindStrength => 'Strength';

  @override
  String get detailKindBodyweight => 'Bodyweight';

  @override
  String get detailKindEndurance => 'Endurance';

  @override
  String get detailKindRecovery => 'Recovery';

  @override
  String detailTimeRange(String day, String date, String start, String end) {
    return '$day $date · $start–$end';
  }

  @override
  String detailTimeNoDuration(String day, String date) {
    return '$day $date · no duration recorded';
  }

  @override
  String get detailLeadSets => 'sets';

  @override
  String get detailLeadVolume => 'kg';

  @override
  String get detailLeadDistance => 'km';

  @override
  String get detailLeadDuration => 'min';

  @override
  String detailBasisStrength(int n, int dur, int rpe) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exercises',
      one: '$n exercise',
    );
    return '$_temp0 · $dur min · effort $rpe of 5';
  }

  @override
  String detailBasisRun(int dur, String pace) {
    return '$dur min · $pace /km average';
  }

  @override
  String detailBasisRecovery(String name) {
    return 'no load · $name';
  }

  @override
  String get detailBasisEmpty => 'Only type and day are known.';

  @override
  String get detailNoEffort => 'without effort';

  @override
  String get detailMetricDuration => 'Duration';

  @override
  String get detailMetricVolume => 'Volume';

  @override
  String get detailMetricHrAvg => 'Avg. HR';

  @override
  String get detailMetricCalories => 'Calories';

  @override
  String get detailMetricElevation => 'Elevation';

  @override
  String detailBlockWorkStrength(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Exercises · $n',
      one: 'Exercise · $n',
    );
    return '$_temp0';
  }

  @override
  String get detailBlockHr => 'Heart rate';

  @override
  String get detailBlockNote => 'Note';

  @override
  String detailDeltaVs(String glyph, String value, String date) {
    return '$glyph $value vs $date';
  }

  @override
  String detailZonesBasis(int min, int total, String date) {
    return 'From $min of $total min recorded · your zones from $date';
  }

  @override
  String detailZonesThin(int min, int total) {
    return 'Only $min of $total min recorded — the distribution describes that part, not the session.';
  }

  @override
  String get detailZonesUnset =>
      'Zones are not set. ATEM computes no distribution while the boundaries are missing.';

  @override
  String get detailZonesSetAction => 'Set zones';

  @override
  String detailZoneName(int n) {
    return 'Zone $n';
  }

  @override
  String detailZoneRangeUpto(int bpm) {
    return 'up to $bpm bpm';
  }

  @override
  String detailZoneRangeFrom(int bpm) {
    return 'from $bpm bpm';
  }

  @override
  String detailZoneRange(int from, int to) {
    return '$from–$to bpm';
  }

  @override
  String get detailExplainZones =>
      'Computed from the watch heart-rate series: each second counts into the zone it falls in. No target — the distribution describes what happened.';

  @override
  String get detailExplainVolume =>
      'Sum of reps × weight across all sets with a weight. Sets without weight are missing from volume and appear in the denominator.';

  @override
  String get detailErrorHr => 'Heart rate unavailable';

  @override
  String get detailRetry => 'Retry';

  @override
  String get detailEdit => 'Edit session';

  @override
  String get detailDelete => 'Delete session';

  @override
  String get settingsZonesTitle => 'Heart rate zones';

  @override
  String settingsZonesStateSet(String date) {
    return 'Set on $date';
  }

  @override
  String get settingsZonesStateUnset => 'Not set';

  @override
  String settingsZonesBasisPct(int hrmax) {
    return '% of max HR $hrmax';
  }

  @override
  String get settingsZonesBasisBpm => 'Absolute bpm';

  @override
  String get settingsZonesProposal => 'Compute proposal from max HR';

  @override
  String get settingsZonesProposalNote =>
      'A starting point, not a recommendation. Every boundary stays individually editable.';

  @override
  String settingsZonesBoundary(int n, int a, int b) {
    return 'Boundary $n · between zone $a and zone $b';
  }

  @override
  String settingsZonesBoundaryLimit(int bpm) {
    return 'At most $bpm bpm — the next boundary is above it.';
  }

  @override
  String get settingsZonesRetro =>
      'Applies to past sessions too: zones are computed from the stored heart-rate series, not fixed at import.';

  @override
  String get settingsZonesNoHrmax =>
      'Max HR is missing. Percentage boundaries need a value — or set the boundaries in bpm.';

  @override
  String get settingsZonesSaved => 'Zones saved';

  @override
  String get settingsZonesSetBounds => 'Set boundaries in bpm';

  @override
  String get settingsZonesHrMaxEnter => 'Enter max HR';

  @override
  String settingsZonesHrMaxLine(int hrmax, String date) {
    return 'Max HR $hrmax · entered by you on $date';
  }

  @override
  String get settingsZonesUnsetNote =>
      'Not set. Without boundaries a session shows its heart rate but no distribution.';

  @override
  String get settingsZonesKeepNote =>
      'Existing boundaries stay unchanged until something is saved.';

  @override
  String settingsZonesBasisNotePct(int hrmax) {
    return 'Max HR $hrmax entered by you. Only bpm are stored; the percentages are computed from them.';
  }

  @override
  String get settingsZonesBasisNoteBpm =>
      'Boundaries directly in bpm. Without max HR — nothing is converted.';

  @override
  String settingsZonesBoundaryTitle(int n) {
    return 'Boundary $n';
  }

  @override
  String settingsZonesStepperCaption(int pct, int hrmax) {
    return 'bpm · $pct % of $hrmax';
  }

  @override
  String get settingsZonesStepperCaptionBpm => 'bpm';

  @override
  String get settingsZonesMinusA11y => 'Minus 1 bpm';

  @override
  String get settingsZonesPlusA11y => 'Plus 1 bpm';

  @override
  String settingsZonesLowerLimit(int bpm) {
    return 'At least $bpm bpm — the previous boundary is below it.';
  }

  @override
  String settingsZonesLastSession(String date) {
    return 'Minutes on the right: session from $date';
  }

  @override
  String settingsZonesRowA11y(String state) {
    return '$state. Open.';
  }

  @override
  String get settingsZonesHrMaxTitle => 'Max heart rate';

  @override
  String get settingsZonesHrMaxField => 'Max HR in bpm';

  @override
  String settingsZonesHrMaxRange(int min, int max) {
    return 'Between $min and $max bpm. ATEM does not estimate max HR from age.';
  }

  @override
  String get settingsZonesHrMaxSave => 'Save max HR';

  @override
  String settingsZonesHrMaxInvalid(int min, int max) {
    return 'Save max HR, not possible, a value between $min and $max is needed';
  }

  @override
  String settingsZonesHrMaxA11y(int hrmax, String date) {
    return 'Max HR $hrmax, entered by you on $date. Change.';
  }

  @override
  String get settingsZonesBoundsTitle => 'Set boundaries';

  @override
  String get settingsZonesBoundsRule =>
      'Each boundary is the first heart rate of the upper zone and lies above the previous one.';

  @override
  String settingsZonesBoundsField(int n) {
    return 'Boundary $n in bpm';
  }

  @override
  String settingsZonesBoundsInvalid(int n, int m) {
    return 'Save, not possible, boundary $n must be above boundary $m';
  }

  @override
  String settingsZonesBoundsMissing(int n) {
    return 'Save, not possible, $n boundaries are still missing';
  }

  @override
  String get settingsZonesProposalDone =>
      'Proposal applied. Every boundary stays individually editable.';

  @override
  String settingsZonesBetween(int a, int b) {
    return 'between zone $a and zone $b';
  }

  @override
  String get detailUnitBpm => 'bpm';

  @override
  String get detailUnitKcal => 'kcal';

  @override
  String get detailUnitHm => 'm';

  @override
  String detailBasisExercises(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exercises',
      one: '$n exercise',
    );
    return '$_temp0';
  }

  @override
  String detailBasisEffort(int rpe) {
    return 'effort $rpe of 5';
  }

  @override
  String get detailSpokenHrAvg => 'Average heart rate';

  @override
  String get detailSpokenHrMax => 'Maximum heart rate';

  @override
  String get detailSpokenHrMin => 'Minimum heart rate';

  @override
  String get detailSpokenLoad => 'Load';

  @override
  String detailSpokenTile(
      String label, String value, String unit, String source) {
    return '$label $value $unit, $source';
  }

  @override
  String get detailSourceApp => 'from the app';

  @override
  String get detailHrAvgShort => 'Avg';

  @override
  String get detailHrMaxShort => 'Max';

  @override
  String get detailHrMinShort => 'Min';

  @override
  String get detailBlockHrZones => 'Heart rate & zones';

  @override
  String detailZoneShort(int n) {
    return 'Z$n';
  }

  @override
  String detailZoneSpokenRange(int from, int to) {
    return '$from to $to bpm';
  }

  @override
  String detailZoneA11y(int n, String range, String time, int total) {
    return 'Zone $n, $range, $time of $total minutes';
  }

  @override
  String detailZoneTimeSpoken(int min, int sec) {
    return '$min minutes $sec';
  }

  @override
  String detailZonesGroupA11y(int min, int total, String date) {
    return 'Time in zones, from $min of $total minutes recorded, your zones from $date';
  }

  @override
  String detailHrBasisNoZones(int min, int total) {
    return 'From $min of $total min recorded';
  }

  @override
  String get detailPulseCurveTitle => 'Pulse curve';

  @override
  String get detailHrLoading => 'Heart rate is loading';

  @override
  String get detailErrorHrBody => 'The watch record does not respond.';

  @override
  String detailHrLastRead(String date) {
    return 'Last read $date';
  }

  @override
  String detailWorkMore(int n) {
    return '+ $n more';
  }

  @override
  String get detailWorkNoComparison => 'no comparison';

  @override
  String detailWorkSets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sets',
      one: '$n set',
    );
    return '$_temp0';
  }

  @override
  String detailDeltaWeight(String n) {
    return '$n kg';
  }

  @override
  String detailDeltaReps(String n) {
    return '$n reps';
  }

  @override
  String get detailDeltaSame => 'same';

  @override
  String detailDeltaSpokenMore(String value, String date) {
    return '$value more than on $date';
  }

  @override
  String detailDeltaSpokenLess(String value, String date) {
    return '$value less than on $date';
  }

  @override
  String detailDeltaSpokenSame(String date) {
    return 'same as on $date';
  }

  @override
  String detailSpokenKg(String n) {
    return '$n kilograms';
  }

  @override
  String detailSpokenReps(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n repetitions',
      one: '$n repetition',
    );
    return '$_temp0';
  }

  @override
  String detailExerciseA11y(
      String name, String sets, String best, String delta) {
    return '$name, $sets, best $best$delta. Show sets.';
  }

  @override
  String get detailExerciseHistory => 'Exercise history';

  @override
  String detailSetRow(int n, String detail) {
    return 'Set $n · $detail';
  }

  @override
  String get detailOriginApp => 'Recorded by you';

  @override
  String get detailOriginWatch => 'Imported from the watch';

  @override
  String get detailOriginBoth => 'App + watch · merged';

  @override
  String get detailOriginMetaApp => 'App · all values';

  @override
  String get detailOriginMetaEmpty => 'App · type and day only';

  @override
  String get detailOriginMetaMerged =>
      'App: sets, duration · watch: heart rate, kcal';

  @override
  String detailOriginMetaWatch(String device) {
    return '$device · all values';
  }

  @override
  String get detailOriginA11yBoth =>
      'Origin: app and watch, merged. The app provides sets and duration, the watch provides heart rate and calories.';

  @override
  String get detailAddEffort => 'Add effort';

  @override
  String get detailBackA11y => 'Back to history';

  @override
  String get detailLoadingA11y => 'Session is loading';

  @override
  String detailTimeDayOnly(String day, String date) {
    return '$day $date';
  }

  @override
  String get detailBasisNoLoad => 'no load';

  @override
  String get zoneFiveTitle => 'Zone 5 per week';

  @override
  String get zoneFiveConditionZones =>
      'Once zones are set and one session has heart rate';

  @override
  String get zoneFiveConditionPulse =>
      'Once one session has heart rate from the watch';

  @override
  String zoneFiveWhat(int bpm) {
    return 'The minutes your heart rate was in zone 5 — from $bpm bpm, by your boundaries. Summed per week, from the sessions with heart rate from the watch.';
  }

  @override
  String get zoneFiveExplainNoTarget =>
      'No target: more time in zone 5 is not better, less is not worse. If your boundaries change, every week is recomputed.';

  @override
  String zoneFiveHead(int week, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions with heart rate',
      one: '1 session with heart rate',
    );
    return 'Week $week · $_temp0';
  }

  @override
  String zoneFiveBasis(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      m,
      locale: localeName,
      other: '$m sessions',
      one: '1 session',
    );
    return 'from $n of $_temp0 · heart rate from the watch';
  }

  @override
  String get zoneFiveNoPulseThisWeek => 'No heart rate this week';

  @override
  String zoneFiveStripA11y(String weeks) {
    return 'Zone 5 per week: $weeks';
  }

  @override
  String zoneFiveWeekA11y(int week, int min) {
    return 'Week $week, $min minutes in zone 5';
  }

  @override
  String zoneFiveWeekZeroA11y(int week) {
    return 'Week $week, measured, no time in zone 5';
  }

  @override
  String zoneFiveWeekNoneA11y(int week) {
    return 'Week $week, no heart rate recorded';
  }

  @override
  String get balanceTitleShort => 'Balance';

  @override
  String weeklySetsLine(int week, int n, String avg) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return 'Week $week · $_temp0 · avg $avg over 4 weeks';
  }

  @override
  String weeklySetsLinePending(int week, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '1 session',
    );
    return 'Week $week · $_temp0 · comparison from 2 full weeks';
  }

  @override
  String get trainLastKicker => 'Last time';

  @override
  String trainLastMeta(int n, int e, int min) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago · $e exercises · $min min',
      one: 'yesterday · $e exercises · $min min',
      zero: 'today · $e exercises · $min min',
    );
    return '$_temp0';
  }

  @override
  String get trainStartFree => 'Start free';

  @override
  String get trainFootNewPlan => 'Create plan';

  @override
  String get trainFootLog => 'Log past';

  @override
  String get trainTileExercises => 'Exercises';

  @override
  String trainTileExercisesMeta(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n in the catalog',
      one: '1 in the catalog',
    );
    return '$_temp0';
  }

  @override
  String get trainTilePlan => 'Plan training';

  @override
  String trainTilePlanMeta(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n own plans',
      one: '1 own plan',
    );
    return '$_temp0';
  }

  @override
  String get trainTilePlanMetaNone => 'No plan of your own yet';

  @override
  String get trainErrorKicker => 'Not loaded';

  @override
  String get trainErrorTitle => 'Today’s plan unavailable';

  @override
  String trainErrorMeta(String time) {
    return 'Last checked $time';
  }

  @override
  String get trainLoadingA11y => 'Loading today’s plan';

  @override
  String trainBlockA11yPlanned(String name, int n, int min) {
    return 'Planned today: $name, $n exercises, about $min minutes';
  }

  @override
  String trainBlockA11yPlannedPlain(String name) {
    return 'Planned today: $name';
  }

  @override
  String trainBlockA11yLast(String name, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Last session: $name, $n days ago',
      one: 'Last session: $name, yesterday',
      zero: 'Last session: $name, today',
    );
    return '$_temp0';
  }

  @override
  String trainStartA11yPlanned(String name) {
    return 'Start $name';
  }

  @override
  String get trainStartA11yFree => 'Start a free session';

  @override
  String trainTileExercisesA11y(String title, String meta) {
    return '$title, $meta';
  }

  @override
  String trainLastMetaShort(int n, int min) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago · $min min',
      one: 'yesterday · $min min',
      zero: 'today · $min min',
    );
    return '$_temp0';
  }

  @override
  String trainLastMetaBare(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: 'yesterday',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String pulseCurveRange(int from, int to) {
    return '$from–$to bpm';
  }

  @override
  String pulseCurveReadout(Object time, Object value, Object zone) {
    return '$time · $value · $zone';
  }

  @override
  String pulseCurveReadoutPlain(Object time, Object value) {
    return '$time · $value';
  }

  @override
  String get pulseCurveStart => '0 min';

  @override
  String detailLoadBasisEntered(int rpe) {
    return 'calculated · entered $rpe of 5';
  }

  @override
  String detailLoadBasisMeasured(String ring, int rpe) {
    return 'calculated · ${ring}measured $rpe of 5';
  }

  @override
  String detailLoadBasisFallback(int rpe) {
    return 'calculated · substitute $rpe of 5';
  }

  @override
  String detailLoadA11yEntered(String value, int rpe) {
    return 'Load $value, calculated from entered effort $rpe of 5';
  }

  @override
  String detailLoadA11yMeasured(String value, int rpe) {
    return 'Load $value, calculated from measured effort $rpe of 5, from the watch';
  }

  @override
  String detailLoadA11yFallback(String value, int rpe) {
    return 'Load $value, calculated with substitute value $rpe of 5';
  }

  @override
  String get detailLoadExplainTitle => 'How load is calculated';

  @override
  String get detailLoadExplainFormulaEndurance =>
      'Duration in minutes × effort (1–5) × 4 × sport factor. Beyond two hours each further minute counts less.';

  @override
  String get detailLoadExplainFormulaStrength =>
      'Volume in kilograms × effort (1–5), divided by 50. Without sets, duration counts.';

  @override
  String detailLoadExplainEntered(int rpe) {
    return 'Effort $rpe of 5 — entered by you.';
  }

  @override
  String detailLoadExplainMeasured(int rpe, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes',
      one: '1 minute',
    );
    return 'No effort entered. The measured average from the heart-rate curve takes its place: $rpe of 5, time-weighted from $_temp0 of recording.';
  }

  @override
  String detailLoadExplainEnteredWins(int entered, int measured) {
    return 'Your entry applies: $entered of 5. Measured from the heart-rate curve: $measured of 5.';
  }

  @override
  String detailLoadExplainFallback(int rpe) {
    return 'Neither entered nor measured. Calculated with $rpe of 5.';
  }

  @override
  String get pulseCurveResolutionMinute => 'one value per minute';

  @override
  String get pulseCurveResolutionTen => 'one value per 10 seconds';

  @override
  String pulseCurveBasis(int n, int total, String resolution) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'From $n minutes',
      one: 'From 1 minute',
    );
    return '$_temp0 of $total recorded · $resolution';
  }

  @override
  String pulseCurveA11ySlider(int dur, int min, int max, String resolution) {
    return 'Heart-rate curve, $dur minutes, $min to $max bpm, $resolution. Swipe to step through.';
  }

  @override
  String pulseCurveA11yPoint(String time, int bpm, int zone) {
    return '$time, $bpm bpm, zone $zone';
  }

  @override
  String pulseCurveA11yPointPlain(String time, int bpm) {
    return '$time, $bpm bpm';
  }

  @override
  String pulseCurveGap(Object time) {
    return '$time · no recording';
  }

  @override
  String pulseCurveA11yGap(Object time) {
    return '$time, no recording';
  }

  @override
  String pulseCurveSpan(String span, String resolution) {
    return '$span · $resolution';
  }
}
