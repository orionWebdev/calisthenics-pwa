/// Metrisch oder imperial — **nur eine Anzeigefrage**.
///
/// Gespeichert wird ausnahmslos in Kilogramm. Der Bestand führt `bodyWeight`
/// einheitlich metrisch, und zwei Einheiten im selben Feld wären eine Falle
/// für jede spätere Rechnung: Ein Gewicht von 180 wäre je nach Kontoeinstellung
/// ein Schwergewicht oder ein Rechenfehler.
enum UnitSystem {
  metric('metric'),
  imperial('imperial');

  const UnitSystem(this.wire);

  final String wire;

  static UnitSystem fromWire(Object? value) =>
      value == 'imperial' ? UnitSystem.imperial : UnitSystem.metric;

  static const _poundsPerKilogram = 2.20462;

  /// Ein Kilogramm in der gewählten Einheit.
  double fromKilograms(double kg) =>
      this == UnitSystem.imperial ? kg * _poundsPerKilogram : kg;

  /// Zurück nach Kilogramm — die einzige Form, die gespeichert wird.
  double toKilograms(double value) =>
      this == UnitSystem.imperial ? value / _poundsPerKilogram : value;
}

/// Die Sprache der App.
///
/// **Zwei Werte, nicht drei.** „Wie das System" wäre ein dritter Zustand, der
/// sich nur bei einem Wechsel der Systemsprache bemerkbar macht — also fast
/// nie, und dann überraschend. Stattdessen wird die Systemsprache **einmal**
/// beim ersten Start gelesen und als Wahl übernommen; ab da entscheidet die
/// Einstellung.
///
/// Der Unterschied ist klein und in einem Fall wichtig: Wer die App auf
/// Deutsch benutzt und sein Telefon auf Englisch stellt, will nicht, dass die
/// App mitwandert.
enum AppLanguage {
  german('de'),
  english('en');

  const AppLanguage(this.code);

  final String code;

  static AppLanguage? fromCode(Object? value) {
    for (final language in values) {
      if (language.code == value) return language;
    }
    return null;
  }

  /// Was aus einer Systemsprache wird. Alles Unbekannte wird Englisch —
  /// nicht Deutsch: Wer weder Deutsch noch Englisch eingestellt hat, kommt
  /// mit Englisch mit höherer Wahrscheinlichkeit zurecht.
  static AppLanguage forSystem(String languageCode) =>
      languageCode == 'de' ? AppLanguage.german : AppLanguage.english;
}

/// Alles, was in den Einstellungen steht.
///
/// ## Warum nicht alle Felder des Bestands
///
/// Das Profil der Vorgänger-App führt zwanzig Felder, darunter `bodyHeight`,
/// `trainingStyle`, `aiTranslation`, `defaultProgressPeriod` und zwei
/// Integrationen. Keines davon hat in dieser App einen Abnehmer. Sie
/// anzuzeigen hiesse, Schalter zu bauen, die nichts schalten.
///
/// Sie werden auch nicht gelöscht: Geschrieben wird mit `merge`, die übrigen
/// Felder bleiben unangetastet. Die PWA liest sie weiter.
///
/// **`theme` fehlt mit Absicht.** Für ATEM existiert keine helle Palette; jede
/// Farbentscheidung seit Modul 1 setzt einen schwarzen Grund voraus. Ein
/// Schalter, der nichts tut oder etwas Halbfertiges zeigt, ist schlimmer als
/// keiner. Die Tatsache steht als Zeile unter „Über die App".
class UserSettings {
  const UserSettings({
    this.bodyWeightKg,
    this.unitSystem = UnitSystem.metric,
    this.language,
    this.restSeconds = defaultRestSeconds,
    this.hapticsEnabled = true,
  });

  /// Wie die Vorgänger-App: 60 Sekunden.
  static const defaultRestSeconds = 60;

  static const minRestSeconds = 15;
  static const maxRestSeconds = 300;

  /// Plausible Grenzen, keine medizinischen. Sie fangen den Vertipper ab,
  /// bei dem aus 78 die 780 wird — und der jede Rechnung über Jahre verzerrte.
  static const minBodyWeightKg = 30.0;
  static const maxBodyWeightKg = 300.0;

  /// Immer in Kilogramm. `null`, solange nichts hinterlegt ist.
  final double? bodyWeightKg;

  final UnitSystem unitSystem;

  /// `null` heisst: **noch nie gewählt**. Dann gilt einmalig die Systemsprache,
  /// und die Wahl wird dabei festgeschrieben.
  final AppLanguage? language;

  final int restSeconds;
  final bool hapticsEnabled;

  UserSettings copyWith({
    double? bodyWeightKg,
    UnitSystem? unitSystem,
    AppLanguage? language,
    int? restSeconds,
    bool? hapticsEnabled,
  }) =>
      UserSettings(
        bodyWeightKg: bodyWeightKg ?? this.bodyWeightKg,
        unitSystem: unitSystem ?? this.unitSystem,
        language: language ?? this.language,
        restSeconds: restSeconds ?? this.restSeconds,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      );

  static bool isPlausibleWeight(double kg) =>
      kg >= minBodyWeightKg && kg <= maxBodyWeightKg;
}
