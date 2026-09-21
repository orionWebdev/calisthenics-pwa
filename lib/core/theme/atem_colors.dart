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

  // ---- Herzfrequenzzonen (Board 16, auf Wunsch vom 21.09.2026) -----------
  //
  // **Eine Abweichung vom Board, ausdrücklich.** Board 16 (Entscheidung 7)
  // verwirft eine Farbskala für die Zonen: Rot hiesse „zu viel" oder „endlich
  // hart", je nach Tagesform, und das weiss die App nicht. Der Nutzer hat sich
  // dennoch dafür entschieden — die Zonen sind auf einen Blick
  // auseinanderzuhalten, und Zone 5 bekommt ihre eigene Auswertung.
  //
  // Was davon bleibt: Die Farbe trägt **nichts allein**. Jede Zone hat weiter
  // ihren Namen, ihren bpm-Bereich und ihre Minuten, und kein Text nennt eine
  // Zone „hoch", „gut" oder „zu viel". Die Farben unterscheiden, sie
  // bewerten nicht.

  /// Zone 1 (und darunter): Cyan.
  static const zone1 = cyan;

  /// Zone 2: Grün.
  static const zone2 = green;

  /// Zone 3: Gelb. Heller und gelber als [amber], damit Zone 3 und 4
  /// nebeneinander nicht ineinander laufen.
  static const zone3 = Color(0xFFFFE14D);

  /// Zone 4: Orange. Dunkler und röter als [amber] — der Vorrat hatte
  /// keinen Orangeton, der sich von Gelb abhebt.
  static const zone4 = Color(0xFFFF8A1F);

  /// Zone 5: Rot. Orangeroter als [magenta] (Markenfarbe, Strain, Alerts):
  /// Magenta bleibt Eingriff und Störung, dieses Rot ist nur Zone 5.
  static const zone5 = Color(0xFFFF3D2E);

  /// Die Farbe einer Zone, 1 bis 5. Zone 0 gibt es nicht: Zone 1 ist nach
  /// unten offen.
  static Color zone(int number) => switch (number) {
        <= 1 => zone1,
        2 => zone2,
        3 => zone3,
        4 => zone4,
        _ => zone5,
      };

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
