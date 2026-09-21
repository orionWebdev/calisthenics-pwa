import 'package:flutter/material.dart' show Icons, MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../../exercises/presentation/muscle_ui.dart';
import '../../application/history_providers.dart';
import '../../domain/muscle_balance.dart';
import '../screens/muscle_balance_screen.dart';

/// Ab dieser effektiven Schriftgrösse wird eine Muskelzeile zweizeilig
/// (Board 09, A3/3): Name oben, Werte als umbrechende Reihe darunter.
const double _stackedFromScale = 1.6;

/// Der Einstieg in die Muskelbalance — **Kachel, Laden, Fehler in einem**.
///
/// Kraft-Tab und Auswertung binden dieselbe Kachel ein; die Details stehen an
/// genau einer Stelle, der Unterseite [MuscleBalanceScreen]. Zwei volle
/// Tabellen an zwei Orten wären zwei Stellen, die auseinanderlaufen.
///
/// Ein Fehler lässt den Block wegfallen, statt eine Fehlerkarte zu zeigen: Die
/// Kachel ist ein Einstieg, keine Aussage — der Fehlerzustand gehört auf die
/// Unterseite, wo die Aussage steht.
class MuscleBalanceEntry extends ConsumerWidget {
  const MuscleBalanceEntry({
    super.key,
    this.alwaysShow = false,
    this.compact = false,
  });

  /// Siehe [MuscleBalanceTile.alwaysShow].
  final bool alwaysShow;

  /// Siehe [MuscleBalanceTile.compact].
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final sessions = ref.watch(sessionsProvider);
    final exercises = ref.watch(exercisesProvider);

    if (sessions.isLoading && !sessions.hasValue) {
      return AtemSkeleton(
        semanticLabel: l10n.balanceLoading,
        blocks: const [AtemSkeletonBlock(height: 104)],
      );
    }
    if (sessions.hasError && !sessions.hasValue) {
      return const SizedBox.shrink();
    }

    final balance = MuscleBalance.compute(
      sessions.value ?? const [],
      exercises.value ?? const [],
      ref.watch(historyReferenceProvider),
    );
    return MuscleBalanceTile(
      balance: balance,
      alwaysShow: alwaysShow,
      compact: compact,
    );
  }
}

/// Die kompakte Kachel (Board 11, A1): Titel, Fenster, Segmentbalken,
/// Grundlage — die ganze Fläche öffnet die Unterseite.
class MuscleBalanceTile extends StatelessWidget {
  const MuscleBalanceTile({
    super.key,
    required this.balance,
    this.onOpen,
    this.alwaysShow = false,
    this.asPanel = false,
    this.compact = false,
  });

  final MuscleBalance balance;

  /// Auch ohne Einheit im Fenster rendern — dann als dünner Zustand „0 / 8".
  ///
  /// Auf Auswertungsbildschirmen rendert jeder Block immer (CLAUDE.md, seit
  /// 16.09.2026); im Kraft-Tab gilt weiter: ohne Daten kein Block.
  final bool alwaysShow;

  /// In der Auswertung liegt der Block auf der Blockfläche
  /// ([AtemAnalysisPanel]) statt als Karte — und unter seiner Schwelle ist er
  /// der gesperrte Block aus Board 13, ohne Tap-Ziel.
  final bool asPanel;

  /// Ohne Rückruf öffnet die Kachel [MuscleBalanceScreen] auf dem nächsten
  /// Navigator — im Kraft-Tab ist das der Stapel des Tabs.
  final VoidCallback? onOpen;

  /// In halber Breite, als eine Hälfte einer [AtemSplit].
  ///
  /// Das Fenster („8 Wochen") fällt aus dem Kopf: Neben einem Titel und einem
  /// Pfeil bleiben auf 145 dp keine weiteren Wörter. Es steht weiterhin im
  /// Kopf der Unterseite und in der Ansage. Die Grundlage bleibt — eine
  /// Verteilung ohne ihren Nenner gibt es nicht, auch nicht auf halber
  /// Breite; sie bricht dort einfach um.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Kein Bestand im Fenster: ausserhalb von Auswertungen rendert der Block
    // nicht. Kein „Leg los!".
    if (balance.sessionsInWindow == 0 && !alwaysShow) {
      return const SizedBox.shrink();
    }

    final l10n = AppL10n.of(context);
    final enough = balance.hasEnough;
    final done = balance.sessionsCounted;
    const target = MuscleBalance.minimumSessions;

    // In der Auswertung, unter der Schwelle: der gesperrte Block. Er hat
    // keine Handlung, also auch kein Tap-Ziel — die Unterseite zeigt
    // dieselbe leere Verteilung.
    if (asPanel && !enough) {
      return AtemThresholdBlock(
        title: l10n.balanceTitle,
        condition: l10n.balanceCondition(target),
        current: done,
        required: target,
        accent: AtemColors.tabStrength,
        shape: AtemThresholdShape.bars,
      );
    }

    final basis = enough
        ? l10n.balanceBasis(balance.totalSets, done, balance.sessionsInWindow)
        : l10n.balanceThinProgress(done, target, target - done);

    return AtemTappable(
      onTap: onOpen ??
          () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MuscleBalanceScreen(),
                ),
              ),
      semanticLabel: [
        l10n.balanceTileA11y(l10n.balanceTitle, basis, l10n.balanceWindow),
        l10n.listOpenDetail,
      ].join(', '),
      pressScale: AtemPressScale.normal,
      child: _surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Derselbe Kopf wie jeder Block (seit 17.09.2026): Titel ohne
            // Umbruch, „8 Wochen" und Pfeil rechtsbündig. Vorher brach der
            // Titel am Gerät mitten im Wort („Muskelbalanc / e"). Kein ⓘ —
            // die Kachel öffnet ohnehin die Unterseite.
            // Auf halber Breite das Rezept der Blocküberschrift: labelMicro
            // in Versalien, wie „ERFASSTE EINHEITEN" daneben. Der grosse
            // Titel brach dort mitten im Wort („Muskelbalan / ce"), und zwei
            // Kopfrezepte nebeneinander sähen gewachsen aus statt
            // entschieden (Board 13).
            if (compact)
              Row(
                children: [
                  Expanded(
                    // Kurztitel: „MUSKELBALANCE" bricht auf 145 dp in
                    // Versalien mitten im Wort, und Verkleinern kommt nicht
                    // in Frage. Der volle Name steht in der Ansage und im
                    // Kopf der Unterseite.
                    child: Text(l10n.balanceTitleShort.toUpperCase(),
                        style: AtemType.labelMicro.of(context)),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AtemColors.textSecondary),
                ],
              )
            else
              AtemExplainHeader(
                title: l10n.balanceTitle,
                trailing: l10n.balanceWindow,
                explanation: const [],
                // Der Pfeil sagt, dass die Kachel sich öffnet — die Ansage
                // sagt es in Worten.
                action: const Icon(Icons.chevron_right,
                    size: 20, color: AtemColors.textSecondary),
              ),
            SizedBox(height: compact ? 10 : 12),
            if (enough)
              _Bar(balance: balance, total: balance.totalSets)
            else
              AtemProgressBar.share(
                value: (done / target).clamp(0.0, 1.0),
                semanticLabel: basis,
                accent: AtemColors.tabStrength,
              ),
            const SizedBox(height: 10),
            Text(basis, style: AtemType.meta.of(context)),
          ],
        ),
      ),
    );
  }

  /// Auswertung: Blockfläche. Verlauf: Listenkarte.
  Widget _surface({required Widget child}) => asPanel
      ? AtemAnalysisPanel(accent: AtemColors.tabStrength, child: child)
      : AtemCard.list(child: child);
}

/// Die Muskelbalance im Detail — **Verteilung und Abstand, kein Urteil**.
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
/// Krafteinheiten **mit Übungen**; Cardio, Regeneration und Krafteinheiten
/// ohne Übungsliste tragen nichts bei. Eine Verteilung, die sich als
/// Verteilung über das ganze Training ausgäbe, wäre eine Behauptung.
///
/// Das Fenster („8 Wochen") steht im Kopf der Unterseite, nicht in der Karte
/// (Board 09, A3/1).
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
    final rows = [
      for (final share in balance.shares)
        if (share.sets > 0) share,
    ];

    return AtemCard.list(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Seit 17.09.2026: Was die Verteilung zählt und dass sie kein
          // Sollverhältnis ist, steht hinter dem ⓘ. Sichtbar bleibt die
          // Grundlage mit Nenner.
          AtemExplainHeader(
            title: l10n.balanceTitle,
            explanation: [l10n.balanceExplain],
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
          const SizedBox(height: 14),
          _Bar(balance: balance, total: total),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const SizedBox(
                  height: 1, child: ColoredBox(color: AtemColors.border)),
            _Row(share: rows[i], total: total),
          ],
          // **Die Spaltenüberschrift steht unten** (Board 09, A3/1). Oben
          // wäre sie ein Versprechen auf eine Tabelle; unten beantwortet sie
          // die Frage, die beim Lesen entsteht: was waren die drei Zahlen?
          const SizedBox(height: 6),
          const SizedBox(
              height: 1, child: ColoredBox(color: AtemColors.border)),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Text(
              [
                l10n.balanceColShare,
                l10n.balanceColSets,
                l10n.balanceColLast,
              ].join('   ').toUpperCase(),
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
    if (!balance.hasEnough || balance.longestGaps.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppL10n.of(context);

    return AtemCard.list(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // „Abstand seit dem letzten Satz… Kein Sollwert" steht seit
          // 17.09.2026 hinter dem ⓘ — sichtbar bleiben Muskel und Tage.
          AtemExplainHeader(
            title: l10n.balanceGapsTitle,
            explanation: [l10n.balanceGapsNote],
          ),
          const SizedBox(height: 10),
          _Gaps(gaps: balance.longestGaps),
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
          height: 14,
          child: Row(
            children: [
              for (var i = 0; i < parts.length; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Expanded(
                  // Ein Mindestmaß verhindert das Verschwinden kleiner
                  // Anteile; das Gewicht bleibt der Anteil.
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
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) >= _stackedFromScale;

    final nameText = Text(
      name,
      maxLines: stacked ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: AtemType.titleSmallOrDefault(context)
          .copyWith(color: share.muscle.color),
    );
    final dot = AtemStatusDot(color: share.muscle.color);

    final percentText = _Value(
      text: '$percent${l10n.commonPercentSign}',
      strong: true,
    );
    final setsText = _Value(text: l10n.balanceSetsShort(share.sets));
    final lastText = _Value(
      text: days == null ? l10n.commonNotAvailable : l10n.balanceLastDays(days),
    );

    return Semantics(
      // Eine Zeile ist ein Knoten. Kein Knopf — es gibt kein Muskeldetail.
      label: '$name, $percent${l10n.commonPercentSign}, '
          '${l10n.balanceColSets} ${share.sets}'
          '${days == null ? '' : ', ${l10n.balanceLastDaysLong(days)}'}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: stacked
              // Ab 160 %: Name oben, Werte als umbrechende Reihe darunter.
              // Der Punkt bleibt neben dem Namen — die Zuordnung läuft nicht
              // nur über die Textfarbe.
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        dot,
                        const SizedBox(width: 10),
                        Expanded(child: nameText),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 2,
                        children: [percentText, setsText, lastText],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    dot,
                    const SizedBox(width: 10),
                    Expanded(child: nameText),
                    const SizedBox(width: 8),
                    // Drei Zahlenspalten mit fester Mindestbreite und
                    // rechtsbündig — sonst tanzen sie von Zeile zu Zeile.
                    _Column(width: 44, child: percentText),
                    _Column(width: 44, child: setsText),
                    _Column(width: 40, child: lastText),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(minWidth: width),
        child: Align(alignment: Alignment.centerRight, child: child),
      );
}

class _Value extends StatelessWidget {
  const _Value({required this.text, this.strong = false});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: AtemType.labelMicro.of(context).copyWith(
              letterSpacing: 0,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              // Drei Textstufen: der Anteil ist der Wert der Zeile (Weiss),
              // Sätze und Abstand sind Beschriftung (#94A3B8).
              color: strong ? AtemColors.textPrimary : AtemColors.textSecondary,
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
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) >= _stackedFromScale;

    return Column(
      children: [
        for (final gap in gaps)
          Semantics(
            label: '${gap.muscle.label(l10n)}, '
                '${l10n.balanceLastDaysLong(gap.lastSetDaysAgo ?? 0)}',
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _GapRow(
                  gap: gap,
                  longest: longest,
                  stacked: stacked,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow({
    required this.gap,
    required this.longest,
    required this.stacked,
  });

  final MuscleShare gap;
  final int longest;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final days = gap.lastSetDaysAgo ?? 0;

    final name = Text(
      gap.muscle.label(l10n),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AtemType.labelUi
          .of(context)
          .copyWith(color: gap.muscle.color, fontSize: 14),
    );
    final value = Text(
      l10n.balanceGapDays(days),
      maxLines: 1,
      softWrap: false,
      style: AtemType.labelMicro.of(context).copyWith(
            letterSpacing: 0,
            fontWeight: FontWeight.w700,
            color: AtemColors.textPrimary,
          ),
    );
    // Länge relativ zum längsten Abstand, **nicht** zu einem Sollwert — den
    // gibt es nicht.
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(AtemRadii.pill),
      child: SizedBox(
        height: 6,
        child: ColoredBox(
          color: AtemColors.track,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (days / longest).clamp(0.05, 1.0),
              heightFactor: 1,
              child: ColoredBox(color: gap.muscle.color),
            ),
          ),
        ),
      ),
    );

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: name),
            const SizedBox(width: 8),
            value
          ]),
          const SizedBox(height: 6),
          bar,
        ],
      );
    }

    return Row(
      children: [
        SizedBox(width: 96, child: name),
        const SizedBox(width: 8),
        Expanded(child: bar),
        const SizedBox(width: 12),
        value,
      ],
    );
  }
}

/// Unter der Schwelle: **wie weit es noch ist**, nicht eine Absage
/// (Board 09, A3/2).
class _Thin extends StatelessWidget {
  const _Thin({required this.balance});

  final MuscleBalance balance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final done = balance.sessionsCounted;
    const target = MuscleBalance.minimumSessions;

    return AtemCard.list(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Seit 17.09.2026: Warum hier keine Verteilung steht, erklärt das ⓘ.
          // Sichtbar bleiben der eine Satz zur Lage, Balken und Nenner.
          AtemExplainHeader(
            title: l10n.balanceTitle,
            explanation: [l10n.balanceThinNote],
          ),
          const SizedBox(height: 10),
          Text(l10n.balanceThin(done, target),
              style: AtemType.labelSmall.of(context)),
          const SizedBox(height: 14),
          AtemProgressBar.share(
            value: (done / target).clamp(0.0, 1.0),
            // Rolle Fortschrittsbalken: Der Wert bewegt sich von allein,
            // niemand kann ihn bedienen.
            semanticLabel:
                l10n.balanceThinProgress(done, target, target - done),
            accent: AtemColors.cyan,
          ),
          const SizedBox(height: 10),
          ExcludeSemantics(
            child: Text(
              l10n.balanceThinProgress(done, target, target - done),
              style: AtemType.meta.of(context),
            ),
          ),
        ],
      ),
    );
  }
}
