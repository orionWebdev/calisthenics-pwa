import 'package:flutter/widgets.dart' show Color;

// ---------------------------------------------------------------------------
// FARBTOKENS
// ---------------------------------------------------------------------------

abstract final class AtemColors {
  // --- Base -----------------------------------------------------------------
  /// Ultra Pitch Black, leicht blaustichig — Scaffold-Hintergrund.
  static const base = Color(0xFF050507);

  /// Card / Surface. Als Glas mit [cardTintAlpha] verwenden.
  static const card = Color(0xFF14141D);

  /// Deckkraft der Glasfläche. Höher = weniger durchscheinend.
  static const cardTintAlpha = 0.80;

  /// Vorberechnete Glasfläche — für ThemeData, wo kein Kontext zur Verfügung
  /// steht, um sie abzuleiten.
  static const cardTinted = Color(0xCC14141D);

  /// Deckende Flächen: Micro-Stat-Boxen, Badges, Input-Felder.
  static const surfaceSolid = Color(0xFF0B0B0E);

  /// Angehobene Fläche (Sheets, Menüs, Dialoge).
  static const surfaceRaised = Color(0xFF1A1A26);

  /// 1px Hairline-Border auf Cards.
  static const border = Color(0xFF232334);

  /// Gauge- / Progress-Track.
  static const track = Color(0xFF16161F);

  /// Chart-Gridlines.
  static const gridLine = Color(0xFF15151E);

  // --- Neon Accents ---------------------------------------------------------
  /// Primär — Electric Cyan. Load, Herzfrequenz, aktive Navigation.
  static const cyan = Color(0xFF00F2FE);

  /// Neon Magenta — Markenfarbe. Strain, Intensität, CTAs, Alerts.
  static const magenta = Color(0xFFF02277);

  /// Deep Magenta Rose — dunkler Stop für CTA-Verläufe.
  static const magentaDeep = Color(0xFFC01963);

  /// Neon Green. Recovery, HRV, Live-Status, Erfolg.
  static const green = Color(0xFF00FF87);

  /// Deep Cyber Violet — Brückenfarbe der Verläufe, Schlaf & Periodisierung.
  static const violet = Color(0xFF7A2BDB);
  static const violetLight = Color(0xFF9D4EDD);

  /// Warnstufe (zwischen green und magenta).
  static const amber = Color(0xFFFFB020);

  // --- Tab-Töne -------------------------------------------------------------
  //
  // **Jeder Bereich hat einen Ton.** Er färbt sein Symbol in der Leiste und
  // legt einen sehr schwachen Verlauf über den Bildschirmgrund — genug, damit
  // man beim Umschalten merkt, dass man woanders ist, zu wenig, um mit den
  // Datenfarben zu konkurrieren.
  //
  // Sie stehen hier und nicht verstreut in den Bildschirmen: „Nur die Tokens
  // aus atem_theme.dart" heisst, dass neue Bedeutungen hier ankommen müssen.
  //
  // Drei der vier sind bestehende Töne. Nur `tabCardio` ist neu — im Vorrat
  // gab es kein Blau ausser Cyan, und Cyan ist die Datenfarbe der ganzen App.

  /// Hybrid — Lila. **Nicht `violet` und nicht `violetLight`:** Das tiefe
  /// Violet trägt 2,8:1 gegen den Grund, `violetLight` 4,43:1 — beide reissen
  /// AA für die Beschriftung daneben. Dieser Ton hält 5,9:1 auf `base` und
  /// 5,3:1 auf `card`. Die Regel „Violet nur Fläche, nie Text" bleibt damit
  /// unangetastet: Sie gilt weiter für `violet`, das hier nicht steht.
  static const tabHybrid = Color(0xFFAB6BF0);

  /// Kraft — Orange. Der vorhandene Warnton; er hat hier keine Warnbedeutung,
  /// sondern ist schlicht der einzige Orangeton im Vorrat.
  static const tabStrength = amber;

  /// Cardio — Blau. Dunkler als Cyan, hell genug für 6,4:1 gegen `base`.
  static const tabCardio = Color(0xFF4C8DFF);

  /// Regeneration — Grün. Derselbe Ton, den Regeneration überall trägt.
  static const tabRecovery = green;

  // --- Text -----------------------------------------------------------------
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF94A3B8);

  /// Pills, Tag-Labels — heller als secondary, ruhiger als primary.
  static const textTertiary = Color(0xFFCDD3EA);

  static const textDisabled = Color(0xFF4A4F63);

  /// Auf Neon-Flächen (Cyan/Green) liegender Text — dunkel für Kontrast.
  static const onNeon = Color(0xFF050507);
}
