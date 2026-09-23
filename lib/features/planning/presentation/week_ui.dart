import 'package:flutter/widgets.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../../cardio/presentation/cardio_ui.dart' show activityLabel;
import '../../history/domain/training_session.dart';
import '../../history/presentation/session_ui.dart' show sessionName;
import '../../plans/domain/plan.dart';
import '../domain/week_plan.dart';
import 'briefing_ui.dart';

/// Worte, Symbole und Töne der Woche (Board 19).
class WeekWords {
  WeekWords(this.context)
      : l10n = AppL10n.of(context),
        briefing = BriefingWords(context);

  final BuildContext context;
  final AppL10n l10n;
  final BriefingWords briefing;

  /// Ein Kreis mit zwei Strichen — „Frei", die Pause.
  static const offGlyph =
      'M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0M10 9v6M14 9v6';

  /// Das Kalender-Symbol im Hybrid-Kopf und am Widget.
  static const calendarGlyph = 'M4 6h16v14H4zM4 10h16M9 3v4M15 3v4';

  static String glyph(WeekKind kind) => switch (kind) {
        WeekKind.strength => BriefingGlyphs.strength,
        WeekKind.cardio => BriefingGlyphs.cardio,
        WeekKind.off => offGlyph,
      };

  /// Die Spur: Kraft Amber, Cardio Violett als Fläche, „Frei" neutral.
  static BriefingTone tone(WeekKind kind) => switch (kind) {
        WeekKind.strength => BriefingTone.strength,
        WeekKind.cardio => BriefingTone.cardio,
        WeekKind.off => BriefingTone.neutral,
      };

  String kind(WeekKind k) => switch (k) {
        WeekKind.strength => l10n.weekKindStrength,
        WeekKind.cardio => l10n.weekKindCardio,
        WeekKind.off => l10n.weekKindOff,
      };

  String daypart(WeekDaypart d) => switch (d) {
        WeekDaypart.morning => l10n.briefingDaypartMorning,
        WeekDaypart.midday => l10n.briefingDaypartMidday,
        WeekDaypart.evening => l10n.briefingDaypartEvening,
      };

  /// Montag bis Sonntag, **immer in dieser Reihenfolge, nie ab heute**
  /// (Board 19, D13).
  static const weekdays = [1, 2, 3, 4, 5, 6, 7];

  String dayLong(int iso) => briefing.dayLong(iso);
  String dayShort(int iso) => briefing.dayShort(iso);

  /// Der aufgelöste Plan — `null`, wenn es ihn nicht mehr gibt.
  Plan? planOf(WeekEntry e, List<Plan> plans) => e.planId == null
      ? null
      : plans.where((p) => p.id == e.planId).firstOrNull;

  /// Der Titel eines Eintrags: Planname, Aktivität, „Krafttraining", „Frei".
  String title(WeekEntry e, List<Plan> plans) => switch (e.kind) {
        WeekKind.strength => planOf(e, plans)?.name ?? l10n.weekStrengthFree,
        WeekKind.cardio => activityLabel(l10n, e.activity),
        WeekKind.off => l10n.weekKindOff,
      };

  /// Die Metazeile: Spur · Umfang · Tageszeit.
  String meta(WeekEntry e, List<Plan> plans) {
    final plan = planOf(e, plans);
    final parts = <String>[
      // „Frei" steht schon im Titel — die Metazeile sagt nur, was es heisst.
      if (e.kind != WeekKind.off) kind(e.kind),
      if (e.kind == WeekKind.strength)
        plan == null
            ? l10n.weekStrengthNoPlan
            : l10n.exerciseCountShort(plan.exerciseCount),
      if (e.kind == WeekKind.cardio && e.durationMin != null)
        l10n.weekCardioMinutes(e.durationMin!),
      if (e.kind == WeekKind.off) l10n.weekOffMeta,
      if (e.daypart != null) daypart(e.daypart!).toLowerCase(),
    ];
    return parts.join(' · ');
  }

  /// Die Notiz eines Eintrags, dessen Plan gelöscht wurde (Entscheidung 12):
  /// neutral, ohne Warnsymbol.
  String? deletedNote(WeekEntry e, List<Plan> plans) {
    if (e.kind != WeekKind.strength || e.planId == null) return null;
    if (planOf(e, plans) != null) return null;
    final name = e.planName;
    return name == null ? null : l10n.weekPlanDeleted(name);
  }

  /// Was an einem Tag trainiert wurde — „Trainiert · Lauf, 35 Min".
  String fact(List<TrainingSession> sessions) => l10n.weekFact([
        for (final s in sessions)
          [
            sessionName(l10n, s),
            if (s.duration?.inMinutes case final m? when m > 0)
              l10n.weekCardioMinutes(m),
          ].join(', '),
      ].join(' · '));
}

/// Die ISO-Kalenderwoche.
int isoWeek(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  final thursday = d.add(Duration(days: 4 - d.weekday));
  final firstThursday = DateTime(thursday.year, 1, 4);
  final monday = firstThursday.subtract(Duration(days: firstThursday.weekday - 1));
  return thursday.difference(monday).inDays ~/ 7 + 1;
}

/// Die Einheiten dieser Kalenderwoche bis heute, je ISO-Wochentag.
Map<int, List<TrainingSession>> sessionsThisWeek(
    List<TrainingSession> all, DateTime today) {
  final monday = mondayOfWeek(today);
  final end = DateTime(today.year, today.month, today.day + 1);
  final out = <int, List<TrainingSession>>{};
  for (final s in all) {
    if (s.date.isBefore(monday) || !s.date.isBefore(end)) continue;
    (out[s.date.weekday] ??= []).add(s);
  }
  return out;
}

DateTime mondayOfWeek(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// Kraft oder Cardio — für den Bisher-Block. Regeneration zählt zu keiner.
WeekKind? laneOf(TrainingSession s) => switch (s) {
      StrengthSession() => WeekKind.strength,
      CardioSession() => WeekKind.cardio,
      _ => null,
    };

/// Die Spurkachel: 36 dp, Symbol in der Farbe der Spur.
class WeekLaneTile extends StatelessWidget {
  const WeekLaneTile({super.key, required this.kind, this.size = 36});

  final WeekKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = WeekWords.tone(kind);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.fill,
        borderRadius: BorderRadius.circular(AtemRadii.iconBox),
      ),
      alignment: Alignment.center,
      child: AtemGlyph(WeekWords.glyph(kind),
          color: tone.glyph, size: size * 0.53),
    );
  }
}
