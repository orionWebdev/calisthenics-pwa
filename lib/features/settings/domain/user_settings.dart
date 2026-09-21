import '../../pulse/domain/heart_rate_zones.dart';

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

/// Wie die Anstrengung eines Satzes **abgefragt und angezeigt** wird.
///
/// **Nur eine Anzeigefrage, wie [UnitSystem].** Gespeichert wird ausnahmslos
/// RPE 1–10 (`LoggedSet.rpe`); RIR ist dieselbe Zahl von der anderen Seite
/// gezählt. Zwei Skalen im selben Feld wären eine Falle für jede spätere
/// Rechnung: Eine 2 wäre je nach Kontoeinstellung ein leichter Satz oder einer
/// bis fast ans Ende.
///
/// RIR heisst „reps in reserve" — wie viele Wiederholungen nach dem Satz noch
/// drin gewesen wären. Viele schätzen das leichter als eine Anstrengungszahl,
/// weil es eine abzählbare Sache ist und kein Gefühl.
enum EffortScale {
  /// „RPE 8" — je höher, desto schwerer.
  rpe('rpe'),

  /// „2 RIR" — je niedriger, desto schwerer.
  rir('rir');

  const EffortScale(this.wire);

  final String wire;

  static EffortScale fromWire(Object? value) =>
      value == 'rir' ? EffortScale.rir : EffortScale.rpe;

  /// Die Zahl, die in dieser Skala zu einem RPE-Wert angezeigt wird.
  ///
  /// RPE 10 ist 0 RIR („nichts mehr drin"), RPE 8 ist 2 RIR. Die Umrechnung
  /// ist die übliche Lesart der Skala im Krafttraining und verliert nichts:
  /// Jeder RPE-Wert hat genau einen RIR-Wert und umgekehrt.
  int number(int rpe) => this == EffortScale.rir ? 10 - rpe : rpe;
}

/// Die Herzfrequenz-Einstellungen: HFmax und die vier Zonengrenzen.
///
/// **Beides mit Datum.** „Festgelegt am 12. Sep" steht in den Einstellungen
/// und über jeder Zonenverteilung im Einheitendetail („deine Zonen vom 12.
/// Sep"): Wer seine Grenzen ändert, ändert damit jede Verteilung, auch die
/// vergangener Einheiten — das Datum sagt, welche Fassung gerade gilt.
///
/// **HFmax wird nie geschätzt.** „220 minus Alter" wäre eine erfundene
/// Angabe mit ±20 bpm Streuung, und auf ihr stünden fünf Zonen und jede
/// Verteilung (Board 16, Entscheidung 13). Es steht da, was jemand
/// eingetragen hat, oder nichts.
class HeartRateSettings {
  const HeartRateSettings({
    this.hrMax,
    this.hrMaxSetAt,
    this.zones,
    this.zonesSetAt,
  });

  final int? hrMax;
  final DateTime? hrMaxSetAt;
  final HeartRateZones? zones;
  final DateTime? zonesSetAt;

  bool get hasZones => zones != null;

  HeartRateSettings copyWith({
    int? hrMax,
    DateTime? hrMaxSetAt,
    HeartRateZones? zones,
    DateTime? zonesSetAt,
  }) =>
      HeartRateSettings(
        hrMax: hrMax ?? this.hrMax,
        hrMaxSetAt: hrMaxSetAt ?? this.hrMaxSetAt,
        zones: zones ?? this.zones,
        zonesSetAt: zonesSetAt ?? this.zonesSetAt,
      );
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
    this.effortScale = EffortScale.rpe,
    this.heartRate = const HeartRateSettings(),
  });

  /// Wie die Vorgänger-App: 60 Sekunden.
  static const defaultRestSeconds = 60;

  static const minRestSeconds = 15;
  static const maxRestSeconds = 300;

  /// Plausible Grenzen, keine medizinischen. Sie fangen den Vertipper ab,
  /// bei dem aus 78 die 780 wird — und der jede Rechnung über Jahre verzerrte.
  static const minBodyWeightKg = 30.0;

  /// 250, nicht 300 — so steht es im Board („30–250 kg"). Die Grenze fängt
  /// den Vertipper, bei dem aus 78 die 780 wird, und muss dafür nicht bis an
  /// den Rand des Menschenmöglichen reichen.
  static const maxBodyWeightKg = 250.0;

  /// Immer in Kilogramm. `null`, solange nichts hinterlegt ist.
  final double? bodyWeightKg;

  final UnitSystem unitSystem;

  /// `null` heisst: **noch nie gewählt**. Dann gilt einmalig die Systemsprache,
  /// und die Wahl wird dabei festgeschrieben.
  final AppLanguage? language;

  final int restSeconds;
  final bool hapticsEnabled;

  /// In welcher Skala die Anstrengung je Satz erscheint. Ändert nur die
  /// Anzeige, nie den gespeicherten Wert.
  final EffortScale effortScale;

  /// HFmax und Zonengrenzen — beides kann fehlen.
  final HeartRateSettings heartRate;

  UserSettings copyWith({
    double? bodyWeightKg,
    UnitSystem? unitSystem,
    AppLanguage? language,
    int? restSeconds,
    bool? hapticsEnabled,
    EffortScale? effortScale,
    HeartRateSettings? heartRate,
  }) =>
      UserSettings(
        bodyWeightKg: bodyWeightKg ?? this.bodyWeightKg,
        unitSystem: unitSystem ?? this.unitSystem,
        language: language ?? this.language,
        restSeconds: restSeconds ?? this.restSeconds,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        effortScale: effortScale ?? this.effortScale,
        heartRate: heartRate ?? this.heartRate,
      );

  static bool isPlausibleWeight(double kg) =>
      kg >= minBodyWeightKg && kg <= maxBodyWeightKg;
}
