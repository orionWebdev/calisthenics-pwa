import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/history_summary.dart';
import '../../domain/training_session.dart';
import '../history_zone_ui.dart';
import '../session_ui.dart';
import 'acwr_scale.dart';

/// Die Aussage-Karte: **ein Satz zuerst**, die Zahlen als Begründung darunter.
///
/// Sie ist die einzige hervorgehobene Karte des Bildschirms. Der Satz kommt aus
/// dem Abstand zur letzten Einheit, nicht aus dem Form-Wert: Der Abstand ist
/// eine gemessene Tatsache, der Form-Wert eine Rechnung mit fünf Bestandteilen.
/// Wer seit fünfzig Tagen nicht trainiert hat, soll das lesen und nicht erst
/// eine 16 deuten müssen.
///
/// ## Was in der Karte steht — Board 06, A1
///
/// Zonen-Dot mit Wort · Kennzahl gross in Mono · „Zuletzt …" · Form mit
/// Richtung · im Rhythmus die ACWR-Skala · Trennlinie · **Training starten**.
/// Der Start-Knopf steht in jeder Zone — auch bei 50 Tagen Pause ist er die
/// Antwort auf die Aussage, nicht eine Aufforderung daneben.
///
/// ## Gleiche Höhe über alle vier Zonen
///
/// Der längste der vier Sätze wird **gemessen** und seine Höhe reserviert.
/// Ergebnis: über die Zonen stabil, mit der Schriftgröße wachsend.
class StatementCard extends StatelessWidget {
  const StatementCard({super.key, required this.summary, this.onStart});

  final HistorySummary summary;

  /// Der Weg in den Runner. Ohne Rückruf — etwa in einer Vorschau — fehlt
  /// der Knopf; im Kraft-Tab ist er immer da.
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final zone = summary.zone;
    final days = summary.daysSinceLast ?? 0;

    final statement = summary.showsFrequency
        ? l10n.historyLeadFrequency(
            summary.sessionsInWindow!, summary.windowDays!)
        : l10n.historyLeadGap(days);
    final last = summary.lastSession;
    final acwr = summary.acwr?.acwr;

    return AtemCard.gradientBorder(
      glow: zone.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            // Ein zusammenhängendes Label: Zone zuerst, dann Satz, dann die
            // Begründung — Farbe wird nicht vorgelesen (G).
            header: true,
            label: [
              zone.label(l10n),
              statement,
              if (last != null) _lastLine(context, l10n, last),
            ].join('. '),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AtemStatusDot(color: zone.color),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          zone.label(l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AtemType.labelUi.of(context).copyWith(
                                color: zone.color,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Statement(
                    text: statement,
                    // Alle vier Möglichkeiten, damit die Höhe nicht an der
                    // aktuellen Zone hängt.
                    candidates: [
                      statement,
                      l10n.historyLeadGap(999),
                      l10n.historyLeadGap(1),
                      l10n.historyLeadFrequency(99, 14),
                    ],
                  ),
                  if (last != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _lastLine(context, l10n, last),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AtemType.meta.of(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Die Skala nur im Rhythmus: Bei 50 Tagen Pause wäre der Wert 0,00
          // und täuschte eine Aussage vor (Entscheidung 07).
          if (acwr != null) ...[
            const SizedBox(height: 14),
            AcwrScale(acwr: acwr),
          ],
          if (onStart != null) ...[
            const SizedBox(height: 14),
            const _Rule(),
            const SizedBox(height: 12),
            AtemButton.gradient(
              label: l10n.workoutsStart,
              semanticLabel: l10n.workoutsStart,
              size: AtemButtonSize.compact,
              onPressed: onStart,
            ),
          ],
        ],
      ),
    );
  }

  /// „Zuletzt Di 08.07. · Laufen 8,2 km" — die letzte Einheit mit dem, was
  /// sie ausmacht.
  static String _lastLine(
      BuildContext context, AppL10n l10n, TrainingSession last) {
    final tag = languageTag(context);
    var name = sessionName(l10n, last);
    if (last case CardioSession(distanceKm: final km?)) {
      name = '$name ${l10n.unitKilometers(km.toStringAsFixed(1))}';
    }
    return l10n.historyLeadLast(
      DateFormat.E(tag).format(last.date),
      DateFormat.Md(tag).format(last.date),
      name,
    );
  }
}

/// Die Trennlinie #232334 zwischen Aussage und Aktion.
class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: AtemColors.border);
}

/// Der Satz — **mit der Kennzahl gross in Mono**.
///
/// Board 06: „Kennzahl Mono 38/700". Die erste Zahl im Satz ist die
/// Kennzahl („50 Tage ohne Training", „7 Einheiten in 14 Tagen"); sie
/// bekommt die Wertrolle, der Rest bleibt Satz. Reserviert wird die Höhe des
/// längsten Kandidaten, damit die Karte beim Zonenwechsel nicht springt.
class _Statement extends StatelessWidget {
  const _Statement({required this.text, required this.candidates});

  final String text;
  final List<String> candidates;

  static final _number = RegExp(r'\d+');

  TextSpan _span(BuildContext context, String s) {
    final match = _number.firstMatch(s);
    final base = AtemType.titleLarge.of(context);
    final value = AtemType.valueLarge.of(context).copyWith(
          fontSize: 38,
          color: AtemColors.textPrimary,
        );
    if (match == null) return TextSpan(text: s, style: base);
    return TextSpan(children: [
      if (match.start > 0)
        TextSpan(text: s.substring(0, match.start), style: base),
      TextSpan(text: match.group(0), style: value),
      TextSpan(text: s.substring(match.end), style: base),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaler = MediaQuery.textScalerOf(context);
        var tallest = 0.0;
        for (final candidate in candidates) {
          final painter = TextPainter(
            text: _span(context, candidate),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
            maxLines: 3,
          )..layout(maxWidth: constraints.maxWidth);
          tallest = math.max(tallest, painter.height);
        }
        return SizedBox(
          height: tallest,
          width: double.infinity,
          child: Text.rich(
            _span(context, text),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
