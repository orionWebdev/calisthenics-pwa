import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/presentation/muscle_ui.dart';
import '../../domain/muscle_balance.dart';

/// Die Muskelbalance im Workouts-Tab — **Verteilung und Abstand, kein Urteil**.
///
/// ## Was hier ausdrücklich nicht steht
///
/// Ob die Verteilung richtig ist. Es gibt kein hinterlegtes Sollverhältnis,
/// also auch kein „zu wenig". Der Block zeigt zwei überprüfbare Dinge: welchen
/// Anteil ein Muskel an den Sätzen hatte, und wie lange sein letzter her ist.
/// Was daraus folgt, weiß der Nutzer und nicht die App.
///
/// ## Der Nenner steht über dem Balken
///
/// „268 Sätze · 14 von 18 Kraft-Einheiten". Die Balance rechnet über
/// Krafteinheiten **mit Übungen**; Cardio, Regeneration und die 16
/// Krafteinheiten ohne Übungsliste tragen nichts bei. Eine Verteilung, die
/// sich als Verteilung über das ganze Training ausgäbe, wäre eine Behauptung.
class MuscleBalanceCard extends StatelessWidget {
  const MuscleBalanceCard({super.key, required this.balance});

  final MuscleBalance balance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    // Unter der Schwelle ein Fortschrittsbalken statt einer Verteilung. Aus
    // drei Einheiten eine Balance zu zeichnen hiesse, drei Tage zu einer
    // Aussage über acht Wochen zu machen.
    if (!balance.hasEnough) return _Thin(balance: balance);

    final total = balance.totalSets;

    return AtemCard.list(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.balanceTitle,
                    style: AtemType.titleMedium.of(context)),
              ),
              const SizedBox(width: 10),
              Text(l10n.balanceWindow,
                  style: AtemType.meta.of(context)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.balanceBasis(
              total,
              balance.sessionsCounted,
              balance.sessionsInWindow,
            ),
            style: AtemType.meta.of(context),
          ),
          const SizedBox(height: 12),
          _Bar(balance: balance, total: total),
          const SizedBox(height: 14),
          for (final share in balance.shares)
            if (share.sets > 0)
              _Row(share: share, total: total),
          // **Die Spaltenüberschrift steht unten** (Board 09, A3/1). Oben
          // wäre sie ein Versprechen auf eine Tabelle; unten beantwortet sie
          // die Frage, die beim Lesen entsteht: was waren die drei Zahlen?
          const SizedBox(height: 10),
          const SizedBox(
              height: 1,
              child: ColoredBox(color: AtemColors.border)),
          const SizedBox(height: 8),
          ExcludeSemantics(
            child: Text(
              [
                l10n.balanceColShare,
                l10n.balanceColSets,
                l10n.balanceColLast,
              ].join('  ').toUpperCase(),
              style: AtemType.labelMicro.of(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// „Längste Abstände" — **eigene Karte** (Board 09, A3/1).
///
/// Zwei Aussagen aus derselben Grundlage: Anteil ist relativ, Abstand ist
/// absolut. Sie in einer Karte zu stapeln liest sich wie eine Fortsetzung
/// der Anteilstabelle; es ist aber eine andere Frage.
class MuscleGapsCard extends StatelessWidget {
  const MuscleGapsCard({super.key, required this.balance});

  final MuscleBalance balance;

  @override
  Widget build(BuildContext context) {
    if (balance.longestGaps.isEmpty) return const SizedBox.shrink();
    final l10n = AppL10n.of(context);

    return AtemCard.list(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Ein Dreieck aus Zeichen statt einem Material-Symbol: Die
              // Karte importiert sonst nur `widgets`.
              ExcludeSemantics(
                child: Text('△',
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(color: AtemColors.textSecondary)),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(l10n.balanceGapsTitle.toUpperCase(),
                    style: AtemType.labelMicro.of(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Gaps(gaps: balance.longestGaps),
          const SizedBox(height: 10),
          Text(l10n.balanceGapsNote, style: AtemType.meta.of(context)),
        ],
      ),
    );
  }
}

/// Neun Segmente, ein Knoten.
///
/// Der Balken ist **ein** Semantics-Element mit der ganzen Verteilung im
/// Label — neun einzelne Knoten wären neun Zahlen ohne Beziehung.
class _Bar extends StatelessWidget {
  const _Bar({required this.balance, required this.total});

  final MuscleBalance balance;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final parts = [
      for (final share in balance.shares)
        if (share.sets > 0) share,
    ];

    final spoken = parts
        .map((s) => '${s.muscle.label(l10n)} '
            '${(s.sets / total * 100).round()}${l10n.commonPercentSign}')
        .join(', ');

    return Semantics(
      image: true,
      label: '${l10n.balanceColShare}: $spoken',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 12,
          child: Row(
            children: [
              for (var i = 0; i < parts.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Expanded(
                  // Ein Prozent bleibt sichtbar: Der Anteil bestimmt das
                  // Gewicht, ein Mindestmaß verhindert das Verschwinden.
                  flex: (parts[i].sets * 100 ~/ total).clamp(3, 100),
                  child: Container(
                    decoration: BoxDecoration(
                      color: parts[i].muscle.color,
                      borderRadius: BorderRadius.circular(AtemRadii.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.share, required this.total});

  final MuscleShare share;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final percent = (share.sets / total * 100).round();
    final days = share.lastSetDaysAgo;
    final name = share.muscle.label(l10n);

    return Semantics(
      // Eine Zeile ist ein Knoten. Kein Knopf — es gibt kein Muskeldetail.
      label: '$name, $percent${l10n.commonPercentSign}, '
          '${l10n.balanceColSets} ${share.sets}'
          '${days == null ? '' : ', ${l10n.balanceLastDaysLong(days)}'}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              ExcludeSemantics(
                child: AtemStatusDot(color: share.muscle.color),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AtemType.labelSmall
                      .of(context)
                      .copyWith(color: share.muscle.color),
                ),
              ),
              const SizedBox(width: 8),
              // Drei Zahlenspalten, jede für sich schmal und nicht umbrechend
              // — sonst tanzen sie bei jeder Zeile an anderer Stelle.
              _Cell(text: '$percent${l10n.commonPercentSign}', bold: true),
              _Cell(text: '${share.sets}'),
              _Cell(
                text: days == null
                    ? l10n.commonNotAvailable
                    : l10n.balanceLastDays(days),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.text, this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          text,
          maxLines: 1,
          style: AtemType.labelMicro.of(context).copyWith(
                letterSpacing: 0,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color:
                    bold ? AtemColors.textPrimary : AtemColors.textSecondary,
              ),
        ),
      );
}

/// Die drei längsten Abstände.
class _Gaps extends StatelessWidget {
  const _Gaps({required this.gaps});

  final List<MuscleShare> gaps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final longest = gaps.first.lastSetDaysAgo ?? 1;

    return Column(
      children: [
        for (final gap in gaps)
          Semantics(
            label: '${gap.muscle.label(l10n)}, '
                '${l10n.balanceLastDaysLong(gap.lastSetDaysAgo ?? 0)}',
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 74,
                      child: Text(
                        gap.muscle.label(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AtemType.labelMicro.of(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AtemRadii.pill),
                        child: SizedBox(
                          height: 6,
                          // Länge relativ zum längsten Abstand, **nicht** zu
                          // einem Sollwert — den gibt es nicht.
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor:
                                  ((gap.lastSetDaysAgo ?? 0) / longest)
                                      .clamp(0.05, 1.0),
                              child: Container(
                                color: gap.muscle.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.balanceLastDaysLong(gap.lastSetDaysAgo ?? 0),
                      style: AtemType.labelMicro
                          .of(context)
                          .copyWith(letterSpacing: 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Unter der Schwelle: **wie weit es noch ist**, nicht eine Absage.
class _Thin extends StatelessWidget {
  const _Thin({required this.balance});

  final MuscleBalance balance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final done = balance.sessionsCounted;
    const target = MuscleBalance.minimumSessions;

    return AtemCard.list(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.balanceTitle, style: AtemType.labelMedium.of(context)),
          const SizedBox(height: 6),
          Text(l10n.balanceThin(done, target),
              style: AtemType.labelSmall.of(context)),
          const SizedBox(height: 12),
          AtemProgressBar.share(
            value: (done / target).clamp(0.0, 1.0),
            // Rolle Fortschrittsbalken: Der Wert bewegt sich von allein,
            // niemand kann ihn bedienen.
            semanticLabel: l10n.balanceThin(done, target),
            accent: AtemColors.cyan,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.balanceThinProgress(done, target, target - done),
            style: AtemType.meta.of(context),
          ),
        ],
      ),
    );
  }
}
