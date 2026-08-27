import '../domain/dashboard_data.dart';
import '../domain/dashboard_repository.dart';

/// NUR FÜR DESIGN-PREVIEW.
///
/// Liefert exakt die Werte aus „ATEM Dashboard.dc.html", damit der Screen ohne
/// Backend betrachtet werden kann. Beim Anschluss an Firestore ersatzlos durch
/// `FirestoreDashboardRepository` ersetzen — diese Klasse gehört nicht in einen
/// Release-Build.
class PreviewDashboardRepository implements DashboardRepository {
  /// Kurven aus dem Design, aus den SVG-y-Koordinaten zurückgerechnet
  /// (y = 22 → 100, y = 120 → 0).
  static const _load = [46.0, 63.0, 33.0, 76.0, 92.0, 57.0, 69.0];
  static const _strain = [26.0, 33.0, 51.0, 39.0, 61.0, 29.0, 37.0];
  static const _recovery = [66.0, 55.0, 71.0, 61.0, 80.0, 73.0, 63.0];

  @override
  Stream<DashboardData> watchDashboard() async* {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    yield DashboardData(
      user: const UserSummary(displayName: 'Alex', unreadNotifications: 2),
      readiness: const ReadinessSnapshot(
        score: 89,
        hrvMs: 82,
        restingHeartRate: 51,
        sleepDuration: Duration(hours: 8, minutes: 24),
        isLive: true,
      ),
      performance: WeeklyPerformance(
        days: [
          for (var i = 0; i < 7; i++)
            DailyMetrics(
              date: monday.add(Duration(days: i)),
              load: _load[i],
              strain: _strain[i],
              recovery: _recovery[i],
            ),
        ],
        todayIndex: now.weekday - 1,
      ),
      session: const TodaySession(
        id: 'preview-day-4',
        title: 'ATEM Hybrid – Day 4: Upper Body & EMOM Finish',
        duration: Duration(minutes: 48),
        intensityLabel: 'High Intensity',
        blockCount: 4,
        isHighIntensity: true,
      ),
      workoutLog: const WorkoutLogSummary(
        planName: 'Upper Body Power',
        totalSets: 24,
      ),
      nutrition: const NutritionSummary(
        proteinGrams: 165,
        proteinTargetGrams: 190,
      ),
      recovery: const RecoverySummary(liveHrvMs: 82, breathworkMinutes: 3),
      periodization: const PeriodizationSummary(
        currentWeek: 6,
        totalWeeks: 12,
        phaseName: 'Hypertrophie',
      ),
    );
  }
}
