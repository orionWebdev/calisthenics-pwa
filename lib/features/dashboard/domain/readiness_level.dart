/// Bereitschaftsstufe, abgeleitet aus dem Readiness-Score.
///
/// Reine Daten: keine Farbe, kein Text. Beides ist Darstellung und lebt in
/// `presentation/readiness_level_ui.dart` — siehe
/// `docs/contracts/03-architecture.md`, Domänenreinheit.
///
/// Die Schwellen stammen aus der Design-Referenz (ATEM Dashboard, renderVals).
enum ReadinessLevel {
  peak,
  solid,
  moderate,
  focusRecovery;

  static ReadinessLevel fromScore(double score) {
    final s = score.round();
    if (s >= 85) return ReadinessLevel.peak;
    if (s >= 70) return ReadinessLevel.solid;
    if (s >= 55) return ReadinessLevel.moderate;
    return ReadinessLevel.focusRecovery;
  }
}
