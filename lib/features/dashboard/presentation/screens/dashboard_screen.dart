import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../workout/application/workout_providers.dart';
import '../../../workout/presentation/screens/workout_runner_screen.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/dashboard_providers.dart';
import '../../domain/dashboard_data.dart';
import '../../domain/readiness_level.dart';
import '../readiness_level_ui.dart';

/// ATEM Performance Dashboard.
///
/// Umsetzung des Handoffs „ATEM Dashboard.dc.html". Sämtliche Werte kommen aus
/// [dashboardDataProvider] — dieser Screen hält keine eigenen Daten.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  // Score-Count-up: 0 → Zielwert, 1400 ms, ease-out-cubic.
  late final AnimationController _scoreCtrl;
  late Animation<double> _scoreAnim;
  double _lastScore = 0;

  // Dauerschleifen aus dem Handoff.
  late final AnimationController _flickerCtrl; // Brand-Dot   2.6 s
  late final AnimationController _liveCtrl; // LIVE-Dot     1.8 s
  late final AnimationController _pulseCtrl; // Button-Glow  2.2 s
  late final AnimationController _sessionDotCtrl; // Session-Dot 1.2 s

  /// Bis go_router kommt (Stufe 6) ist der aktive Tab lokaler Zustand —
  /// ein Provider dafür wäre schon heute die falsche Schicht.
  int _activeNav = 0;

  @override
  void initState() {
    super.initState();
    _scoreCtrl = AnimationController(vsync: this, duration: AtemMotion.countUp);
    _scoreAnim = const AlwaysStoppedAnimation(0);
    _flickerCtrl =
        AnimationController(vsync: this, duration: AtemMotion.brandDotFlicker);
    _liveCtrl =
        AnimationController(vsync: this, duration: AtemMotion.livePulse);
    _pulseCtrl =
        AnimationController(vsync: this, duration: AtemMotion.buttonGlowPulse);
    _sessionDotCtrl =
        AnimationController(vsync: this, duration: AtemMotion.sessionDotPulse);
    // Die Schleifen werden nicht hier gestartet, sondern in
    // didChangeDependencies — dort ist die MediaQuery verfügbar.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Vertrag 01-accessibility R8: dekorative Dauerschleifen respektieren
    // „Animationen reduzieren". Ohne das terminiert pumpAndSettle() nie.
    AtemMotion.syncLoop(context, _flickerCtrl);
    AtemMotion.syncLoop(context, _liveCtrl, reverse: true);
    AtemMotion.syncLoop(context, _pulseCtrl, reverse: true);
    AtemMotion.syncLoop(context, _sessionDotCtrl, reverse: true);
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _flickerCtrl.dispose();
    _liveCtrl.dispose();
    _pulseCtrl.dispose();
    _sessionDotCtrl.dispose();
    super.dispose();
  }

  void _animateScoreTo(double target) {
    if ((target - _lastScore).abs() < 0.01 && _scoreCtrl.isCompleted) return;
    _scoreAnim = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: AtemMotion.curve),
    );
    _lastScore = target;
    _scoreCtrl.duration = AtemMotion.duration(context, AtemMotion.countUp);
    _scoreCtrl.forward(from: 0);
  }

  Future<void> _onToggleSession(String sessionId) async {
    final wasRunning = ref.read(sessionTimerProvider).isRunning;
    await ref.read(sessionTimerProvider.notifier).toggle(sessionId);

    // Beim Start direkt in den Runner — dort wird trainiert. Der Timer läuft im
    // Notifier weiter und zeigt nach der Rückkehr „SESSION LÄUFT".
    if (!wasRunning && ref.read(sessionTimerProvider).isRunning && mounted) {
      await Navigator.of(context).pushNamed(
        WorkoutRunnerScreen.routeName,
        arguments: sessionId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dashboardDataProvider);

    ref.listen<AsyncValue<DashboardData>>(dashboardDataProvider, (_, next) {
      final score = next.value?.readiness.score;
      if (score != null) _animateScoreTo(score);
    });

    return Scaffold(
      backgroundColor: AtemColors.base,
      body: async.when(
        loading: () => const _DashboardSkeleton(),
        error: (e, _) => _DashboardError(
          message: '$e',
          onRetry: () => ref.invalidate(dashboardDataProvider),
        ),
        data: (data) => _buildContent(context, data),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardData data) {
    return Stack(
      children: [
        RefreshIndicator(
          color: AtemColors.cyan,
          backgroundColor: AtemColors.surfaceRaised,
          onRefresh: () async => ref.invalidate(dashboardDataProvider),
          child: ListView(
            padding: EdgeInsets.only(
              left: AtemSpacing.screenPadding,
              right: AtemSpacing.screenPadding,
              top: MediaQuery.paddingOf(context).top + 8,
              // Freiraum für die Floating Nav.
              bottom: 130,
            ),
            children: [
              _CyberHeader(user: data.user, flicker: _flickerCtrl),
              const SizedBox(height: AtemSpacing.cardGap),
              _ReadinessHero(
                readiness: data.readiness,
                scoreAnimation: _scoreAnim,
                livePulse: _liveCtrl,
              ),
              const SizedBox(height: AtemSpacing.cardGap),
              _PerformanceCard(performance: data.performance),
              const SizedBox(height: AtemSpacing.cardGap),
              if (data.session != null)
                _SessionCard(
                  session: data.session!,
                  glowPulse: _pulseCtrl,
                  dotPulse: _sessionDotCtrl,
                  elapsed: ref.watch(sessionTimerProvider).elapsed,
                  onToggle: () => _onToggleSession(data.session!.id),
                )
              else
                const _NoSessionCard(),
              const SizedBox(height: AtemSpacing.cardGap),
              _QuickActionsGrid(data: data),
            ],
          ),
        ),
        Positioned(
          left: AtemSpacing.screenPadding,
          right: AtemSpacing.screenPadding,
          bottom: AtemSpacing.screenPadding,
          child: _FloatingNav(
            activeIndex: _activeNav,
            onSelect: (i) => setState(() => _activeNav = i),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// 1. HEADER — Cyber Status Bar
// ===========================================================================

class _CyberHeader extends StatelessWidget {
  const _CyberHeader({required this.user, required this.flicker});

  final UserSummary user;
  final Animation<double> flicker;

  /// Opacity-Verlauf des Brand-Dots: 1 → 0.25 → 1 → 0.55 → 1.
  double _flickerOpacity(double t) {
    const stops = [1.0, 0.25, 1.0, 0.55, 1.0];
    final scaled = t * (stops.length - 1);
    final i = scaled.floor().clamp(0, stops.length - 2);
    return ui.lerpDouble(stops[i], stops[i + 1], scaled - i)!;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AtemColors.card.withValues(alpha: 0.8),
                  borderRadius: AtemRadii.pillR,
                  border: Border.all(color: AtemColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: flicker,
                      builder: (_, __) => Opacity(
                        opacity: _flickerOpacity(flicker.value),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AtemColors.green,
                            shape: BoxShape.circle,
                            boxShadow: AtemGlow.dot(AtemColors.green),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ATEM HYBRID',
                      style: text.labelSmall?.copyWith(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: AtemColors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Text('${_greeting()}, ${user.displayName} 👋',
                  style: text.titleLarge),
              const SizedBox(height: 2),
              Text('Optimales System-Level erreicht', style: text.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _Avatar(user: user),
      ],
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Guten Morgen';
    if (h < 18) return 'Guten Tag';
    return 'Guten Abend';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final UserSummary user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AtemGradients.avatarRing,
              boxShadow: AtemGlow.soft(AtemColors.cyan, opacity: 0.35),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: const BoxDecoration(
                  color: AtemColors.base, shape: BoxShape.circle),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: const BoxDecoration(
                    color: Color(0xFF10121F), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  user.initial,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16),
                ),
              ),
            ),
          ),
          if (user.unreadNotifications > 0)
            Positioned(
              right: 0,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17),
                height: 17,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AtemColors.magenta,
                  borderRadius: AtemRadii.pillR,
                  border: Border.all(color: AtemColors.base, width: 1.5),
                  boxShadow: AtemGlow.soft(AtemColors.magenta, opacity: 0.7),
                ),
                child: Text(
                  '${user.unreadNotifications}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AtemColors.textPrimary,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// 2. HERO — Readiness Bio-Gauge
// ===========================================================================

class _ReadinessHero extends StatelessWidget {
  const _ReadinessHero({
    required this.readiness,
    required this.scoreAnimation,
    required this.livePulse,
  });

  final ReadinessSnapshot readiness;
  final Animation<double> scoreAnimation;
  final Animation<double> livePulse;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AtemCard.glass(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      glow: AtemColors.cyan,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: _AmbientCornerGlows()),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ATEM READINESS', style: text.labelSmall),
                  if (readiness.isLive) _LivePill(pulse: livePulse),
                ],
              ),
              AnimatedBuilder(
                animation: scoreAnimation,
                builder: (context, _) {
                  final value = scoreAnimation.value;
                  final level = ReadinessLevel.fromScore(value);
                  return Column(
                    children: [
                      SizedBox(
                        width: 224,
                        height: 192,
                        child: CustomPaint(
                          painter: _ArcGaugePainter(progress: value / 100),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${value.round()}',
                                      style: text.displayLarge?.copyWith(
                                        shadows: AtemGlow.text(AtemColors.cyan),
                                      ),
                                    ),
                                    Text('%',
                                        style: text.titleLarge?.copyWith(
                                          fontSize: 19,
                                          color: AtemColors.textSecondary,
                                        )),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  level.label(AppL10n.of(context)),
                                  style: text.labelMedium?.copyWith(
                                    color: level.color,
                                    shadows: AtemGlow.text(level.color),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 6),
                        decoration: BoxDecoration(
                          color: AtemColors.border.withValues(alpha: 0.5),
                          borderRadius: AtemRadii.pillR,
                          border: Border.all(color: AtemColors.border),
                        ),
                        child: Text(
                          level.tag(AppL10n.of(context)),
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(
                              fontSize: 10, color: AtemColors.textTertiary),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _MicroStat(
                      value: readiness.hrvMs == null
                          ? '–'
                          : '${readiness.hrvMs} ms',
                      label: 'HRV',
                      accent: AtemColors.green,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _MicroStat(
                      value: readiness.restingHeartRate == null
                          ? '–'
                          : '${readiness.restingHeartRate} bpm',
                      label: 'RUHE-HF',
                      accent: AtemColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _MicroStat(
                      value: readiness.sleepLabel,
                      label: 'SCHLAF',
                      accent: AtemColors.violetLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Drei dekorative Radial-Glows in den Ecken der Hero-Card.
class _AmbientCornerGlows extends StatelessWidget {
  const _AmbientCornerGlows();

  @override
  Widget build(BuildContext context) {
    Widget glow(Color c, double opacity, Alignment a) => Align(
          alignment: a,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                c.withValues(alpha: opacity),
                c.withValues(alpha: 0),
              ]),
            ),
          ),
        );

    return IgnorePointer(
      child: ClipRect(
        child: Stack(children: [
          glow(AtemColors.cyan, 0.16, const Alignment(-1.4, -1.4)),
          glow(AtemColors.violet, 0.18, const Alignment(1.5, -0.6)),
          glow(AtemColors.magenta, 0.10, const Alignment(-1.2, 1.5)),
        ]),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: AtemRadii.pillR,
        border: Border.all(color: AtemColors.green.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0.3).animate(pulse),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AtemColors.green,
                shape: BoxShape.circle,
                boxShadow: AtemGlow.dot(AtemColors.green),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'LIVE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: AtemColors.green,
                ),
          ),
        ],
      ),
    );
  }
}

class _MicroStat extends StatelessWidget {
  const _MicroStat({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AtemColors.surfaceSolid,
        borderRadius: AtemRadii.statBoxR,
        border: Border.all(color: AtemColors.border),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.28),
            blurRadius: 20,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              style: text.titleSmall?.copyWith(
                fontSize: 14.5,
                color: AtemColors.textPrimary,
                shadows: AtemGlow.text(accent, opacity: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: text.labelSmall?.copyWith(fontSize: 8, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }
}

/// 260°-Bogen, Lücke unten zentriert (Start 140°, wie im SVG-Original).
class _ArcGaugePainter extends CustomPainter {
  _ArcGaugePainter({required this.progress});

  final double progress;

  static const _startAngle = 140 * math.pi / 180;
  static const _sweepAngle = 260 * math.pi / 180;
  static const _radius = 84.0;
  static const _stroke = 13.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 6);
    final rect = Rect.fromCircle(center: center, radius: _radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = AtemColors.track;
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, track);

    final sweep = _sweepAngle * progress.clamp(0.0, 1.0);
    if (sweep <= 0) return;

    final shader = AtemGradients.neonWave.createShader(rect);

    // Glow-Kopie darunter. saveLayer, weil Paint.color bei gesetztem
    // Shader ignoriert wird und die Deckkraft sonst wirkungslos bliebe.
    canvas.saveLayer(
      rect.inflate(_stroke * 2),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.drawArc(
      rect,
      _startAngle,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.restore();

    canvas.drawArc(
      rect,
      _startAngle,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) => old.progress != progress;
}

// ===========================================================================
// 3. PERFORMANCE-CHART (7 Tage)
// ===========================================================================

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.performance});

  final WeeklyPerformance performance;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AtemCard.glass(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('PERFORMANCE · 7 TAGE',
                    style: text.labelSmall, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendDot(label: 'LOAD', color: AtemColors.cyan),
                  SizedBox(width: 8),
                  _LegendDot(label: 'STRAIN', color: AtemColors.magenta),
                  SizedBox(width: 8),
                  _LegendDot(label: 'RECOVERY', color: AtemColors.green),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 358 / 152,
            child: CustomPaint(
              painter: _PerformancePainter(
                performance: performance,
                dayLabelStyle: text.labelSmall!.copyWith(fontSize: 9),
                todayLabelStyle: text.labelSmall!.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AtemColors.textPrimary,
                ),
                tooltipStyle: text.labelSmall!
                    .copyWith(fontSize: 8.5, color: AtemColors.textTertiary),
                tooltipValueStyle: text.labelSmall!.copyWith(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: AtemColors.magenta,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: AtemGlow.dot(color),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontSize: 8, letterSpacing: 1)),
      ],
    );
  }
}

class _PerformancePainter extends CustomPainter {
  _PerformancePainter({
    required this.performance,
    required this.dayLabelStyle,
    required this.todayLabelStyle,
    required this.tooltipStyle,
    required this.tooltipValueStyle,
  });

  final WeeklyPerformance performance;
  final TextStyle dayLabelStyle;
  final TextStyle todayLabelStyle;
  final TextStyle tooltipStyle;
  final TextStyle tooltipValueStyle;

  static const _labels = ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO'];
  static const _padX = 20.0;
  static const _plotTop = 22.0;
  static const _plotBottom = 120.0;

  double _x(int i, Size size) =>
      _padX + i * (size.width - _padX * 2) / (_labels.length - 1);

  double _y(double value) =>
      _plotTop + (1 - value.clamp(0.0, 100.0) / 100) * (_plotBottom - _plotTop);

  /// Catmull-Rom → Bézier, damit die Kurve wie im Original weich läuft.
  Path _spline(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[0] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    return path;
  }

  void _text(Canvas canvas, String s, TextStyle style, Offset at,
      {bool center = true}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center ? at - Offset(tp.width / 2, tp.height / 2) : at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final days = performance.days;
    if (days.length < 2) return;

    // Gridlines.
    final grid = Paint()
      ..color = AtemColors.gridLine
      ..strokeWidth = 1;
    for (final y in const [35.0, 70.0, 105.0]) {
      canvas.drawLine(Offset(_padX, y), Offset(size.width - _padX, y), grid);
    }

    List<Offset> pts(double Function(DailyMetrics) sel) => [
          for (var i = 0; i < days.length; i++)
            Offset(_x(i, size), _y(sel(days[i])))
        ];

    final loadPts = pts((d) => d.load);
    final loadPath = _spline(loadPts);
    final rect = Offset.zero & size;

    // Area-Fill.
    final area = Path.from(loadPath)
      ..lineTo(loadPts.last.dx, size.height)
      ..lineTo(loadPts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()..shader = AtemGradients.chartArea.createShader(rect),
    );

    // Strain (gestrichelt) + Recovery.
    canvas.drawPath(
      _dash(_spline(pts((d) => d.strain)), 4, 5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AtemColors.magenta.withValues(alpha: 0.7),
    );
    canvas.drawPath(
      _spline(pts((d) => d.recovery)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AtemColors.green.withValues(alpha: 0.75),
    );

    // Load-Kurve: Glow + Linie.
    final lineShader = AtemGradients.neonWave.createShader(rect);
    canvas.saveLayer(
        rect, Paint()..color = Colors.white.withValues(alpha: 0.35));
    canvas.drawPath(
      loadPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..shader = lineShader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.restore();
    canvas.drawPath(
      loadPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..shader = lineShader,
    );

    // Datenpunkte.
    for (var i = 0; i < loadPts.length; i++) {
      if (i == performance.todayIndex) continue;
      final t = i / (loadPts.length - 1);
      final c = Color.lerp(
        Color.lerp(AtemColors.cyan, AtemColors.violetLight,
            (t / 0.55).clamp(0.0, 1.0))!,
        AtemColors.magenta,
        ((t - 0.55) / 0.45).clamp(0.0, 1.0),
      )!;
      canvas.drawCircle(
          loadPts[i], 3, Paint()..color = const Color(0xFF0A0B12));
      canvas.drawCircle(
        loadPts[i],
        3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = c,
      );
    }

    // Tageslabels.
    for (var i = 0; i < _labels.length && i < days.length; i++) {
      final isToday = i == performance.todayIndex;
      _text(canvas, _labels[i], isToday ? todayLabelStyle : dayLabelStyle,
          Offset(_x(i, size), 140));
    }

    // Heute: Drop-Line, Punkt, Tooltip.
    final ti = performance.todayIndex;
    if (ti >= 0 && ti < loadPts.length) {
      final p = loadPts[ti];
      canvas.drawPath(
        _dash(
          Path()
            ..moveTo(p.dx, 16)
            ..lineTo(p.dx, _plotBottom),
          3,
          4,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AtemColors.magenta, Color(0x1A00F2FE)],
          ).createShader(Rect.fromLTWH(p.dx - 1, 16, 2, _plotBottom - 16)),
      );

      canvas.drawCircle(
          p, 7, Paint()..color = AtemColors.magenta.withValues(alpha: 0.25));
      canvas.drawCircle(p, 4, Paint()..color = AtemColors.textPrimary);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = AtemColors.magenta,
      );

      final label = '${_labels[ti]} · LOAD ';
      final value = '${days[ti].load.round()}';
      final lp = TextPainter(
        text: TextSpan(children: [
          TextSpan(text: label, style: tooltipStyle),
          TextSpan(text: value, style: tooltipValueStyle),
        ]),
        textDirection: TextDirection.ltr,
      )..layout();

      // Innerhalb der Zeichenfläche halten — an MO/DI bzw. SA/SO würde ein
      // um den Punkt zentrierter Tooltip sonst über den Rand hinausragen.
      final boxW = lp.width + 16;
      final cx = p.dx.clamp(boxW / 2 + 2, size.width - boxW / 2 - 2);
      final box = Rect.fromCenter(
        center: Offset(cx, p.dy - 22),
        width: boxW,
        height: lp.height + 10,
      );
      final rrect = RRect.fromRectAndRadius(box, const Radius.circular(8));
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFF12141F));
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = AtemColors.magenta.withValues(alpha: 0.45),
      );
      lp.paint(canvas, Offset(box.left + 8, box.top + 5));
    }
  }

  /// Zerlegt einen Pfad in Striche — Flutter kennt kein natives dash-array.
  Path _dash(Path source, double on, double off) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        out.addPath(metric.extractPath(d, math.min(d + on, metric.length)),
            Offset.zero);
        d += on + off;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(_PerformancePainter old) => old.performance != performance;
}

// ===========================================================================
// 4. SESSION-CARD
// ===========================================================================

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.glowPulse,
    required this.dotPulse,
    required this.elapsed,
    required this.onToggle,
  });

  final TodaySession session;
  final Animation<double> glowPulse;
  final Animation<double> dotPulse;
  final Duration? elapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final running = elapsed != null;

    return AtemCard.gradientBorder(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEUTIGE SESSION',
            style: text.labelSmall
                ?.copyWith(fontSize: 8.5, color: AtemColors.cyan),
          ),
          const SizedBox(height: 7),
          Text(session.title, style: text.titleMedium),
          const SizedBox(height: 11),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Badge(label: '${session.duration.inMinutes} Min'),
              _Badge(
                label: session.intensityLabel,
                color: session.isHighIntensity ? AtemColors.magenta : null,
              ),
              _Badge(label: '${session.blockCount} Blocks'),
            ],
          ),
          const SizedBox(height: 13),
          running
              ? _RunningButton(
                  elapsed: elapsed!, pulse: dotPulse, onTap: onToggle)
              : _StartButton(pulse: glowPulse, onTap: onToggle),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AtemColors.surfaceSolid,
        borderRadius: AtemRadii.pillR,
        border: Border.all(
            color: c == null ? AtemColors.border : c.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: c ?? AtemColors.textTertiary,
            ),
      ),
    );
  }
}

class _StartButton extends StatefulWidget {
  const _StartButton({required this.pulse, required this.onTap});

  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AtemMotion.fast,
        child: AnimatedBuilder(
          animation: widget.pulse,
          builder: (context, child) {
            final t = widget.pulse.value;
            return Container(
              decoration: BoxDecoration(
                borderRadius: AtemRadii.pillR,
                boxShadow: [
                  for (var i = 0; i < AtemGlow.buttonPulseLow.length; i++)
                    BoxShadow.lerp(AtemGlow.buttonPulseLow[i],
                        AtemGlow.buttonPulseHigh[i], t)!,
                ],
              ),
              child: child,
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: const BoxDecoration(
              gradient: AtemGradients.neonWave,
              borderRadius: AtemRadii.pillR,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                    size: const Size(11, 13), painter: _PlayTrianglePainter()),
                const SizedBox(width: 9),
                Text(
                  'SESSION STARTEN',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(shadows: [
                    const Shadow(color: Colors.black26, blurRadius: 4),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = AtemColors.textPrimary);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _RunningButton extends StatelessWidget {
  const _RunningButton({
    required this.elapsed,
    required this.pulse,
    required this.onTap,
  });

  final Duration elapsed;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mm = elapsed.inMinutes.toString().padLeft(2, '0');
    final ss = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AtemColors.surfaceSolid,
          borderRadius: AtemRadii.pillR,
          border: Border.all(color: AtemColors.green.withValues(alpha: 0.6)),
          boxShadow: AtemGlow.soft(AtemColors.green, opacity: 0.35),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0.25).animate(pulse),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AtemColors.green,
                  shape: BoxShape.circle,
                  boxShadow: AtemGlow.dot(AtemColors.green),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SESSION LÄUFT · $mm:$ss',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 11.5,
                    color: AtemColors.green,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSessionCard extends StatelessWidget {
  const _NoSessionCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AtemCard.glass(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HEUTIGE SESSION',
              style: text.labelSmall?.copyWith(fontSize: 8.5)),
          const SizedBox(height: 7),
          Text('Für heute ist nichts geplant', style: text.titleMedium),
          const SizedBox(height: 4),
          Text('Plane eine Einheit oder logge ein freies Workout.',
              style: text.bodySmall),
        ],
      ),
    );
  }
}

// ===========================================================================
// 5. QUICK ACTIONS (2×2)
// ===========================================================================

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final n = data.nutrition;

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AtemSpacing.gridGap,
      crossAxisSpacing: AtemSpacing.gridGap,
      childAspectRatio: 1.28,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _QuickAction(
          accent: AtemColors.cyan,
          icon: _AtemIcons.bars,
          title: 'Workout Log',
          subtitle: Text(
            '${data.workoutLog.headline} · ${data.workoutLog.totalSets} Sets',
            style: text.bodySmall?.copyWith(fontSize: 9.5),
          ),
        ),
        _QuickAction(
          accent: AtemColors.magenta,
          icon: _AtemIcons.bolt,
          title: 'Nutrition & Fuel',
          trailing: _MiniRing(
            progress: n.progress,
            color: AtemColors.magenta,
            label: '${n.progressPercent}%',
          ),
          subtitle: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: 'Protein ${n.proteinGrams}g',
                style: text.bodySmall?.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AtemColors.magenta),
              ),
              TextSpan(
                text: ' / ${n.proteinTargetGrams}g Ziel',
                style: text.bodySmall?.copyWith(fontSize: 9.5),
              ),
            ]),
          ),
        ),
        _QuickAction(
          accent: AtemColors.green,
          icon: _AtemIcons.wave,
          title: 'Recovery Scan',
          subtitle: Text(
            data.recovery.liveHrvMs == null
                ? '${data.recovery.breathworkMinutes} Min Breathwork'
                : 'Live HRV ${data.recovery.liveHrvMs} ms · '
                    '${data.recovery.breathworkMinutes} Min Breathwork',
            style: text.bodySmall?.copyWith(fontSize: 9.5),
          ),
        ),
        _QuickAction(
          accent: AtemColors.violetLight,
          icon: _AtemIcons.calendar,
          title: 'Periodisierung',
          subtitle: Text(
            'Woche ${data.periodization.currentWeek} von '
            '${data.periodization.totalWeeks} · ${data.periodization.phaseName}',
            style: text.bodySmall?.copyWith(fontSize: 9.5),
          ),
          footer: _ProgressBar(progress: data.periodization.progress),
        ),
      ],
    );
  }
}

class _QuickAction extends StatefulWidget {
  const _QuickAction({
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.footer,
  });

  final Color accent;
  final Path Function() icon;
  final String title;
  final Widget subtitle;
  final Widget? trailing;
  final Widget? footer;

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AtemMotion.normal,
        child: AnimatedContainer(
          duration: AtemMotion.normal,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AtemColors.card.withValues(alpha: AtemColors.cardTintAlpha),
            borderRadius: AtemRadii.cardR,
            border: Border.all(
              color: _pressed
                  ? widget.accent.withValues(alpha: 0.5)
                  : AtemColors.border,
            ),
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.4),
                      blurRadius: 26,
                      spreadRadius: -8,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 33,
                    height: 33,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(AtemRadii.iconBox),
                    ),
                    child: CustomPaint(
                      painter: _StrokeIconPainter(
                          path: widget.icon(), color: widget.accent),
                    ),
                  ),
                  const Spacer(),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
              const SizedBox(height: 10),
              Text(widget.title,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Expanded(
                child: DefaultTextStyle.merge(
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  child: widget.subtitle,
                ),
              ),
              if (widget.footer != null) widget.footer!,
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniRing extends StatelessWidget {
  const _MiniRing({
    required this.progress,
    required this.color,
    required this.label,
  });

  final double progress;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: CustomPaint(
        painter: _MiniRingPainter(progress: progress, color: color),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  color: AtemColors.textPrimary,
                ),
          ),
        ),
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  _MiniRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - 3.5,
    );
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = AtemColors.track,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2),
    );
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) =>
      old.progress != progress || old.color != color;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AtemColors.track,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AtemColors.violet, AtemColors.violetLight]),
            borderRadius: BorderRadius.circular(2),
            boxShadow: AtemGlow.soft(AtemColors.violetLight, opacity: 0.5),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// 6. FLOATING BOTTOM NAV
// ===========================================================================

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.activeIndex, required this.onSelect});

  final int activeIndex;
  final ValueChanged<int> onSelect;

  static final _items = <({String label, Path Function() icon})>[
    (label: 'HOME', icon: _AtemIcons.home),
    (label: 'WORKOUTS', icon: _AtemIcons.dumbbell),
    (label: 'ANALYTICS', icon: _AtemIcons.analytics),
    (label: 'RECOVERY', icon: _AtemIcons.wave),
    (label: 'PROFIL', icon: _AtemIcons.profile),
  ];

  @override
  Widget build(BuildContext context) {
    return AtemBar(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < _items.length; i++)
            _NavItem(
              label: _items[i].label,
              icon: _items[i].icon,
              active: i == activeIndex,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Path Function() icon;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? AtemColors.cyan : AtemColors.textSecondary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1,
        duration: AtemMotion.fast,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 21,
                height: 21,
                child: CustomPaint(
                  painter: _StrokeIconPainter(
                    path: widget.icon(),
                    color: color,
                    glow: widget.active,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 7.5,
                      letterSpacing: 0.5,
                      color: color,
                    ),
              ),
              const SizedBox(height: 3),
              AnimatedOpacity(
                opacity: widget.active ? 1 : 0,
                duration: AtemMotion.fast,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AtemColors.cyan,
                    shape: BoxShape.circle,
                    boxShadow: AtemGlow.dot(AtemColors.cyan),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// ICONS — Stroke-Pfade aus dem Handoff (24×24-Viewbox)
// ===========================================================================

abstract final class _AtemIcons {
  static Path bars() => Path()
    ..moveTo(4, 20)
    ..lineTo(4, 10)
    ..moveTo(9, 20)
    ..lineTo(9, 4)
    ..moveTo(14, 20)
    ..lineTo(14, 13)
    ..moveTo(19, 20)
    ..lineTo(19, 8);

  static Path bolt() => Path()
    ..moveTo(13, 2)
    ..lineTo(5, 13)
    ..lineTo(10, 13)
    ..lineTo(8, 22)
    ..lineTo(17, 10)
    ..lineTo(12, 10)
    ..lineTo(13, 2)
    ..close();

  static Path wave() => Path()
    ..moveTo(3, 12)
    ..cubicTo(6, 5.5, 9, 5.5, 12, 12)
    ..cubicTo(15, 18.5, 18, 18.5, 21, 12);

  static Path calendar() => Path()
    ..moveTo(4.5, 6.5)
    ..lineTo(19.5, 6.5)
    ..lineTo(19.5, 19.5)
    ..lineTo(4.5, 19.5)
    ..close()
    ..moveTo(4.5, 10.5)
    ..lineTo(19.5, 10.5)
    ..moveTo(8.5, 4)
    ..lineTo(8.5, 8)
    ..moveTo(15.5, 4)
    ..lineTo(15.5, 8);

  static Path home() => Path()
    ..moveTo(4, 11.5)
    ..lineTo(12, 4.5)
    ..lineTo(20, 11.5)
    ..moveTo(6.5, 10.5)
    ..lineTo(6.5, 19.5)
    ..lineTo(17.5, 19.5)
    ..lineTo(17.5, 10.5);

  static Path dumbbell() => Path()
    ..moveTo(2.5, 12)
    ..lineTo(5.5, 12)
    ..moveTo(18.5, 12)
    ..lineTo(21.5, 12)
    ..moveTo(6.5, 8.5)
    ..lineTo(6.5, 15.5)
    ..moveTo(17.5, 8.5)
    ..lineTo(17.5, 15.5)
    ..moveTo(9.5, 6)
    ..lineTo(9.5, 18)
    ..moveTo(14.5, 6)
    ..lineTo(14.5, 18)
    ..moveTo(9.5, 12)
    ..lineTo(14.5, 12);

  static Path analytics() => Path()
    ..moveTo(5, 19.5)
    ..lineTo(5, 12.5)
    ..moveTo(12, 19.5)
    ..lineTo(12, 6.5)
    ..moveTo(19, 19.5)
    ..lineTo(19, 10);

  static Path profile() => Path()
    ..addOval(Rect.fromCircle(center: const Offset(12, 8), radius: 3.5))
    ..moveTo(4.5, 19.5)
    ..cubicTo(6.1, 15.7, 8.7, 14.2, 12, 14.2)
    ..cubicTo(15.3, 14.2, 17.9, 15.7, 19.5, 19.5);
}

/// Zeichnet einen 24×24-Pfad skaliert, mit 1.7er Stroke und runden Kappen.
class _StrokeIconPainter extends CustomPainter {
  _StrokeIconPainter({
    required this.path,
    required this.color,
    this.glow = false,
  });

  final Path path;
  final Color color;
  final bool glow;

  /// Stroke-Stärke laut Handoff (24×24-Viewbox).
  static const strokeWidth = 1.7;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 24 * 0.72;
    canvas.save();
    canvas.translate(
      (size.width - 24 * scale) / 2,
      (size.height - 24 * scale) / 2,
    );
    canvas.scale(scale);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    if (glow) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StrokeIconPainter old) =>
      old.color != color || old.glow != glow || old.path != path;
}

// ===========================================================================
// LADE- UND FEHLERZUSTÄNDE
// ===========================================================================

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double height) => Container(
          height: height,
          margin: const EdgeInsets.only(bottom: AtemSpacing.cardGap),
          decoration: BoxDecoration(
            color: AtemColors.card.withValues(alpha: 0.5),
            borderRadius: AtemRadii.cardR,
            border: Border.all(color: AtemColors.border),
          ),
        );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AtemSpacing.screenPadding,
        MediaQuery.paddingOf(context).top + 16,
        AtemSpacing.screenPadding,
        130,
      ),
      children: [block(64), block(360), block(210), block(180), block(300)],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('DATEN NICHT VERFÜGBAR',
                style: text.labelMedium?.copyWith(color: AtemColors.magenta)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: text.bodySmall),
            const SizedBox(height: 20),
            OutlinedButton(
                onPressed: onRetry, child: const Text('ERNEUT VERSUCHEN')),
          ],
        ),
      ),
    );
  }
}
