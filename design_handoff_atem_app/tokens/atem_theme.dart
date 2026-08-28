import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ATEM Performance App — Theme
/// Neon Cyberpunk & Dark Glassmorphism
/// Quelle: ATEM Dashboard.dc.html (Design-Referenz)
abstract class AtemColors {
  // Base
  static const deepCanvas = Color(0xFF030308); // Ultra Pitch Black, blaustichig
  static const surface = Color(0xFF090A10); // Card/Surface (mit 0.8 Opacity nutzen)
  static const surfaceSolid = Color(0xFF0B0C14); // Micro-Stat-Boxen, Badges
  static const border = Color(0xFF1A1C29); // 1px Card-Border
  static const track = Color(0xFF14161F); // Gauge/Progress-Track
  static const gridLine = Color(0xFF12141F); // Chart-Gridlines

  // Neon Accents
  static const cyan = Color(0xFF00F2FE); // Accent 1 — Electric Cyan
  static const violet = Color(0xFF7B2CBF); // Accent 2 — Deep Cyber Violet
  static const violetLight = Color(0xFF9D4EDD);
  static const magenta = Color(0xFFFF007A); // Accent 3 — Neon Magenta
  static const lime = Color(0xFF00FF87); // Accent 4 — Recovery Green

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF7A819B);
  static const textTertiary = Color(0xFFCDD3EA); // Pills, Tag-Labels
}

abstract class AtemGradients {
  /// Cyan → Violet → Magenta (Arc-Gauge, Chart-Linie, Primary Button)
  static const neonWave = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AtemColors.cyan, AtemColors.violetLight, AtemColors.magenta],
    stops: [0.0, 0.55, 1.0],
  );

  /// Gradient-Border der Session-Card (135°)
  static const cardBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AtemColors.cyan, AtemColors.violet, AtemColors.magenta],
    stops: [0.0, 0.55, 1.0],
  );

  /// Avatar-Ring (SweepGradient statt CSS conic-gradient)
  static const avatarRing = SweepGradient(
    colors: [
      AtemColors.cyan,
      AtemColors.violetLight,
      AtemColors.magenta,
      AtemColors.lime,
      AtemColors.cyan,
    ],
  );

  /// Chart-Area-Fill (vertikal auslaufend)
  static LinearGradient chartArea = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AtemColors.cyan.withOpacity(0.22),
      AtemColors.violet.withOpacity(0.08),
      AtemColors.deepCanvas.withOpacity(0),
    ],
    stops: const [0.0, 0.6, 1.0],
  );
}

abstract class AtemRadii {
  static const card = 20.0;
  static const pill = 30.0; // Badges, Buttons, Floating Nav
  static const statBox = 14.0;
  static const iconBox = 10.0;
}

abstract class AtemSpacing {
  static const screenPadding = 16.0;
  static const cardGap = 13.0;
  static const gridGap = 11.0;
  static const cardPadding = 14.0;
}

/// Neon-Glow-Schatten (box-shadow-Äquivalente)
abstract class AtemGlow {
  static List<BoxShadow> soft(Color c, {double opacity = 0.5}) => [
        BoxShadow(
          color: c.withOpacity(opacity),
          blurRadius: 26,
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> dot(Color c) =>
      [BoxShadow(color: c, blurRadius: 8)];

  /// Pulsierender Button-Glow (Endzustände für AnimationController)
  static List<BoxShadow> buttonPulseLow = [
    BoxShadow(color: AtemColors.magenta.withOpacity(0.55), blurRadius: 18, spreadRadius: -2),
    BoxShadow(color: AtemColors.cyan.withOpacity(0.4), blurRadius: 34, spreadRadius: -6),
  ];
  static List<BoxShadow> buttonPulseHigh = [
    BoxShadow(color: AtemColors.magenta.withOpacity(0.85), blurRadius: 32, spreadRadius: 2),
    BoxShadow(color: AtemColors.cyan.withOpacity(0.65), blurRadius: 50, spreadRadius: -2),
  ];

  static List<BoxShadow> nav = [
    const BoxShadow(color: Color(0xA6000000), blurRadius: 32, offset: Offset(0, 8)),
    BoxShadow(color: AtemColors.cyan.withOpacity(0.4), blurRadius: 30, spreadRadius: -14),
  ];
}

abstract class AtemTheme {
  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);

    // Poppins = UI-Font, JetBrains Mono = HUD-Labels/Werte
    final poppins = GoogleFonts.poppinsTextTheme(base.textTheme);
    final mono = GoogleFonts.jetBrainsMono();

    return base.copyWith(
      scaffoldBackgroundColor: AtemColors.deepCanvas,
      colorScheme: const ColorScheme.dark(
        surface: AtemColors.surface,
        primary: AtemColors.cyan,
        secondary: AtemColors.violetLight,
        tertiary: AtemColors.magenta,
        error: AtemColors.magenta,
        onSurface: AtemColors.textPrimary,
        outline: AtemColors.border,
      ),
      textTheme: poppins.copyWith(
        // Greeting "Guten Morgen, Alex"
        titleLarge: poppins.titleLarge?.copyWith(fontSize: 19, fontWeight: FontWeight.w600, color: AtemColors.textPrimary),
        // Card-Titel ("ATEM Hybrid – Day 4 …")
        titleMedium: poppins.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, height: 1.35),
        // Quick-Card-Titel
        titleSmall: poppins.titleSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
        // Readiness-Score "89"
        displayLarge: poppins.displayLarge?.copyWith(fontSize: 47, fontWeight: FontWeight.w700, height: 1),
        // Sekundärtext / Sublines
        bodySmall: poppins.bodySmall?.copyWith(fontSize: 9.5, color: AtemColors.textSecondary, height: 1.5),
        bodyMedium: poppins.bodyMedium?.copyWith(fontSize: 10.5, color: AtemColors.textSecondary),
        // HUD-Section-Label ("ATEM READINESS", "PERFORMANCE · 7 TAGE")
        labelSmall: mono.copyWith(fontSize: 9, letterSpacing: 2.5, color: AtemColors.textSecondary),
        // Status-Label ("PEAK READINESS") — Farbe kontextabhängig setzen
        labelMedium: mono.copyWith(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 2.5),
        // Button-Label ("SESSION STARTEN")
        labelLarge: poppins.labelLarge?.copyWith(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2.5),
      ),
      cardTheme: CardTheme(
        color: AtemColors.surface.withOpacity(0.8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtemRadii.card),
          side: const BorderSide(color: AtemColors.border, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AtemColors.surfaceSolid,
        side: const BorderSide(color: AtemColors.border),
        shape: const StadiumBorder(),
        labelStyle: poppins.bodySmall?.copyWith(fontSize: 9.5, fontWeight: FontWeight.w500, color: AtemColors.textTertiary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dividerColor: AtemColors.border,
      splashFactory: NoSplash.splashFactory, // Glow-States statt Material-Ripple
    );
  }
}

/// Semantik der Accent-Farben (Konvention für Screens):
/// cyan    → Load / Herzfrequenz / aktive Nav
/// magenta → Strain / Intensität / Nutrition / Notifications
/// lime    → Recovery / HRV / Live-Status
/// violet  → Schlaf / Periodisierung
///
/// Glassmorphism-Card-Rezept:
///   ClipRRect(borderRadius: 20) → BackdropFilter(ImageFilter.blur(14,14))
///   → Container(color: surface@0.8, border: 1px AtemColors.border)
/// Gradient-Border (Session-Card): äußerer Container mit
///   AtemGradients.cardBorder + padding 1.5 → innerer Container radius 20.5-1.5.
