import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/domain/muscle.dart';
import '../../../exercises/presentation/muscle_ui.dart';
import '../../domain/plan.dart';

/// Ein Plan als **Karte** — Bild oben, Titel, Text, Knopf.
///
/// ## Warum Karte statt Zeile (seit 16.09.2026)
///
/// Pläne werden ein eigenes Angebot: später kommen kuratierte und
/// Premium-Pläne hinzu, mit eigenem Bild. Eine 64-dp-Zeile trägt kein Bild und
/// keinen Satz; eine Karte, die man seitlich durchblättert, schon. Der Aufbau
/// folgt der Vorgabe des Nutzers — Bildfläche, Titel, Text, ein Knopf.
///
/// ## Die Bildfläche ohne Bild
///
/// Kein Plan hat heute ein Bild. Die Fläche wird deshalb aus Tokens
/// gezeichnet: Bereichston Kraft als schwacher Verlauf auf `surfaceRaised`,
/// schräge Linien bei 6 % und das Plankürzel in Mono. Sobald ein Bild da ist,
/// ersetzt [image] die gezeichnete Fläche; die Karte ändert sonst nichts.
///
/// ## Zwei Ziele, getrennt
///
/// Die Karte öffnet den Plan, der Knopf startet ihn. Beide sind eigene
/// Tap-Ziele mit eigenem Semantics-Knoten — ein Tap auf den Knopf darf nie das
/// Detail öffnen.
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.onOpen,
    required this.onStart,
    this.description,
    this.muscles = const [],
    this.image,
    this.width = defaultWidth,
  });

  final Plan plan;
  final VoidCallback onOpen;
  final VoidCallback onStart;

  /// Freitext zum Plan. Ohne ihn steht die Metazeile als Text.
  final String? description;

  /// Höchstens drei werden gezeigt.
  final List<MuscleGroup> muscles;

  /// Späteres Planbild. Ohne Bild wird die Fläche gezeichnet.
  final ImageProvider? image;

  final double width;

  static const defaultWidth = 260.0;

  /// Kürzel wie in der Planzeile: bis zu zwei Anfangsbuchstaben.
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words.map((w) => w[0]).take(2).join();
    return (letters.isEmpty ? '·' : letters).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final minutes = plan.estimatedDuration.inMinutes;
    final meta = [
      l10n.planMeta(plan.exerciseCount, trainingTypeLabel(l10n, plan.type)),
      l10n.durationApproxMinutes(minutes),
    ].join(' · ');
    final hasDescription = description?.trim().isNotEmpty ?? false;
    final text = hasDescription ? description! : meta;
    final shown = muscles.take(3).toList();

    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: AtemColors.card,
          borderRadius: AtemRadii.cardR,
          border: Border.all(color: AtemColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AtemTappable(
              onTap: onOpen,
              semanticLabel:
                  l10n.planCardA11y(plan.name, plan.exerciseCount, minutes),
              minTapSize: const Size(0, 48),
              pressBuilder: (context, pressed) => AnimatedContainer(
                duration: AtemMotion.duration(context, AtemMotion.fast),
                decoration: BoxDecoration(
                  boxShadow: pressed
                      ? AtemGlow.soft(AtemColors.tabStrength, opacity: 0.25)
                      : const [],
                ),
                child: _Body(
                  plan: plan,
                  image: image,
                  text: text,
                  textIsMeta: !hasDescription,
                  muscles: shown,
                ),
              ),
              child: _Body(
                plan: plan,
                image: image,
                text: text,
                textIsMeta: !hasDescription,
                muscles: shown,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: AtemButton.outline(
                label: l10n.sheetStart,
                semanticLabel: l10n.planCardStartA11y(plan.name),
                size: AtemButtonSize.compact,
                expand: true,
                onPressed: onStart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.plan,
    required this.image,
    required this.text,
    required this.textIsMeta,
    required this.muscles,
  });

  final Plan plan;
  final ImageProvider? image;
  final String text;

  /// Ohne Beschreibung steht die Metazeile („7 Übungen · ~45 min") an dieser
  /// Stelle — dann in der dritten Textstufe, nicht als Lesetext.
  final bool textIsMeta;
  final List<MuscleGroup> muscles;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: image != null
                ? Image(image: image!, fit: BoxFit.cover)
                : _DrawnCover(initials: PlanCard.initialsOf(plan.name)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                plan.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AtemType.titleMedium.of(context),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textIsMeta
                    ? AtemType.meta.of(context)
                    : AtemType.labelSmall.of(context),
              ),
              if (muscles.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    for (final m in muscles)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: m.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              m.label(l10n),
                              style: AtemType.meta.of(context),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Die gezeichnete Bildfläche — Verlauf, schräge Linien, Kürzel.
class _DrawnCover extends StatelessWidget {
  const _DrawnCover({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AtemColors.surfaceRaised,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AtemColors.tabStrength.withValues(alpha: 0.22),
            AtemColors.surfaceRaised,
          ],
        ),
      ),
      child: CustomPaint(
        painter: const _StripesPainter(),
        child: Center(
          child: Text(
            initials,
            // Die Schrift skaliert nicht mit: Das Kürzel ist Dekor, die
            // Fläche hat eine feste Höhe aus dem Seitenverhältnis.
            textScaler: TextScaler.noScaling,
            style: AtemType.valueLarge.of(context).copyWith(
                  fontSize: 34,
                  color: AtemColors.tabStrength.withValues(alpha: 0.85),
                  letterSpacing: 2,
                ),
          ),
        ),
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  const _StripesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AtemColors.textPrimary.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const gap = 14.0;
    final extent = size.width + size.height;
    for (var x = -size.height; x < extent; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripesPainter oldDelegate) => false;
}

/// Die seitliche Reihe der Plan-Karten.
///
/// Keine feste Höhe: Die Karten stehen in einer [Row] in einem horizontalen
/// Scroller und bestimmen die Höhe selbst — bei 200 % Schrift wächst die
/// Reihe mit, statt Text abzuschneiden.
class PlanCardRow extends StatelessWidget {
  const PlanCardRow({
    super.key,
    required this.plans,
    required this.onOpen,
    required this.onStart,
    this.musclesOf,
    this.horizontalPadding = AtemSpacing.screenPadding,
  });

  final List<Plan> plans;
  final ValueChanged<Plan> onOpen;
  final ValueChanged<Plan> onStart;
  final List<MuscleGroup> Function(Plan plan)? musclesOf;

  /// Das Polster des Bildschirms — die Reihe läuft bis an den Rand, beginnt
  /// aber bündig mit dem Inhalt darüber.
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.sizeOf(context).width;
        // Die nächste Karte ragt sichtbar an: höchstens 85 % der Breite.
        final width = math.min(PlanCard.defaultWidth, screen * 0.85);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          clipBehavior: Clip.none,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < plans.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                AtemEntrance(
                  index: i,
                  axis: AtemEntranceAxis.right,
                  child: PlanCard(
                    plan: plans[i],
                    width: width,
                    muscles: musclesOf?.call(plans[i]) ?? const [],
                    onOpen: () => onOpen(plans[i]),
                    onStart: () => onStart(plans[i]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
