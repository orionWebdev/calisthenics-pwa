import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Der Ton eines Bereichs — **Farbe als Ortsangabe, nicht als Aussage**.
///
/// Jeder Tab hat einen Ton (`AtemColors.tabHybrid` und Geschwister). Er tut
/// genau zwei Dinge: Er färbt das Symbol seines Platzes in der Leiste, und er
/// legt einen sehr schwachen Verlauf über den Bildschirmgrund.
///
/// ## Warum so schwach
///
/// Die App codiert mit Farbe bereits Bedeutung: Cyan sind Daten, Magenta ist
/// die Marke, Lime ist Erfolg, neun Töne sind Muskeln. Ein kräftiger
/// Bereichston käme als zehnte Bedeutung dazu und würde mit allen streiten.
/// Bei 6 % Deckkraft am oberen Rand, gegen null auslaufend, merkt man ihn beim
/// Umschalten und vergisst ihn beim Lesen — genau das ist der Auftrag.
///
/// Er ist **nie** der einzige Träger: Jeder Platz der Leiste trägt sein Wort,
/// jeder Bildschirm seine Überschrift.
class AtemTabTheme extends InheritedWidget {
  AtemTabTheme({
    super.key,
    required this.tone,
    required Widget child,
  }) : super(child: _Wash(tone: tone, child: child));

  final Color tone;

  /// Der Ton des umgebenden Bereichs, oder Cyan ausserhalb eines Tabs.
  static Color of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AtemTabTheme>()?.tone ??
      AtemColors.cyan;

  @override
  bool updateShouldNotify(AtemTabTheme old) => old.tone != tone;
}

/// Der Verlauf hinter dem Inhalt.
class _Wash extends StatelessWidget {
  const _Wash({required this.tone, required this.child});

  final Color tone;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tone.withValues(alpha: 0.06),
              tone.withValues(alpha: 0.015),
              AtemColors.base,
            ],
            // Der Ton sitzt oben, wo der Kopf steht, und ist auf halber Höhe
            // schon weg. Ein Verlauf über die volle Höhe färbte auch die
            // Fläche unter der Leiste — und die soll neutral bleiben.
            stops: const [0, 0.28, 0.62],
          ),
        ),
        child: child,
      );
}

/// Eine Karte, die den Ton ihres Bereichs trägt.
///
/// Für den einen Block je Bildschirm, der sich abheben darf — die
/// Regenerationskarte, die Wochenkachel. Zwei getönte Karten nebeneinander
/// heben sich gegenseitig auf.
class AtemToneCard extends StatelessWidget {
  const AtemToneCard({
    super.key,
    required this.child,
    this.tone,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;

  /// `null` nimmt den Ton des Bereichs.
  final Color? tone;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AtemTabTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AtemRadii.card),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.10),
            AtemColors.card,
          ],
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
