import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';

/// Eine Spur mit Füllung — **ein Material für alle fünf Zonen**.
///
/// Violett, immer in derselben Reihenfolge; unterschieden nur durch Platz,
/// Name und Minuten. Keine Farbskala von Grün nach Rot: Das wäre ein Urteil
/// („rot heisst zu viel" oder „endlich hart", je nach Tagesform), das die App
/// nicht fällen kann — und Farbe trägt hier ohnehin nichts (Board 16,
/// Entscheidung 7). Damit ist die Verteilung auch bei Farbfehlsichtigkeit
/// vollständig lesbar.
///
/// Violett ist **Fläche, nie Text**: Diese Spur trägt keine Schrift.
class ZoneTrack extends StatelessWidget {
  const ZoneTrack({super.key, required this.fraction, this.height = 10});

  /// 0 bis 1 — der Anteil an der aufgezeichneten Zeit.
  final double fraction;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth * fraction.clamp(0.0, 1.0);
            return SizedBox(
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // Das Board nennt #14161F. Gemeint ist das Spur-Token
                  // `track` (#16161F): Ein Zwischenton daneben wäre genau die
                  // „vierte Farbebene", die es nicht geben darf.
                  color: AtemColors.track,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AtemColors.violet,
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}
