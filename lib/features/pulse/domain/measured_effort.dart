import '../../health_import/domain/health_session.dart';
import '../../history/domain/training_session.dart';
import 'heart_rate_zones.dart';
import 'zone_intensity.dart';

/// **Die gemessene Anstrengung, nachschlagbar je Einheit.**
///
/// Der Puls liegt nicht an der Einheit, sondern am Uhr-Datensatz daneben —
/// Board 15, Entscheidung 1: „Lösen ist verlustfrei", deshalb wird beim
/// Übernehmen nichts kopiert. Wer aus einer Einheit ihre Anstrengung lesen
/// will, muss also über die Verknüpfung gehen.
///
/// Dieses Stück tut das **einmal für alle** und legt das Ergebnis in eine
/// Tabelle. Der Grund ist die Lastrechnung: Sie läuft über jede Einheit des
/// Verlaufs, und eine lineare Suche je Einheit wäre quadratisch.
///
/// Die Zuordnung geht über [TrainingSession.healthSessionId] gegen
/// [HealthSession.externalId] — dieselbe Paarung wie in `watchFiguresProvider`
/// (`import_action.dart` schreibt dort `healthSessionId: session.externalId`).
///
/// Nur **übernommene** Datensätze zählen. Ein abgelehnter gehört in keine
/// Zahl, und ein wartender ist „sichtbar, aber ohne Wirkung auf eine einzige
/// Zahl" — er hat ohnehin noch keine Einheit, mit der er verknüpft wäre.
class MeasuredEfforts {
  const MeasuredEfforts._(this._byExternalId);

  /// Nichts gemessen — jede Abfrage gibt `null`. Der Zustand ohne
  /// festgelegte Zonen, ohne Uhr und in jedem Test, der davon nichts wissen
  /// will.
  const MeasuredEfforts.none() : _byExternalId = const {};

  /// Ohne [zones] gibt es keine Zonen und damit keine Anstrengung: Die
  /// Grenzen sind eine Angabe des Nutzers, keine Annahme der App.
  factory MeasuredEfforts.from({
    required Iterable<HealthSession> records,
    required HeartRateZones? zones,
  }) {
    if (zones == null) return const MeasuredEfforts.none();

    final byId = <String, int>{};
    for (final record in records) {
      if (record.state != HealthSessionState.accepted) continue;
      final pulse = record.pulse;
      if (pulse == null) continue;

      final intensity = ZoneIntensity.of(ZoneDistribution.of(
        secondsByBpm: pulse.secondsByBpm,
        windowSeconds: pulse.windowSeconds,
        zones: zones,
      ));
      if (intensity == null) continue;
      byId[record.externalId] = intensity.effort;
    }
    return MeasuredEfforts._(Map.unmodifiable(byId));
  }

  final Map<String, int> _byExternalId;

  bool get isEmpty => _byExternalId.isEmpty;

  /// Die gemessene Anstrengung dieser Einheit, oder `null`.
  ///
  /// `null` heisst hier durchweg dasselbe: **Die Messung sagt nichts.** Keine
  /// Uhr, keine Zonen, kein Pulsverlauf oder zu wenig davon — für den
  /// Aufrufer ist das ein Fall, nicht vier.
  int? of(TrainingSession session) {
    final linked = session.healthSessionId;
    return linked == null ? null : _byExternalId[linked];
  }
}
