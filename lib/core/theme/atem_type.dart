import 'package:flutter/material.dart' show TextTheme;
import 'package:flutter/widgets.dart';

import 'atem_colors.dart';

/// Die Typenskala aus Design-Gespräch 01.
///
/// Acht Rollen statt zehn gewachsener Größen, plus eine dekorative Ausnahme.
/// Siehe `docs/design-prompts/01-typenskala.md` und die Spezifikation
/// „ATEM Typo & Interaction Spec" im Claude-Design-Projekt.
///
/// ## Warum [AtemTextRole] und nicht einfach [TextStyle]
///
/// Flutter skaliert bei großer Systemschrift die `fontSize`, **nicht** die
/// `letterSpacing` — die ist in logischen Pixeln angegeben. Eine feste Sperrung
/// von 2,5 px rückt bei 200 % relativ zusammen, und die HUD-Labels verlieren
/// ihren Charakter genau dann, wenn sie am größten sind.
///
/// Deshalb trägt jede Rolle ihre Sperrung als **em-Wert** und rechnet sie in
/// [AtemTextRole.of] gegen die tatsächlich skalierte Größe aus.
@immutable
class AtemTextRole {
  const AtemTextRole(this.base, {this.trackingEm = 0});

  /// Der Stil bei Skalierung 1.0 — für `ThemeData` und statische Kontexte.
  final TextStyle base;

  /// Laufweite als Anteil der Schriftgröße.
  final double trackingEm;

  /// Der Stil mit proportional mitwachsender Laufweite.
  ///
  /// Überall dort verwenden, wo ein Label gesperrt ist. Ohne Sperrung ist das
  /// Ergebnis identisch mit [base], der Aufruf also unschädlich.
  TextStyle of(BuildContext context) {
    if (trackingEm == 0) return base;
    final scaled = MediaQuery.textScalerOf(context).scale(base.fontSize!);
    return base.copyWith(letterSpacing: scaled * trackingEm);
  }
}

abstract final class AtemType {
  static TextStyle _poppins(
    double size,
    FontWeight weight, {
    Color color = AtemColors.textPrimary,
    double? height,
    double tracking = 0,
  }) =>
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: size * tracking,
      );

  /// Fliesstext in der **Systemschrift** — auf Android also Roboto.
  ///
  /// ## Warum nicht Poppins
  ///
  /// Poppins ist geometrisch: kreisrunde Punzen, offene Formen, kaum
  /// Unterscheidung zwischen `l`, `I` und `1`. Als Überschrift ist das ihr
  /// Charakter; bei 14 sp Fliesstext auf einem Telefon ist es eine Hürde. Sie
  /// war nie als Lesetext gedacht — die Design-Referenz nennt sie „UI".
  ///
  /// Die Systemschrift kostet keine Bytes, ist auf jedem Gerät da und für
  /// genau diese Grösse gezeichnet. Sie bekommt bewusst **keine eigene
  /// Familie im Vorrat**: Eine dritte Schriftdatei wäre eine dritte Stimme,
  /// und die App hat schon zwei.
  ///
  /// Überschriften, Knöpfe und Labels bleiben Poppins, Messwerte bleiben Mono.
  static TextStyle _text(
    double size,
    FontWeight weight, {
    Color color = AtemColors.textPrimary,
    double? height,
  }) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  static TextStyle _mono(
    double size,
    FontWeight weight, {
    Color color = AtemColors.textPrimary,
    double tracking = 0,
    bool tabular = true,
  }) =>
      TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: size * tracking,
        // Messwerte dürfen im Sekundentakt nicht springen.
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
      );

  // --- Werte -----------------------------------------------------------------

  /// 48 sp · Readiness-Score im Gauge.
  static final display = AtemTextRole(
    _poppins(48, FontWeight.w700, height: 1.0),
  );

  /// 24 sp · Session- und Pausen-Timer.
  static final valueLarge = AtemTextRole(
    _mono(24, FontWeight.w700, tracking: 0.02),
    trackingEm: 0.02,
  );

  /// 16 sp · HRV, Ruhe-HF, Schlaf, Eingabefelder.
  static final valueMedium = AtemTextRole(_mono(16, FontWeight.w600));

  // --- Titel -----------------------------------------------------------------

  /// 20 sp · Begrüßung, Screen- und Dialogtitel.
  static final titleLarge = AtemTextRole(_poppins(20, FontWeight.w600));

  /// 16 sp · Karten-, Übungs- und Quick-Action-Titel.
  static final titleMedium = AtemTextRole(
    _poppins(16, FontWeight.w600, height: 1.35),
  );

  // --- Labels ----------------------------------------------------------------

  /// 14 sp · Buttons, Dialogaktionen, CTA.
  ///
  /// Bewusst nicht 12: Auf Gradient-Buttons wäre 12 sp schwächer als die
  /// [labelSmall]-Unterzeilen daneben, und die CTA-Hierarchie kippt.
  static final labelMedium = AtemTextRole(
    _poppins(14, FontWeight.w600, tracking: 0.10),
    trackingEm: 0.10,
  );

  /// 13 sp · Badges, Unterzeilen, Statuszeilen, Historie.
  ///
  /// **Systemschrift, nicht Poppins**, und 13 statt 12: Diese Rolle trägt die
  /// erklärenden Sätze unter jeder Überschrift — sie wird gelesen, nicht
  /// überflogen.
  static final labelSmall = AtemTextRole(
    _text(13, FontWeight.w400,
        color: AtemColors.textTertiary, height: 1.4),
  );

  /// 12 sp · Sektionslabels, Navigation, Tabellenköpfe, Stat-Beschriftung.
  ///
  /// Der HUD-Träger. Gewicht 500 statt 700: Bei 8,5 sp brauchte das Label Fett,
  /// um überhaupt zu existieren — bei 12 sp macht Fett es zur Überschrift.
  ///
  /// **Die Farbe ist `textTertiary`, nicht `textSecondary`.** Diese Rolle
  /// trägt inzwischen nicht mehr nur Sektionsköpfe, sondern die Metazeile
  /// unter fast jedem Titel — „KRAFT · 49 MIN", „6 ÜBUNGEN · 18 SÄTZE". In
  /// #94A3B8 gesperrt und in Mono war das auf einem Telefon mühsam.
  /// #94A3B8 bleibt die dunkelste erlaubte Textfarbe; sie wird nur nicht mehr
  /// für Text verwendet, den man tatsächlich liest.
  static final labelMicro = AtemTextRole(
    _mono(12, FontWeight.w500,
        color: AtemColors.textTertiary, tracking: 0.16, tabular: false),
    trackingEm: 0.16,
  );

  /// 10 sp · **Nur** die fünf dekorativen Ausnahmen.
  ///
  /// Verwendung ausschließlich über das Primitiv, das eine Vorlese-Alternative
  /// erzwingt. Zulässig sind: die drei Chart-Legenden, die Prozentzahl im
  /// Mini-Ring, die Wortmarke. Siehe `docs/contracts/01-accessibility.md` R2.
  static final labelDeco = AtemTextRole(
    _mono(10, FontWeight.w500,
        color: AtemColors.textSecondary, tracking: 0.14, tabular: false),
    trackingEm: 0.14,
  );

  /// Fließtext. Nicht Teil der acht HUD-Rollen, aber gebraucht.
  ///
  /// 15 sp Systemschrift in `textTertiary`. Vorher 14 sp Poppins in
  /// `textSecondary` — die dunkelste erlaubte Farbe in der Schrift mit den
  /// rundesten Formen, bei der kleinsten Lesegrösse. Drei Entscheidungen, die
  /// einzeln vertretbar waren und zusammen einen Absatz ergaben, den man
  /// anstrengt zu lesen.
  static final body = AtemTextRole(
    _text(15, FontWeight.w400, color: AtemColors.textTertiary, height: 1.5),
  );

  /// Kartentitel in einer Kachel — etwas kleiner als [titleMedium].
  static TextStyle titleSmallOrDefault(BuildContext c) =>
      titleMedium.of(c).copyWith(fontSize: 14);

  /// Übersetzung in Flutters Material-Slots — für `ThemeData`.
  ///
  /// Die Laufweite ist hier auf Skalierung 1.0 eingefroren. Wo eine gesperrte
  /// Rolle direkt verwendet wird, `AtemType.<rolle>.of(context)` nehmen.
  static TextTheme get textTheme => TextTheme(
        displayLarge: display.base,
        displayMedium: valueLarge.base,
        headlineSmall: titleLarge.base,
        titleLarge: titleLarge.base,
        titleMedium: titleMedium.base,
        titleSmall: labelSmall.base,
        bodyLarge: body.base,
        bodyMedium: body.base,
        bodySmall: labelSmall.base,
        labelLarge: labelMedium.base,
        labelMedium: valueMedium.base,
        labelSmall: labelMicro.base,
      );
}
