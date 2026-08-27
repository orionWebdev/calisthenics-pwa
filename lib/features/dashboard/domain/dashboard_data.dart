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

@immutable
class NutritionSummary {
  const NutritionSummary({
    required this.proteinGrams,
    required this.proteinTargetGrams,
  });

  final int proteinGrams;
  final int proteinTargetGrams;

  /// 0.0–1.0, für den Mini-Ring.
  double get progress => proteinTargetGrams <= 0
      ? 0
      : (proteinGrams / proteinTargetGrams).clamp(0.0, 1.0);

  int get progressPercent => (progress * 100).round();
}

@immutable
class RecoverySummary {
  const RecoverySummary({this.liveHrvMs, required this.breathworkMinutes});

  final int? liveHrvMs;
  final int breathworkMinutes;
}

@immutable
class PeriodizationSummary {
  const PeriodizationSummary({
    required this.currentWeek,
    required this.totalWeeks,
    required this.phaseName,
  });

  final int currentWeek;
  final int totalWeeks;
  final String phaseName;

  double get progress =>
      totalWeeks <= 0 ? 0 : (currentWeek / totalWeeks).clamp(0.0, 1.0);
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
    required this.nutrition,
    required this.recovery,
    required this.periodization,
  });

  final UserSummary user;
  final ReadinessSnapshot readiness;
  final WeeklyPerformance performance;

  /// `null`, wenn für heute nichts geplant ist.
  final TodaySession? session;

  /// Die folgenden vier sind `null`, solange es **keine Datenquelle** gibt.
  ///
  /// Ernährung, Regenerationsminuten und Periodisierung werden nirgends
  /// erfasst — weder in der PWA noch in dieser App, und Health Connect steht
  /// ausdrücklich nicht in V1. Ein Platzhalterwert wäre eine Erfindung, die auf
  /// dem Bildschirm wie eine Messung aussieht. Die Oberfläche zeigt stattdessen
  /// offen, dass nichts vorliegt.
  final WorkoutLogSummary? workoutLog;
  final NutritionSummary? nutrition;
  final RecoverySummary? recovery;
  final PeriodizationSummary? periodization;
}
