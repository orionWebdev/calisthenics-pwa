import '../../../core/domain/health_gateway.dart';
import 'weight_entry.dart';
import 'weight_series.dart';

/// Was ein Abgleich mit Health Connect an der Reihe ändern würde.
///
/// Absichtlich ein **Plan** und keine Ausführung: Er lässt sich ohne Gerät
/// prüfen, ohne Netz rechnen und vor dem Schreiben ansehen.
class WeightSyncPlan {
  const WeightSyncPlan({required this.toSave, required this.toPublish});

  static const empty = WeightSyncPlan(toSave: [], toPublish: []);

  /// Einträge, die aus der Quelle übernommen werden — neu oder geändert.
  final List<WeightEntry> toSave;

  /// Eigene Einträge, die die Quelle noch nicht kennt.
  final List<WeightEntry> toPublish;

  bool get isEmpty => toSave.isEmpty && toPublish.isEmpty;
}

/// Der Abgleich zwischen der Reihe und einer Gesundheitsquelle.
///
/// ## Die vier Regeln
///
/// 1. **Was ATEM selbst geschrieben hat, kommt nicht als fremde Messung
///    zurück.** Sonst liefe der Abgleich im Kreis: schreiben, lesen, als
///    Messung übernehmen, wieder schreiben. Erkannt am Paketnamen.
/// 2. **Ein Tag, ein Wert** — wie überall in dieser Reihe. Misst jemand
///    morgens und abends, gilt die spätere Messung. Zwei Punkte am selben Tag
///    wären Tagesrauschen mit dem Aussehen eines Verlaufs.
/// 3. **Eine Messung überschreibt keine Eingabe.** Wer einen Wert getippt hat,
///    hat eine Aussage gemacht; ein Import, der sie still ersetzt, nimmt sie
///    zurück, ohne zu fragen. Gemessene Einträge dagegen gehören der Quelle
///    und werden von ihr aktualisiert.
/// 4. **Nur getippte Werte gehen zurück.** Eine Messung dorthin
///    zurückzuschreiben, woher sie kam, verdoppelt sie.
abstract final class WeightSync {
  /// Wie weit zurück gelesen wird.
  ///
  /// Dreissig Tage, und das ist keine Vorsicht, sondern Googles Grenze: Ohne
  /// die zusätzliche Berechtigung `READ_HEALTH_DATA_HISTORY` liefert Health
  /// Connect nichts, was länger als dreissig Tage vor der Freigabe liegt. Die
  /// Berechtigung ist nicht deklariert — jede einzelne braucht bei der
  /// Einreichung eine eigene Begründung, und für den laufenden Abgleich reicht
  /// dieses Fenster. Ein einmaliger Import der ganzen Vergangenheit wäre ein
  /// eigenes Vorhaben mit eigener Begründung.
  static const windowDays = 30;

  static DateTime windowStart(DateTime reference) {
    final day = WeightEntry.dayOf(reference);
    return DateTime(day.year, day.month, day.day - windowDays + 1);
  }

  /// Rechnet den Plan aus.
  ///
  /// [measured] enthält **alle** Datensätze des Fensters, auch die eigenen —
  /// sie werden gebraucht, um zu wissen, welche Einträge bereits
  /// zurückgeschrieben sind.
  static WeightSyncPlan plan({
    required WeightSeries series,
    required List<MeasuredWeight> measured,
    required String ownSourceId,
    required DateTime reference,
  }) {
    final from = windowStart(reference);
    final to = WeightEntry.dayOf(reference);

    final foreignByDay = <String, MeasuredWeight>{};
    final ownByDay = <String, MeasuredWeight>{};

    for (final record in measured) {
      final day = WeightEntry.dayOf(record.measuredAt);
      if (day.isBefore(from) || day.isAfter(to)) continue;
      final key = WeightEntry.idFor(day);
      final target = record.sourceId == ownSourceId ? ownByDay : foreignByDay;
      final existing = target[key];
      // Regel 2: Bei mehreren Messungen an einem Tag gilt die spätere.
      if (existing == null || existing.measuredAt.isBefore(record.measuredAt)) {
        target[key] = record;
      }
    }

    final toSave = <WeightEntry>[];
    for (final entry in foreignByDay.entries) {
      final record = entry.value;
      final day = WeightEntry.dayOf(record.measuredAt);
      final existing = series.entryOn(day);

      // Regel 3: Eine Eingabe bleibt stehen.
      if (existing != null && !existing.source.isMeasured) continue;

      final unchanged = existing != null &&
          existing.externalId == record.id &&
          (existing.kg - record.kg).abs() < 0.001;
      if (unchanged) continue;

      toSave.add(WeightEntry(
        date: day,
        kg: record.kg,
        source: WeightSource.healthConnect,
        externalId: record.id,
      ));
    }

    final toPublish = <WeightEntry>[];
    for (final entry in series.entries) {
      // Regel 4: Nur was jemand getippt hat.
      if (entry.source.isMeasured) continue;
      if (entry.date.isBefore(from) || entry.date.isAfter(to)) continue;

      final own = ownByDay[entry.documentId];
      final alreadyThere =
          own != null && (own.kg - entry.kg).abs() < 0.001;
      if (alreadyThere) continue;

      toPublish.add(entry);
    }

    // Ein Tag, den der Abgleich gerade aus der Quelle übernimmt, wird nicht
    // im selben Lauf dorthin zurückgeschrieben — sonst stünde eine Messung
    // gegen die Eingabe, die sie gerade ersetzt hat.
    final incoming = {for (final e in toSave) e.documentId};
    toPublish.removeWhere((e) => incoming.contains(e.documentId));

    toSave.sort((a, b) => a.date.compareTo(b.date));
    toPublish.sort((a, b) => a.date.compareTo(b.date));
    return WeightSyncPlan(toSave: toSave, toPublish: toPublish);
  }
}
