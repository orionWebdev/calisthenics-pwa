/// ATEM Performance — App Theme
/// Neon Cyberpunk & Dark Glassmorphism.
///
/// Zielversion: Flutter 3.27+ (nutzt `Color.withValues` und die `*ThemeData`-APIs).
/// Benötigte Dependency: `google_fonts`.
///
/// Aufbau:
///   AtemColors     — Farbtokens (Single Source of Truth)
///   AtemGradients  — Neon-Verläufe
///   AtemRadii /    — Geometrie- und Abstands-Tokens
///   AtemSpacing
///   AtemGlow       — Neon-Schatten
///   AtemGlass      — Glassmorphism-Rezepte (Decorations + Widgets)
///   AtemTheme.dark — das ThemeData
library;

import 'dart:ui';

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';


// ---------------------------------------------------------------------------
// FARBTOKENS
// ---------------------------------------------------------------------------

abstract final class AtemColors {
  // --- Base -----------------------------------------------------------------
  /// Ultra Pitch Black, leicht blaustichig — Scaffold-Hintergrund.
  static const base = Color(0xFF050507);

  /// Card / Surface. Als Glas mit ~0.72–0.85 Alpha verwenden.
  static const card = Color(0xFF14141D);

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

  // --- Text -----------------------------------------------------------------
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF94A3B8);

  /// Pills, Tag-Labels — heller als secondary, ruhiger als primary.
  static const textTertiary = Color(0xFFCDD3EA);

  static const textDisabled = Color(0xFF4A4F63);

  /// Auf Neon-Flächen (Cyan/Green) liegender Text — dunkel für Kontrast.
  static const onNeon = Color(0xFF050507);
}

// ---------------------------------------------------------------------------
// GRADIENTEN
// ---------------------------------------------------------------------------

abstract final class AtemGradients {
  /// Cyan → Violet → Magenta. Arc-Gauge, Chart-Linie, Primary Button.
  static const neonWave = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AtemColors.cyan, AtemColors.violetLight, AtemColors.magenta],
    stops: [0.0, 0.55, 1.0],
  );

  /// Gradient-Border der Hero-/Session-Card (135°).
  static const cardBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AtemColors.cyan, AtemColors.violet, AtemColors.magenta],
    stops: [0.0, 0.55, 1.0],
  );

  /// Marken-CTA: Deep Rose → Magenta.
  static const brandCta = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AtemColors.magentaDeep, AtemColors.magenta],
  );

  /// Recovery-Verlauf — Green → Cyan.
  static const recovery = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AtemColors.green, AtemColors.cyan],
  );

  /// Avatar-Ring (SweepGradient als Ersatz für CSS conic-gradient).
  static const avatarRing = SweepGradient(
    colors: [
      AtemColors.cyan,
      AtemColors.violetLight,
      AtemColors.magenta,
      AtemColors.green,
      AtemColors.cyan,
    ],
  );

  /// Glas-Highlight: heller Lichtstreif von oben links über die Card.
  static final glassSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.06),
      Colors.white.withValues(alpha: 0.015),
      Colors.transparent,
    ],
    stops: const [0.0, 0.45, 1.0],
  );

  /// Chart-Area-Fill (vertikal auslaufend).
  static final chartArea = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AtemColors.cyan.withValues(alpha: 0.22),
      AtemColors.violet.withValues(alpha: 0.08),
      AtemColors.base.withValues(alpha: 0.0),
    ],
    stops: const [0.0, 0.6, 1.0],
  );

  /// Verlauf für einen einzelnen Akzent (Buttons, Fortschrittsbalken).
  static LinearGradient accent(Color c) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c, Color.lerp(c, AtemColors.violet, 0.45)!],
      );
}

// ---------------------------------------------------------------------------
// GEOMETRIE & ABSTÄNDE
// ---------------------------------------------------------------------------

abstract final class AtemRadii {
  static const card = 20.0;
  static const sheet = 28.0;
  static const pill = 30.0;
  static const statBox = 14.0;
  static const iconBox = 10.0;

  static const cardR = BorderRadius.all(Radius.circular(card));
  static const statBoxR = BorderRadius.all(Radius.circular(statBox));
  static const pillR = BorderRadius.all(Radius.circular(pill));
  static const sheetR =
      BorderRadius.vertical(top: Radius.circular(sheet));
}

abstract final class AtemSpacing {
  static const screenPadding = 16.0;
  static const cardPadding = 14.0;
  static const cardGap = 13.0;
  static const gridGap = 11.0;

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AtemMotion {
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const pulse = Duration(milliseconds: 1800);
  static const curve = Curves.easeOutCubic;
}

// ---------------------------------------------------------------------------
// NEON-GLOW
// ---------------------------------------------------------------------------

abstract final class AtemGlow {
  /// Weicher Halo hinter Cards und Icon-Boxen.
  static List<BoxShadow> soft(Color c, {double opacity = 0.5}) => [
        BoxShadow(
          color: c.withValues(alpha: opacity),
          blurRadius: 26,
          spreadRadius: -8,
        ),
      ];

  /// Harter kleiner Punkt-Glow (Live-Dots, Status-Indikatoren).
  static List<BoxShadow> dot(Color c) => [
        BoxShadow(color: c, blurRadius: 8),
      ];

  /// Text-Glow als Shadow-Liste für [TextStyle.shadows].
  static List<Shadow> text(Color c, {double opacity = 0.55}) => [
        Shadow(color: c.withValues(alpha: opacity), blurRadius: 14),
      ];

  /// Ambienter Grund-Schatten unter Glas-Flächen.
  static const List<BoxShadow> ambient = [
    BoxShadow(color: Color(0x99000000), blurRadius: 28, offset: Offset(0, 10)),
  ];

  /// Pulsierender Primary-Button — Endzustände für einen AnimationController.
  static final List<BoxShadow> buttonPulseLow = [
    BoxShadow(
        color: AtemColors.magenta.withValues(alpha: 0.55),
        blurRadius: 18,
        spreadRadius: -2),
    BoxShadow(
        color: AtemColors.cyan.withValues(alpha: 0.40),
        blurRadius: 34,
        spreadRadius: -6),
  ];

  static final List<BoxShadow> buttonPulseHigh = [
    BoxShadow(
        color: AtemColors.magenta.withValues(alpha: 0.85),
        blurRadius: 32,
        spreadRadius: 2),
    BoxShadow(
        color: AtemColors.cyan.withValues(alpha: 0.65),
        blurRadius: 50,
        spreadRadius: -2),
  ];

  /// Floating Bottom-Nav.
  static final List<BoxShadow> nav = [
    const BoxShadow(
        color: Color(0xA6000000), blurRadius: 32, offset: Offset(0, 8)),
    BoxShadow(
        color: AtemColors.cyan.withValues(alpha: 0.40),
        blurRadius: 30,
        spreadRadius: -14),
  ];
}

// ---------------------------------------------------------------------------
// GLASSMORPHISM
// ---------------------------------------------------------------------------

/// Rezepte für Dark Glassmorphism.
///
/// Der Effekt besteht immer aus drei Schichten:
///   1. `BackdropFilter` mit Blur (Milchglas)
///   2. halbtransparente Fläche in [AtemColors.card]
///   3. 1px Hairline-Border + optionaler Neon-Glow
///
/// Wichtig: `BackdropFilter` ist teuer. In langen Listen [AtemGlass.flat]
/// verwenden — visuell nah dran, aber ohne Blur-Pass.
abstract final class AtemGlass {
  static const blurSigma = 14.0;
  static const heavyBlurSigma = 28.0;

  /// Deckkraft der Glasfläche. Höher = weniger durchscheinend.
  static const tintAlpha = 0.80;

  /// Standard-Glasfläche.
  ///
  /// Enthält bewusst KEINEN Sheen-Gradient: In einer [BoxDecoration] gewinnt
  /// `gradient` gegen `color`, die Kartenfüllung würde also nie gemalt. Den
  /// Sheen als eigene Schicht darüberlegen — siehe [sheenOverlay].
  static BoxDecoration decoration({
    double radius = AtemRadii.card,
    Color? borderColor,
    Color? glow,
    double glowOpacity = 0.35,
  }) {
    return BoxDecoration(
      color: AtemColors.card.withValues(alpha: tintAlpha),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AtemColors.border, width: 1),
      boxShadow: [
        ...AtemGlow.ambient,
        if (glow != null) ...AtemGlow.soft(glow, opacity: glowOpacity),
      ],
    );
  }

  /// Lichtstreif-Schicht, die ÜBER die Glasfläche und UNTER den Inhalt gehört.
  static BoxDecoration sheenOverlay({double radius = AtemRadii.card}) {
    return BoxDecoration(
      gradient: AtemGradients.glassSheen,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Blurfreie Variante für Listen und Micro-Boxen.
  static BoxDecoration flat({
    double radius = AtemRadii.statBox,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: AtemColors.surfaceSolid,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? AtemColors.border, width: 1),
    );
  }

  /// Getönte Akzent-Fläche (z. B. Recovery-Badge auf Green).
  static BoxDecoration tinted(
    Color accent, {
    double radius = AtemRadii.pill,
    double fill = 0.12,
    double borderAlpha = 0.35,
  }) {
    return BoxDecoration(
      color: accent.withValues(alpha: fill),
      borderRadius: BorderRadius.circular(radius),
      border:
          Border.all(color: accent.withValues(alpha: borderAlpha), width: 1),
    );
  }
}

/// Frosted-Glass-Card. Blur + Tint + Hairline-Border + optionaler Neon-Glow.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AtemSpacing.cardPadding),
    this.margin,
    this.radius = AtemRadii.card,
    this.blur = AtemGlass.blurSigma,
    this.glow,
    this.glowOpacity = 0.35,
    this.borderColor,
    this.sheen = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;

  /// Neon-Farbe für den Halo hinter der Card. `null` = kein Glow.
  final Color? glow;
  final double glowOpacity;
  final Color? borderColor;
  final bool sheen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    Widget content = DecoratedBox(
      // Schatten/Glow muss außerhalb des ClipRRect liegen.
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          ...AtemGlow.ambient,
          if (glow != null) ...AtemGlow.soft(glow!, opacity: glowOpacity),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: AtemColors.card.withValues(alpha: AtemGlass.tintAlpha),
              borderRadius: borderRadius,
              border: Border.all(
                  color: borderColor ?? AtemColors.border, width: 1),
            ),
            // Sheen als eigene Schicht: in einer BoxDecoration würde ein
            // gradient die color verdrängen und die Füllung verschwinden.
            child: DecoratedBox(
              decoration: sheen
                  ? BoxDecoration(
                      gradient: AtemGradients.glassSheen,
                      borderRadius: borderRadius)
                  : const BoxDecoration(),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return margin == null ? content : Padding(padding: margin!, child: content);
  }
}

/// Glass-Card mit Neon-Gradient-Border — für die Hero-/Session-Card.
class GradientBorderGlassCard extends StatelessWidget {
  const GradientBorderGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AtemSpacing.cardPadding),
    this.margin,
    this.radius = AtemRadii.card,
    this.borderWidth = 1.5,
    this.gradient = AtemGradients.cardBorder,
    this.blur = AtemGlass.blurSigma,
    this.glow = AtemColors.cyan,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double borderWidth;
  final Gradient gradient;
  final double blur;
  final Color? glow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final outerRadius = BorderRadius.circular(radius + borderWidth);
    final innerRadius = BorderRadius.circular(radius);

    Widget content = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: outerRadius,
        boxShadow: [
          ...AtemGlow.ambient,
          if (glow != null) ...AtemGlow.soft(glow!, opacity: 0.30),
        ],
      ),
      padding: EdgeInsets.all(borderWidth),
      child: ClipRRect(
        borderRadius: innerRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              // Deckend: der Gradient-Rand darf nicht durch die Fläche bluten.
              color: const Color(0xFF07080D).withValues(alpha: 0.96),
              borderRadius: innerRadius,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient: AtemGradients.glassSheen,
                  borderRadius: innerRadius),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      content = GestureDetector(
          onTap: onTap, behavior: HitTestBehavior.opaque, child: content);
    }

    return margin == null ? content : Padding(padding: margin!, child: content);
  }
}

/// Schwebende, milchige Bottom-Navigation / Toolbar.
class GlassBar extends StatelessWidget {
  const GlassBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.radius = AtemRadii.pill,
    this.blur = AtemGlass.heavyBlurSigma,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration:
          BoxDecoration(borderRadius: borderRadius, boxShadow: AtemGlow.nav),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AtemColors.card.withValues(alpha: 0.82),
              borderRadius: borderRadius,
              border: Border.all(
                  color: AtemColors.border.withValues(alpha: 0.9), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// THEME
// ---------------------------------------------------------------------------

abstract final class AtemTheme {
  /// Poppins = UI-Font. JetBrains Mono = HUD-Labels und Messwerte.
  static TextTheme textTheme([TextTheme? base]) {
    final poppins = GoogleFonts.poppinsTextTheme(base ?? const TextTheme());
    TextStyle mono(
            {double size = 10,
            FontWeight weight = FontWeight.w500,
            double spacing = 2.5,
            Color color = AtemColors.textSecondary}) =>
        GoogleFonts.jetBrainsMono(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          color: color,
        );

    return poppins.copyWith(
      // Große Messwerte: Readiness-Score, Strain, Session-Timer.
      displayLarge: poppins.displayLarge?.copyWith(
          fontSize: 47,
          fontWeight: FontWeight.w700,
          height: 1.0,
          letterSpacing: -1.5,
          color: AtemColors.textPrimary),
      displayMedium: poppins.displayMedium?.copyWith(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          height: 1.05,
          letterSpacing: -1.0,
          color: AtemColors.textPrimary),
      displaySmall: poppins.displaySmall?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.1,
          color: AtemColors.textPrimary),

      // Screen-Überschriften.
      headlineMedium: poppins.headlineMedium?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AtemColors.textPrimary),
      headlineSmall: poppins.headlineSmall?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AtemColors.textPrimary),

      // Greeting "Guten Morgen, Alex".
      titleLarge: poppins.titleLarge?.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: AtemColors.textPrimary),
      // Card-Titel.
      titleMedium: poppins.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: AtemColors.textPrimary),
      // Quick-Card-Titel.
      titleSmall: poppins.titleSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AtemColors.textPrimary),

      bodyLarge: poppins.bodyLarge?.copyWith(
          fontSize: 14, height: 1.5, color: AtemColors.textPrimary),
      bodyMedium: poppins.bodyMedium?.copyWith(
          fontSize: 12, height: 1.5, color: AtemColors.textSecondary),
      bodySmall: poppins.bodySmall?.copyWith(
          fontSize: 10.5, height: 1.5, color: AtemColors.textSecondary),

      // Button-Label "SESSION STARTEN".
      labelLarge: poppins.labelLarge?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.5,
          color: AtemColors.textPrimary),
      // Status-Label "PEAK READINESS" — Farbe pro Kontext überschreiben.
      labelMedium: mono(
          size: 10.5,
          weight: FontWeight.w700,
          color: AtemColors.textPrimary),
      // HUD-Section-Label "ATEM READINESS", "PERFORMANCE · 7 TAGE".
      labelSmall: mono(size: 9),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final text = textTheme(base.textTheme);

    const scheme = ColorScheme.dark(
      primary: AtemColors.magenta,
      onPrimary: AtemColors.textPrimary,
      primaryContainer: AtemColors.surfaceRaised,
      onPrimaryContainer: AtemColors.magenta,
      // Cyan bleibt der Daten- und Aktiv-Akzent (Load, HF, aktive Nav,
      // Fokus-Rahmen) — so steht es in beiden Design-Referenzen.
      secondary: AtemColors.cyan,
      onSecondary: AtemColors.onNeon,
      tertiary: AtemColors.green,
      onTertiary: AtemColors.onNeon,
      error: AtemColors.magenta,
      onError: AtemColors.textPrimary,
      surface: AtemColors.base,
      onSurface: AtemColors.textPrimary,
      onSurfaceVariant: AtemColors.textSecondary,
      surfaceContainerLowest: AtemColors.base,
      surfaceContainerLow: AtemColors.card,
      surfaceContainer: AtemColors.surfaceSolid,
      surfaceContainerHigh: AtemColors.surfaceRaised,
      surfaceContainerHighest: AtemColors.surfaceRaised,
      outline: AtemColors.border,
      outlineVariant: AtemColors.track,
      shadow: Colors.black,
      inverseSurface: AtemColors.textPrimary,
      onInverseSurface: AtemColors.base,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AtemColors.base,
      canvasColor: AtemColors.base,
      dividerColor: AtemColors.border,
      textTheme: text,
      primaryTextTheme: text,
      iconTheme: const IconThemeData(color: AtemColors.textSecondary, size: 20),
      primaryIconTheme: const IconThemeData(color: AtemColors.cyan),

      // Glow-States statt Material-Ripple.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: AtemColors.cyan.withValues(alpha: 0.05),
      focusColor: AtemColors.cyan.withValues(alpha: 0.12),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(color: AtemColors.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AtemColors.base,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      cardTheme: CardThemeData(
        color: AtemColors.card.withValues(alpha: AtemGlass.tintAlpha),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: AtemRadii.cardR,
          side: BorderSide(color: AtemColors.border, width: 1),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AtemColors.surfaceSolid,
        selectedColor: AtemColors.cyan.withValues(alpha: 0.14),
        side: const BorderSide(color: AtemColors.border),
        shape: const StadiumBorder(),
        labelStyle: text.bodySmall?.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: AtemColors.textTertiary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        showCheckmark: false,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AtemColors.cyan,
          foregroundColor: AtemColors.onNeon,
          disabledBackgroundColor: AtemColors.surfaceRaised,
          disabledForegroundColor: AtemColors.textDisabled,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(color: AtemColors.onNeon),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AtemColors.cyan,
          backgroundColor: AtemColors.cyan.withValues(alpha: 0.06),
          side: BorderSide(color: AtemColors.cyan.withValues(alpha: 0.45)),
          minimumSize: const Size.fromHeight(48),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AtemColors.cyan,
          textStyle: text.labelLarge?.copyWith(letterSpacing: 1.2),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AtemColors.textSecondary,
          highlightColor: AtemColors.cyan.withValues(alpha: 0.12),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AtemColors.magenta,
        foregroundColor: AtemColors.textPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const StadiumBorder(),
        extendedTextStyle: text.labelLarge,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtemColors.surfaceSolid,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: text.bodyMedium?.copyWith(color: AtemColors.textDisabled),
        labelStyle: text.labelSmall,
        floatingLabelStyle: text.labelSmall?.copyWith(color: AtemColors.cyan),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AtemRadii.statBoxR,
          borderSide: BorderSide(color: AtemColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AtemRadii.statBoxR,
          borderSide: BorderSide(color: AtemColors.cyan, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AtemRadii.statBoxR,
          borderSide: BorderSide(color: AtemColors.magenta),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AtemRadii.statBoxR,
          borderSide: BorderSide(color: AtemColors.magenta, width: 1.5),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AtemColors.cyan.withValues(alpha: 0.14),
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            fontSize: 8.5,
            color: states.contains(WidgetState.selected)
                ? AtemColors.cyan
                : AtemColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AtemColors.cyan
                : AtemColors.textSecondary,
          ),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AtemColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AtemColors.surfaceRaised,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AtemColors.border,
        shape: RoundedRectangleBorder(borderRadius: AtemRadii.sheetR),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AtemColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: text.titleMedium,
        contentTextStyle: text.bodyMedium,
        shape: const RoundedRectangleBorder(
          borderRadius: AtemRadii.cardR,
          side: BorderSide(color: AtemColors.border),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AtemColors.surfaceRaised,
        contentTextStyle: text.bodyMedium?.copyWith(color: AtemColors.textPrimary),
        actionTextColor: AtemColors.cyan,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AtemRadii.statBoxR,
          side: BorderSide(color: AtemColors.border),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AtemColors.cyan,
        unselectedLabelColor: AtemColors.textSecondary,
        labelStyle: text.labelMedium?.copyWith(color: AtemColors.cyan),
        unselectedLabelStyle: text.labelMedium
            ?.copyWith(color: AtemColors.textSecondary, fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: AtemColors.cyan,
        dividerColor: Colors.transparent,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: AtemColors.cyan,
        inactiveTrackColor: AtemColors.track,
        thumbColor: AtemColors.cyan,
        overlayColor: AtemColors.cyan.withValues(alpha: 0.14),
        trackHeight: 4,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AtemColors.cyan,
        linearTrackColor: AtemColors.track,
        circularTrackColor: AtemColors.track,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AtemColors.onNeon
                : AtemColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AtemColors.cyan
                : AtemColors.track),
        trackOutlineColor:
            const WidgetStatePropertyAll(AtemColors.border),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: AtemColors.textSecondary,
        textColor: AtemColors.textPrimary,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: AtemRadii.statBoxR),
      ),

      dividerTheme: const DividerThemeData(
        color: AtemColors.border,
        thickness: 1,
        space: 1,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: AtemGlass.flat(radius: AtemRadii.iconBox),
        textStyle: text.bodySmall?.copyWith(color: AtemColors.textPrimary),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// SEMANTIK-KONVENTION
// ---------------------------------------------------------------------------
//
// cyan    → Load, Herzfrequenz, aktive Navigation, primäre Aktion
// magenta → Strain, Intensität, Alerts, Notifications
// green   → Recovery, HRV, Live-Status, Erfolg
// violet  → Schlaf, Periodisierung, Brückenfarbe der Verläufe
// amber   → Warnung zwischen green und magenta
//
// Verwendung:
//   GlassCard(glow: AtemColors.cyan, child: ...)
//   GradientBorderGlassCard(child: ...)            // Hero-/Session-Card
//   Container(decoration: AtemGlass.flat())        // Micro-Stat-Box
//   Container(decoration: AtemGlass.tinted(AtemColors.green))  // Badge
//   GlassBar(child: ...)                           // Floating Bottom-Nav
