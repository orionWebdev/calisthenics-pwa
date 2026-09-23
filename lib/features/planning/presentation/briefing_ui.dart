import 'package:flutter/material.dart' show MaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../../history/presentation/session_ui.dart' show languageTag;
import '../domain/briefing_question.dart';
import '../domain/training_goal.dart';

/// Worte, Symbole und Töne der Trainingsangaben (Board 18).
///
/// Die Symbole sind die Pfade des Boards, unverändert (Sektion B, `I`).
abstract final class BriefingGlyphs {
  static const strength = 'M6.5 6.5v11M17.5 6.5v11M3.5 9.5v5M20.5 9.5v5M6.5 12h11';
  static const cardio = 'M3 12h4l2.5-6 4 12 2.5-6H21';
  static const both =
      'M3 12a5 5 0 1 0 10 0a5 5 0 1 0 -10 0M11 12a5 5 0 1 0 10 0a5 5 0 1 0 -10 0';
  static const pattern =
      'M17 3l3 3-3 3M4 11V9a3 3 0 0 1 3-3h13M7 21l-3-3 3-3M20 13v2a3 3 0 0 1-3 3H4';
  static const count = 'M5 9h14M5 15h14M10 4L8 20M16 4l-2 16';
  static const days = 'M4 6h16v14H4zM4 10h16M9 3v4M15 3v4M9 15l2 2 4-4';
  static const multi = 'M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0M12 7v5l3 2';
  static const place =
      'M12 21s-6-5.5-6-11a6 6 0 0 1 12 0c0 5.5-6 11-6 11zM10 10a2 2 0 1 0 4 0a2 2 0 1 0 -4 0';
  static const aim =
      'M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0M7 12a5 5 0 1 0 10 0a5 5 0 1 0 -10 0M11 12a1 1 0 1 0 2 0a1 1 0 1 0 -2 0';
  static const describes = 'M5 21V4h11l-2 4 2 4H5';
  static const now =
      'M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0M10 8.5l5 3.5-5 3.5z';

  static const home = 'M4 11l8-6 8 6v9h-6v-5h-4v5H4z';
  static const gym = 'M2 12h20M5 8v8M8 6v12M16 6v12M19 8v8';
  static const outdoor = 'M3 19l6-9 4 5 3-3 5 7zM16 6a2 2 0 1 0 4 0a2 2 0 1 0 -4 0';

  static const morning =
      'M4 18h16M7 18a5 5 0 0 1 10 0M12 6v3M5.6 10.6l1.8 1.4M18.4 10.6l-1.8 1.4';
  static const midday =
      'M8 12a4 4 0 1 0 8 0a4 4 0 1 0 -8 0M12 3v2M12 19v2M3 12h2M19 12h2';
  static const evening = 'M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z';

  static String of(BriefingQuestion q) => switch (q) {
        BriefingQuestion.lanes => both,
        BriefingQuestion.pattern => pattern,
        BriefingQuestion.perWeek => count,
        BriefingQuestion.days => days,
        BriefingQuestion.multi => multi,
        BriefingQuestion.places => place,
        BriefingQuestion.goals => aim,
        BriefingQuestion.describes => describes,
      };

  static String ofPlace(Place p) => switch (p) {
        Place.home => home,
        Place.gym => gym,
        Place.outdoor => outdoor,
      };

  static String ofDaypart(Daypart d) => switch (d) {
        Daypart.morning => morning,
        Daypart.midday => midday,
        Daypart.evening => evening,
      };

  static String ofAim(TrainingAim a) => switch (a) {
        TrainingAim.weight => 'M4 4h16v16H4zM8 10a4 4 0 0 1 8 0M12 10l2-2.5',
        TrainingAim.endurance => cardio,
        TrainingAim.mobility => 'M3 12c3-5 6 5 9 0s6 5 9 0',
        TrainingAim.fitness => 'M13 3L5 14h6l-1 7 8-11h-6z',
        TrainingAim.health =>
          'M12 20s-7-4.5-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.5-7 10-7 10z',
        TrainingAim.strength =>
          'M6.5 10v8M17.5 10v8M4 12v4M20 12v4M6.5 14h11M12 3v5M9.5 5.5L12 3l2.5 2.5',
        TrainingAim.muscle => 'M4 19h16M6 15h12M8 11h8M10 7h4',
      };
}

/// Welche Spur eine Antwort betrifft — als Kastenfläche und Symbolfarbe.
///
/// **Nie Status, nie Wertung** (Board 18, Entscheidung 22). Cardio-Violett
/// ist nur Fläche, das Symbol darauf weiss.
enum BriefingTone {
  strength(Color(0x24FFB020), AtemColors.tabStrength),
  cardio(AtemColors.violet, AtemColors.textPrimary),
  both(Color(0x29AB6BF0), AtemColors.tabHybrid),
  neutral(AtemColors.surfaceSolid, AtemColors.textTertiary);

  const BriefingTone(this.fill, this.glyph);

  final Color fill;
  final Color glyph;

  static BriefingTone ofAim(TrainingAim a) => switch (a) {
        TrainingAim.endurance => cardio,
        TrainingAim.strength || TrainingAim.muscle => strength,
        _ => both,
      };
}

/// Die Worte zu Modell und Antworten.
class BriefingWords {
  BriefingWords(this.context)
      : l10n = AppL10n.of(context),
        _tag = languageTag(context);

  final BuildContext context;
  final AppL10n l10n;
  final String _tag;

  String lane(Lane lane) => switch (lane) {
        Lane.strength => l10n.briefingOptStrength,
        Lane.cardio => l10n.briefingOptCardio,
      };

  String? lanes(Set<Lane>? value) => switch (value) {
        null => null,
        final s when s.length == 2 => l10n.briefingOptBoth,
        final s => lane(s.first),
      };

  String pattern(WeekPattern p) => switch (p) {
        WeekPattern.same => l10n.briefingOptPatternSame,
        WeekPattern.alternating => l10n.briefingOptPatternAlt,
        WeekPattern.irregular => l10n.briefingOptPatternIrregular,
      };

  String schedule(DaySchedule s) => switch (s) {
        DaySchedule.fixed => l10n.briefingOptDaysFixed,
        DaySchedule.free => l10n.briefingOptDaysFree,
      };

  String multi(MultiPerDay m) => switch (m) {
        MultiPerDay.no => l10n.briefingOptMultiNo,
        MultiPerDay.some => l10n.briefingOptMultiSome,
        MultiPerDay.most => l10n.briefingOptMultiMost,
      };

  String daypart(Daypart d) => switch (d) {
        Daypart.morning => l10n.briefingDaypartMorning,
        Daypart.midday => l10n.briefingDaypartMidday,
        Daypart.evening => l10n.briefingDaypartEvening,
      };

  String place(Place p) => switch (p) {
        Place.home => l10n.briefingOptPlaceHome,
        Place.gym => l10n.briefingOptPlaceGym,
        Place.outdoor => l10n.briefingOptPlaceOutdoor,
      };

  String aim(TrainingAim a) => switch (a) {
        TrainingAim.weight => l10n.briefingGoalWeight,
        TrainingAim.endurance => l10n.briefingGoalEndurance,
        TrainingAim.mobility => l10n.briefingGoalMobility,
        TrainingAim.fitness => l10n.briefingGoalFitness,
        TrainingAim.health => l10n.briefingGoalHealth,
        TrainingAim.strength => l10n.briefingGoalStrength,
        TrainingAim.muscle => l10n.briefingGoalMuscle,
      };

  /// Ziele **alphabetisch je Sprache** — nicht nach Beliebtheit
  /// (Entscheidung 19, Leitplanke 2).
  List<TrainingAim> aimsInOrder() {
    final list = [...TrainingAim.values];
    list.sort((a, b) => aim(a).compareTo(aim(b)));
    return list;
  }

  String describes(Describes d) => switch (d) {
        Describes.current => l10n.briefingOptDescribesNow,
        Describes.intended => l10n.briefingOptDescribesIntended,
      };

  /// „3×", „8+" — die Zahl, wie sie im Chip und in der Zeile steht.
  String count(int n) => n >= 8 ? l10n.briefingPerWeekMore : '$n×';

  String chipCount(int n) => n >= 8 ? l10n.briefingPerWeekMore : '$n';

  String countA11y(Lane l, int n) => n >= 8
      ? l10n.briefingPerWeekA11yMore(lane(l))
      : n == 1
          ? l10n.briefingPerWeekA11yOne(lane(l), n)
          : l10n.briefingPerWeekA11yOther(lane(l), n);

  /// Die Wochentage in der Reihenfolge des Gebietsschemas (DE: Montag
  /// zuerst), als ISO-Nummern 1–7.
  List<int> weekdaysInOrder() {
    // 0 = Sonntag, wie in MaterialLocalizations.
    final first = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final startIso = first == 0 ? 7 : first;
    return [for (var i = 0; i < 7; i++) (startIso - 1 + i) % 7 + 1];
  }

  /// „Mo" — zweistellig, ohne Punkt. Nie ein Buchstabe: Mo/Mi und Sa/So
  /// wären gleich (Entscheidung 9).
  String dayShort(int iso) =>
      DateFormat.E(_tag).format(_isoDay(iso)).replaceAll('.', '');

  /// „Montag" — für Vorleseprogramme, nie „Mo".
  String dayLong(int iso) => DateFormat.EEEE(_tag).format(_isoDay(iso));

  String date(DateTime d) => DateFormat.MMMd(_tag).format(d);

  /// Die Kurzantwort einer Frage für die gefaltete Zeile; `null` = offen.
  String? summary(BriefingQuestion q, TrainingGoal g, DateTime today) {
    final lanesAsked = [
      for (final l in Lane.values)
        if (g.includes(l)) l,
    ];
    switch (q) {
      case BriefingQuestion.lanes:
        return lanes(g.lanes);
      case BriefingQuestion.pattern:
        final p = g.weekPattern;
        if (p == null) return null;
        final isA = g.isWeekA(today);
        return isA == null
            ? pattern(p)
            : '${pattern(p)} · ${l10n.briefingAnchorSummary(isA ? 'A' : 'B')}';
      case BriefingQuestion.perWeek:
        if (g.perWeek.isEmpty && g.perWeekB.isEmpty) return null;
        final alt = g.weekPattern == WeekPattern.alternating;
        String c(int? n) => n == null ? l10n.briefingOpenLower : count(n);
        final parts = [
          for (final l in lanesAsked)
            alt
                ? l10n.briefingPerWeekPair(
                    lane(l), c(g.perWeek[l]), c(g.perWeekB[l]))
                : l10n.briefingLaneValue(lane(l), c(g.perWeek[l])),
        ];
        var out = parts.join(' · ');
        if (alt) out = '$out ${l10n.briefingWeeksAbSuffix}';
        if (g.weekPattern == WeekPattern.irregular) {
          out = '$out ${l10n.briefingPerWeekAverage}';
        }
        return out;
      case BriefingQuestion.days:
        final s = g.schedule;
        if (s == null) return null;
        if (s == DaySchedule.free || lanesAsked.isEmpty) return schedule(s);
        return [
          for (final l in lanesAsked)
            l10n.briefingLaneValue(
              lane(l),
              g.days[l] == null
                  ? l10n.briefingDaysOpen
                  : [
                      for (final d in weekdaysInOrder())
                        if (g.days[l]!.contains(d)) dayShort(d),
                    ].join(' '),
            ),
        ].join(' · ');
      case BriefingQuestion.multi:
        final m = g.multiPerDay;
        if (m == null) return null;
        return [
          multi(m),
          for (final l in lanesAsked)
            if (g.dayparts[l] case final parts?)
              l10n.briefingLaneValue(
                lane(l),
                [
                  for (final d in Daypart.values)
                    if (parts.contains(d)) daypart(d).toLowerCase(),
                ].join('/'),
              ),
        ].join(' · ');
      case BriefingQuestion.places:
        final p = g.places;
        if (p == null) return null;
        return [
          for (final x in Place.values)
            if (p.contains(x)) place(x),
        ].join(' · ');
      case BriefingQuestion.goals:
        final a = g.goals;
        if (a == null) return null;
        return [
          for (final x in aimsInOrder())
            if (a.contains(x)) aim(x),
        ].join(' · ');
      case BriefingQuestion.describes:
        final d = g.describes;
        if (d == null) return null;
        if (d == Describes.current) return l10n.briefingDescribesNowShort;
        final since = g.answeredAt['describes'];
        return since == null
            ? l10n.briefingDescribesIntendedShort
            : l10n.briefingDescribesSince(
                l10n.briefingDescribesIntendedShort, date(since));
    }
  }

  String title(BriefingQuestion q) => switch (q) {
        BriefingQuestion.lanes => l10n.briefingQModality,
        BriefingQuestion.pattern => l10n.briefingQPattern,
        BriefingQuestion.perWeek => l10n.briefingQPerWeek,
        BriefingQuestion.days => l10n.briefingQDays,
        BriefingQuestion.multi => l10n.briefingQMulti,
        BriefingQuestion.places => l10n.briefingQPlace,
        BriefingQuestion.goals => l10n.briefingQGoals,
        BriefingQuestion.describes => l10n.briefingQDescribes,
      };

  String short(BriefingQuestion q) => switch (q) {
        BriefingQuestion.lanes => l10n.briefingQModalityShort,
        BriefingQuestion.pattern => l10n.briefingQPatternShort,
        BriefingQuestion.perWeek => l10n.briefingQPerWeekShort,
        BriefingQuestion.days => l10n.briefingQDaysShort,
        BriefingQuestion.multi => l10n.briefingQMultiShort,
        BriefingQuestion.places => l10n.briefingQPlaceShort,
        BriefingQuestion.goals => l10n.briefingQGoalsShort,
        BriefingQuestion.describes => l10n.briefingQDescribesShort,
      };

  /// Die eine Hinweiszeile unter der Frage, oder `null`.
  String? hint(BriefingQuestion q, TrainingGoal g) => switch (q) {
        BriefingQuestion.perWeek => g.weekPattern == WeekPattern.irregular
            ? l10n.briefingQPerWeekHintIrregular
            : l10n.briefingQPerWeekHint,
        BriefingQuestion.multi => l10n.briefingQMultiHint,
        BriefingQuestion.places => l10n.briefingQPlaceHint,
        BriefingQuestion.goals => l10n.briefingQGoalsHint,
        BriefingQuestion.describes => l10n.briefingQDescribesHint,
        _ => null,
      };

  /// Die Metazeile der Einstellungszeile: der Inhalt, nicht der Füllstand
  /// (Board 18, A8). `null`, wenn nichts angegeben ist.
  String? settingsSummary(TrainingGoal g, DateTime today) {
    final modality = lanes(g.lanes);
    if (modality != null) {
      final perWeek = [
        for (final l in Lane.values)
          if (g.perWeek[l] case final n?) l10n.briefingLaneValue(lane(l), count(n)),
      ].join(' · ');
      return perWeek.isEmpty
          ? modality
          : l10n.settingsRowBriefingSummary(modality, perWeek);
    }
    for (final q in BriefingQuestion.values) {
      final s = summary(q, g, today);
      if (s != null) return s;
    }
    return null;
  }

  static DateTime _isoDay(int iso) => DateTime(2026, 9, 20 + iso); // 21.9. = Mo
}
