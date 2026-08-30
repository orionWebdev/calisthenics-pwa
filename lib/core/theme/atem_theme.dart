import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'atem_colors.dart';
import 'atem_page_transition.dart';
import 'atem_type.dart';
import 'atem_geometry.dart';

// ---------------------------------------------------------------------------
// THEME
// ---------------------------------------------------------------------------

abstract final class AtemTheme {
  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final text = AtemType.textTheme;

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

      cardTheme: const CardThemeData(
        color: AtemColors.cardTinted,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AtemRadii.cardR,
          side: BorderSide(color: AtemColors.border, width: 1),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AtemColors.surfaceSolid,
        selectedColor: AtemColors.cyan.withValues(alpha: 0.14),
        side: const BorderSide(color: AtemColors.border),
        shape: const StadiumBorder(),
        labelStyle: AtemType.labelSmall.base,
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
          (states) => AtemType.labelMicro.base.copyWith(
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
        contentTextStyle:
            text.bodyMedium?.copyWith(color: AtemColors.textPrimary),
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
        unselectedLabelStyle: text.labelMedium?.copyWith(
            color: AtemColors.textSecondary, fontWeight: FontWeight.w500),
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
        trackOutlineColor: const WidgetStatePropertyAll(AtemColors.border),
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
        decoration: BoxDecoration(
          color: AtemColors.surfaceSolid,
          borderRadius: BorderRadius.circular(AtemRadii.iconBox),
          border: Border.all(color: AtemColors.border),
        ),
        textStyle: text.bodySmall?.copyWith(color: AtemColors.textPrimary),
      ),

      // Ein Übergang für alle Plattformen — er beschreibt keine Geste,
      // sondern eine Richtung, und die ist überall dieselbe.
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: AtemPageTransitionsBuilder(),
        TargetPlatform.iOS: AtemPageTransitionsBuilder(),
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
