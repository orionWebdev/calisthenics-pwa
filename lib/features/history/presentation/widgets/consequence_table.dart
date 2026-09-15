import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/session_consequence.dart';

/// Ob eine Veränderung in die gewünschte Richtung geht.
///
/// **Nicht „gut" und „schlecht".** Eine kürzere Pause ist besser, eine längere
/// schlechter — das ist keine Bewertung des Nutzers, sondern die Richtung, in
/// die diese eine Kennzahl gelesen wird. Bei Zählungen gibt es keine Richtung.
enum ConsequenceDirection {
  better,
  worse,
  neutral;

  Color get color => switch (this) {
        ConsequenceDirection.better => AtemColors.green,
        ConsequenceDirection.worse => AtemColors.magenta,
        ConsequenceDirection.neutral => AtemColors.textSecondary,
      };

  /// Das Wort, das im Vorlesetext steht. Ohne es trüge nur die Farbe die
  /// Richtung — Vertrag R6.
  String label(AppL10n l, {required bool isDuration}) => switch (this) {
        ConsequenceDirection.better =>
          isDuration ? l.directionShorter : l.directionBetter,
        ConsequenceDirection.worse => isDuration ? l.directionLonger : l.directionWorse,
        ConsequenceDirection.neutral => l.directionSame,
      };
}

/// Eine Zeile der Folgenvorschau.
@immutable
class ConsequenceRow {
  const ConsequenceRow({
    required this.label,
    required this.before,
    required this.after,
    this.direction = ConsequenceDirection.neutral,
    this.isDuration = false,
  });

  /// Eine Zählung: keine Richtung, nur Vorher und Nachher.
  factory ConsequenceRow.count({
    required String label,
    required int before,
    required int after,
  }) =>
      ConsequenceRow(
        label: label,
        before: '$before',
        after: '$after',
      );

  final String label;
  final String before;
  final String after;
  final ConsequenceDirection direction;

  /// Tage statt Punkte — dann heisst die Richtung „kürzer"/„länger".
  final bool isDuration;

  bool get changes => before != after;
}

/// Was eine Änderung anrichtet — **gerechnet, nicht gewarnt**.
///
/// ## Warum auch die unveränderten Zeilen dastehen
///
/// Das Board zeigt vier feste Kennzahlen, darunter solche, die sich nicht
/// bewegen („Längste Pause 74 → 74"). Das ist Absicht: Bei einer Änderung, die
/// Lücken verschiebt, ist „daran rührt es nicht" selbst eine Auskunft — und
/// eine Tabelle, deren Zeilen je nach Fall verschwinden, lässt sich zwischen
/// zwei Aufrufen nicht vergleichen.
///
/// ## Die Farbe steht nie allein
///
/// Lime für die gewünschte Richtung, Magenta für die andere, neutral für
/// Zählungen. Das Richtungswort steht im Vorlesetext — „von 50 Tagen auf 32
/// Tage, kürzer".
class ConsequenceTable extends StatelessWidget {
  const ConsequenceTable({super.key, required this.rows, this.note});

  final List<ConsequenceRow> rows;

  /// „Vorschau, noch nicht gespeichert." — steht nur beim Bearbeiten.
  final String? note;

  /// Die vier Zeilen beim **Bearbeiten** einer Einheit.
  static List<ConsequenceRow> forEditing(
    AppL10n l10n,
    SessionConsequence c,
    String monthLabel,
    int year,
    int month,
  ) {
    final (monthBefore, monthAfter) = c.monthCount(year, month);
    return [
      _days(l10n.sessionImpactPause, c.pauseBefore, c.pauseAfter, l10n),
      _days(l10n.sessionImpactLongest, c.longestBefore, c.longestAfter, l10n),
      _points(l10n.sessionImpactForm, c.formBefore, c.formAfter),
      ConsequenceRow.count(
        label: l10n.sessionImpactMonth(monthLabel),
        before: monthBefore,
        after: monthAfter,
      ),
    ];
  }

  /// Die vier Zeilen beim **Löschen** einer Einheit.
  static List<ConsequenceRow> forDeleting(
    AppL10n l10n,
    SessionConsequence c,
    String kindLabel,
    int kindBefore,
    int kindAfter,
  ) =>
      [
        ConsequenceRow.count(
          label: l10n.sessionImpactCount,
          before: c.sessionsBefore,
          after: c.sessionsAfter,
        ),
        _days(l10n.sessionImpactPause, c.pauseBefore, c.pauseAfter, l10n),
        _points(l10n.sessionImpactForm, c.formBefore, c.formAfter),
        ConsequenceRow.count(
          label: l10n.sessionImpactOfKind(kindLabel),
          before: kindBefore,
          after: kindAfter,
        ),
      ];

  /// Eine Zeitspanne. **Kürzer ist besser** — das ist die Leserichtung von
  /// „Pause", nicht ein Urteil über den Nutzer.
  static ConsequenceRow _days(
    String label,
    int? before,
    int? after,
    AppL10n l10n,
  ) =>
      ConsequenceRow(
        label: label,
        before: before == null ? l10n.commonNotAvailable : l10n.consequenceDays(before),
        after: after == null ? l10n.commonNotAvailable : l10n.consequenceDays(after),
        isDuration: true,
        direction: before == null || after == null || before == after
            ? ConsequenceDirection.neutral
            : (after < before ? ConsequenceDirection.better : ConsequenceDirection.worse),
      );

  /// Ein Punktwert. Mehr ist besser.
  static ConsequenceRow _points(String label, int? before, int? after) =>
      ConsequenceRow(
        label: label,
        before: before?.toString() ?? '—',
        after: after?.toString() ?? '—',
        direction: before == null || after == null || before == after
            ? ConsequenceDirection.neutral
            : (after > before ? ConsequenceDirection.better : ConsequenceDirection.worse),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.sessionImpactTitle,
            style: AtemType.labelMedium.of(context)),
        if (note case final text?) ...[
          const SizedBox(height: 4),
          Text(text, style: AtemType.meta.of(context)),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _Row(row: rows[i]),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row});

  final ConsequenceRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Semantics(
      // Eine Datenzeile ist **ein** Knoten, nicht vier — und das Richtungswort
      // steht darin, nicht nur in der Farbe.
      label: '${row.label}, ${l10n.consequenceStepA11y(
        row.label,
        row.before,
        row.after,
      )}, ${row.direction.label(l10n, isDuration: row.isDuration)}',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(row.label,
                  style: AtemType.labelSmall.of(context)),
            ),
            const SizedBox(width: 12),
            // Bei 200 % bricht die Zeile auf zwei — deshalb ein Wrap und
            // keine feste Aufteilung.
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Text(
                    row.before,
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(letterSpacing: 0),
                  ),
                  Text('→',
                      style: AtemType.labelMicro
                          .of(context)
                          .copyWith(letterSpacing: 0)),
                  Text(
                    row.after,
                    style: AtemType.labelMicro.of(context).copyWith(
                          letterSpacing: 0,
                          fontWeight: FontWeight.w700,
                          color: row.direction.color,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
