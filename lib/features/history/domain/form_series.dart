import 'readiness.dart';
import 'training_form.dart';
import 'training_load.dart';
import 'training_session.dart';

/// Ein Tag der Formkurve.
class FormPoint {
  const FormPoint({
    required this.date,
    required this.value,
    required this.hasTraining,
  });

  final DateTime date;

  /// 0 bis 100.
  final double value;

  /// Wurde an diesem Tag trainiert?
  ///
  /// Entscheidet die Darstellung: **Die Lücke wird nicht interpoliert.** Die
  /// Form wird täglich gerechnet, auch ohne Training — der Verlauf nach der
  /// letzten Einheit ist echt, aber trainingsfrei. Die Linie wechselt dort auf
  /// gestrichelt und bekommt eine Fläche; zwei Träger, nicht nur Farbe.
  final bool hasTraining;
}

/// Einheiten je Woche, für den Streifen unter der Achse.
class WeekCount {
  const WeekCount({required this.weekStart, required this.count});

  final DateTime weekStart;
  final int count;
}

/// Die Formkurve über die Zeit.
class FormSeries {
  const FormSeries({
    required this.points,
    required this.weeks,
    required this.maxPerWeek,
  });

  static const empty = FormSeries(points: [], weeks: [], maxPerWeek: 0);

  final List<FormPoint> points;

  /// Ein zweiter Datensatz **ohne zweite Achse**: Man soll sehen, dass die
  /// Kurve steigt, weil die Striche dichter werden. Ursache und Wirkung in
  /// einem Bild.
  final List<WeekCount> weeks;

  final int maxPerWeek;

  bool get isEmpty => points.isEmpty;

  /// Rechnet die Kurve für die letzten [days] Tage.
  ///
  /// Ein Punkt je Tag. Bei einem halben Jahr sind das rund 180 Auswertungen
  /// über je 120 Tage Fenster — für eine Ansicht, die einmal beim Öffnen
  /// entsteht, ist das vertretbar. Wird es je zu langsam, ist die Schrittweite
  /// die Stellschraube, nicht die Genauigkeit der einzelnen Rechnung.
  static FormSeries compute(
    List<TrainingSession> sessions,
    DateTime reference, {
    int days = 180,
    LoadContext context = const LoadContext(),
  }) {
    if (sessions.isEmpty) return FormSeries.empty;

    final trainingDays = <String>{
      for (final s in sessions) Readiness.dayKey(s.date),
    };

    final earliest =
        sessions.map((s) => s.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final nominalStart =
        DateTime(reference.year, reference.month, reference.day - (days - 1));
    var cursor = earliest.isAfter(nominalStart)
        ? DateTime(earliest.year, earliest.month, earliest.day)
        : nominalStart;

    final refDay = DateTime(reference.year, reference.month, reference.day);

    final points = <FormPoint>[];
    while (!cursor.isAfter(refDay)) {
      final form = TrainingForm.compute(sessions, cursor, context: context);
      points.add(FormPoint(
        date: cursor,
        value: (form.score ?? 0).toDouble(),
        hasTraining: trainingDays.contains(Readiness.dayKey(cursor)),
      ));
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }

    final weeks = _weeks(points, trainingDays);
    return FormSeries(
      points: points,
      weeks: weeks,
      maxPerWeek: weeks.fold<int>(0, (a, w) => w.count > a ? w.count : a),
    );
  }

  static List<WeekCount> _weeks(
    List<FormPoint> points,
    Set<String> trainingDays,
  ) {
    if (points.isEmpty) return const [];
    final weeks = <WeekCount>[];

    // Wochenbeginn ist Montag — derselbe Wochenanfang wie im Dashboard.
    var start = points.first.date;
    start = DateTime(start.year, start.month, start.day - (start.weekday - 1));

    while (!start.isAfter(points.last.date)) {
      var count = 0;
      for (var i = 0; i < 7; i++) {
        final day = DateTime(start.year, start.month, start.day + i);
        if (trainingDays.contains(Readiness.dayKey(day))) count++;
      }
      weeks.add(WeekCount(weekStart: start, count: count));
      start = DateTime(start.year, start.month, start.day + 7);
    }
    return weeks;
  }
}
