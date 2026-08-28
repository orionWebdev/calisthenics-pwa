import 'package:meta/meta.dart';

import '../../history/domain/readiness.dart';
import 'readiness_level.dart';

@immutable
class UserSummary {
  const UserSummary({
    required this.displayName,
    required this.unreadNotifications,
  });

  final String displayName;
  final int unreadNotifications;

  /// Initial für den Avatar.
  String get initial =>
      displayName.trim().isEmpty ? '?' : displayName.trim()[0].toUpperCase();
}

/// Readiness-Snapshot. `score` entspricht dem ACWR-basierten Readiness-Score
/// (0–100) aus der bestehenden Berechnung.
@immutable
class ReadinessSnapshot {
  const ReadinessSnapshot({
    required this.score,
    this.hrvMs,
    this.restingHeartRate,
    this.sleepDuration,
    this.isLive = false,
    this.zone,
  });

  final double score;

  /// Die Zone aus der ACWR-Rechnung, `null` bei Quellen ohne Historie.
  ///
  /// Sie sagt mehr als [level]: Derselbe Punktwert kann Untertraining oder
  /// Übertraining bedeuten, und die Empfehlung ist dann die jeweils
  /// gegenteilige. Nur der ACWR kennt die Richtung.
  final ReadinessZone? zone;

  /// Herzfrequenzvariabilität. `null`, solange keine Wearable-Quelle verbunden ist.
  final int? hrvMs;

  /// Ruhepuls in bpm. `null` ohne Wearable-Quelle.
  final int? restingHeartRate;

  /// Schlafdauer. `null` ohne Wearable-Quelle.
  final Duration? sleepDuration;

  /// True, wenn die Werte aus einer aktiven Live-Quelle stammen.
  final bool isLive;

  ReadinessLevel get level => ReadinessLevel.fromScore(score);

  String get sleepLabel {
    final d = sleepDuration;
    if (d == null) return '–';
    return '${d.inHours}h ${(d.inMinutes % 60).toString().padLeft(2, '0')}m';
  }
}

/// Ein Tag der Wochenkurve. Alle Werte auf 0–100 normalisiert.
@immutable
class DailyMetrics {
  const DailyMetrics({
    required this.date,
    required this.load,
    required this.strain,
    required this.recovery,
  });

  final DateTime date;
  final double load;
  final double strain;
  final double recovery;
}

/// 7-Tage-Performance. Erwartet genau 7 Einträge, Montag → Sonntag.
@immutable
class WeeklyPerformance {
  const WeeklyPerformance({required this.days, required this.todayIndex});

  final List<DailyMetrics> days;

  /// Index des heutigen Tages in [days], oder -1.
  final int todayIndex;

  DailyMetrics? get today =>
      todayIndex >= 0 && todayIndex < days.length ? days[todayIndex] : null;
}

@immutable
class TodaySession {
  const TodaySession({
    required this.id,
    required this.title,
    required this.duration,
    required this.intensityLabel,
    required this.blockCount,
    this.planId,
    this.isHighIntensity = false,
  });

  /// Die Kennung des **Termins**, nicht des Plans.
  final String id;

  /// Der Plan hinter dem Termin.
  ///
  /// `null` bei einem Schnelleintrag — die Vorgänger-App legt solche Termine
  /// ohne Plan an (`isQuickEntry`). Dann gibt es nichts zu laden, und der
  /// Runner beginnt leer.
  final String? planId;
  final String title;
  final Duration duration;
  final String intensityLabel;
  final int blockCount;
  final bool isHighIntensity;
}

@immutable
class WorkoutLogSummary {
  const WorkoutLogSummary({required this.totalSets, this.planName});

  final int totalSets;

  /// Name des Plans der letzten Einheit, falls einer hinterlegt war.
  ///
  /// **Kein fertiger Satz mehr.** Vorher stand hier eine verdichtete Zeile wie
  /// „Bench 92,5 kg PR · 5×5 Squat" — also Anzeigetext in der Domäne, was
  /// Vertrag 3 verbietet und jede Übersetzung blockiert hätte. Die Formulierung
  /// gehört ins Widget.
  final String? planName;
}




/// Vollständiger Zustand des Dashboards. Wird vom Repository geliefert —
/// der Screen enthält keine eigenen Werte.
@immutable
class DashboardData {
  const DashboardData({
    required this.user,
    required this.readiness,
    required this.performance,
    required this.session,
    required this.workoutLog,
    this.form,
    this.lastSession,
    this.nextSession,
  });

  final UserSummary user;
  final ReadinessSnapshot readiness;
  final WeeklyPerformance performance;

  /// `null`, wenn für heute nichts geplant ist.
  final TodaySession? session;

  /// Sätze der letzten Einheit. `null`, wenn keine welche trägt.
  final WorkoutLogSummary? workoutLog;

  /// Formwert und Richtung.
  final FormSummary? form;

  /// Die letzte Einheit, mit dem Vergleich zu ihrem Bezug.
  final LastSessionSummary? lastSession;

  /// Der nächste Termin nach heute.
  final NextSession? nextSession;
}

/// Der Formwert für die Kachel.
@immutable
class FormSummary {
  const FormSummary({
    required this.score,
    required this.rising,
    required this.changed,
    required this.zoneDays,
  });

  final int score;
  final bool rising;
  final bool changed;

  /// Tage seit der letzten Einheit — die Zahl, aus der die Zone folgt.
  final int? zoneDays;
}

/// Die letzte Einheit mit ihrem Vergleich.
@immutable
class LastSessionSummary {
  const LastSessionSummary({
    required this.id,
    required this.name,
    required this.daysAgo,
    required this.load,
    this.loadBefore,
  });

  final String id;
  final String name;
  final int daysAgo;
  final double load;

  /// Die Last der Bezugseinheit. `null`, wenn es keine gibt.
  final double? loadBefore;
}

/// Der nächste geplante Termin.
@immutable
class NextSession {
  const NextSession({
    required this.id,
    required this.title,
    required this.date,
    required this.daysAhead,
    this.planId,
  });

  final String id;
  final String title;
  final DateTime date;

  /// 0 heißt heute, 1 morgen.
  final int daysAhead;

  final String? planId;
}
