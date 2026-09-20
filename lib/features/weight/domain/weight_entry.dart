/// Woher ein Gewichtswert stammt.
///
/// ## Warum die Herkunft überhaupt gespeichert wird
///
/// Board 14, Abschnitt D: Ein getippter Wert und ein gemessener sind nicht
/// dasselbe. Wer sich morgens auf die Waage stellt, misst; wer abends aus dem
/// Kopf nachträgt, schätzt. Die Kurve unterscheidet beides über die **Form**
/// des Punktes — gefüllt gegen hohl —, nicht über eine zweite Farbe und nicht
/// über ein Abzeichen (Entscheidung 6).
///
/// ## Warum drei Werte und nicht zwei
///
/// [settings] ist kein dritter Sensor, sondern eine **Erklärung**: Der eine
/// Wert, den das Profil bis zum 20.09.2026 führte, hat kein Ursprungsdatum.
/// Er wird als erster Eintrag übernommen und trägt sichtbar, woher er kommt —
/// ehrlicher als ein erfundenes Datum (Board 14, Abschnitt E). Auf der Kurve
/// ist er ein getippter Wert, weil ihn jemand getippt hat.
enum WeightSource {
  /// Selbst eingetragen — im Eingabeblatt.
  manual('manual'),

  /// Aus Health Connect gelesen. Ab 8.2; das Feld steht vorher, damit der
  /// erste gemessene Wert kein Schemawechsel ist.
  healthConnect('healthConnect'),

  /// Aus der Einstellung „Körpergewicht" übernommen (einmalig, je Konto).
  settings('settings');

  const WeightSource(this.wire);

  /// Wie der Wert in Firestore steht.
  final String wire;

  static WeightSource fromWire(Object? value) {
    for (final source in values) {
      if (source.wire == value) return source;
    }
    // Unbekannte Herkunft ist ein getippter Wert, kein Fehler: Ein Wert aus
    // einer späteren Quelle darf nicht verschwinden, nur weil diese Fassung
    // ihren Namen noch nicht kennt.
    return WeightSource.manual;
  }

  /// Ob der Punkt hohl gezeichnet wird (gemessen) statt gefüllt (getippt).
  bool get isMeasured => this == WeightSource.healthConnect;
}

/// Ein Gewichtswert an einem Tag.
///
/// ## Ein Tag trägt genau einen Wert
///
/// Nicht als Regel im Code, sondern als **Form der Daten**: Die Kennung des
/// Dokuments ist das Datum ([documentId]). Ein zweiter Eintrag am selben Tag
/// kann gar kein zweiter Punkt werden, er ersetzt den ersten. Board 14, B2
/// sagt das auch im Blatt an — es informiert, blockiert aber nichts.
///
/// ## Warum tagesgenau und nicht auf die Minute
///
/// Körpergewicht schwankt innerhalb eines Tages um mehr, als es in zwei Wochen
/// wandert (Entscheidung 1). Eine Uhrzeit vorzuhalten hiesse, zwei Messungen
/// desselben Tages als Entwicklung zu zeichnen — das wäre Tagesrauschen mit
/// dem Aussehen eines Verlaufs.
class WeightEntry {
  WeightEntry({
    required DateTime date,
    required this.kg,
    required this.source,
    this.externalId,
  }) : date = dayOf(date);

  /// Tagesgenau, lokale Zeit, immer Mitternacht.
  final DateTime date;

  final double kg;

  final WeightSource source;

  /// Die Kennung des Datensatzes in der Quelle, aus der er kam.
  ///
  /// Nur für gemessene Werte belegt. Ohne sie liesse sich beim zweiten Lesen
  /// aus Health Connect nicht unterscheiden, ob ein Wert neu ist oder derselbe
  /// noch einmal — und jede Synchronisation wäre ein Duplikat.
  final String? externalId;

  /// Der Tag zu einem Zeitpunkt: Mitternacht, lokale Zeit.
  static DateTime dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Die Dokumentkennung: `2026-09-20`.
  ///
  /// Sortierbar als Zeichenkette und **eindeutig je Tag** — genau das ist der
  /// Zweck. Bewusst von Hand gesetzt statt über `intl`: Die Domäne kennt kein
  /// Gebietsschema, und eine Kennung ist keine Anzeige.
  String get documentId => idFor(date);

  static String idFor(DateTime value) {
    final day = dayOf(value);
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }

  WeightEntry copyWith({double? kg, WeightSource? source}) => WeightEntry(
        date: date,
        kg: kg ?? this.kg,
        source: source ?? this.source,
        externalId: externalId,
      );

  @override
  String toString() => 'WeightEntry($documentId, $kg, ${source.wire})';
}
