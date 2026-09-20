import 'package:flutter/material.dart' show MaterialPageRoute;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../history/application/history_providers.dart';
import '../../../settings/application/settings_providers.dart';
import '../../application/weight_providers.dart';
import '../../domain/weight_entry.dart';
import '../../domain/weight_series.dart';
import '../screens/weight_history_screen.dart';
import '../weight_ui.dart';
import 'weight_chart.dart';
import 'weight_entry_sheet.dart';

/// **Gewicht** — der Verlaufsblock im Hybrid-Tab (Board 14, Abschnitt A).
///
/// ## Der Satz, an dem alles gemessen wird
///
/// Der Block zeigt, was war — nie, was sein soll. Eine Veränderung ist eine
/// Tatsache mit Richtungsglyph, nie eine Farbe; eine Lücke ist eine Lücke, nie
/// eine gerade Linie.
///
/// ## Warum er rendert, auch wenn fast nichts da ist
///
/// Die allgemeine Regel lautet: Ein Block ohne Daten rendert nicht, der
/// Bildschirm hört früher auf (Modul 5). Hier gilt sie **bewusst nicht**
/// (Entscheidung 7): Das Onboarding verlangt ein Körpergewicht, jedes Profil
/// kennt also mindestens einen Wert — „keine Daten" ist datenseitig kaum
/// möglich, und ohne den Block gäbe es keinen Weg zum ersten Verlaufseintrag.
///
/// Kennt das Profil wirklich keinen Wert (Vorschau, Test, abgebrochenes
/// Onboarding), rendert er doch nicht: Eine leere Karte mit einem Aufruf wäre
/// genau die Platzhalterkarte, die Modul 5 verboten hat.
///
/// ## Das Fenster der Karte
///
/// Drei Monate (Entscheidung 3) — **solange darin eine Kurve steht**. Liegen
/// alle Einträge länger zurück, zeigt die Karte die ganze Reihe und schreibt
/// „ALLE" in die Kopfzeile. Ein Fenster zu behaupten, in dem nichts liegt,
/// hiesse, einen Verlauf zu verstecken, den es gibt.
class WeightCard extends ConsumerWidget {
  const WeightCard({super.key});

  /// Ob der Block überhaupt etwas zu zeigen hat.
  ///
  /// **Solange etwas lädt, lautet die Antwort ja.** Der Wert kommt aus zwei
  /// Strömen — der Reihe und dem Profil —, und sie treffen nicht gleichzeitig
  /// ein. Wer nur den einen fragt, lässt den Block in dem Augenblick
  /// verschwinden, in dem der andere noch unterwegs ist: erst weg, dann
  /// plötzlich da, und die halbe Seite springt.
  static bool hasData(WidgetRef ref) {
    if (_loadingNow(ref)) return true;
    return ref.watch(latestWeightProvider) != null;
  }

  static bool _loadingNow(WidgetRef ref) =>
      ref.watch(weightSeriesProvider).isLoading ||
      ref.watch(settingsProvider).isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(weightSeriesProvider);

    // Das Ladegate fragt **beide** Quellen. Fragte es nur die Reihe, stünde
    // bei geladener Reihe und ladendem Profil ein leerer Platz da, wo
    // [hasData] gerade noch einen Block versprochen hat.
    if (_loadingNow(ref)) return _loading();

    return async.when(
      loading: _loading,
      error: (_, __) => _Error(
        latest: ref.watch(latestWeightProvider),
        // Ein Profilwert hat kein Datum. „Zuletzt bekannt · 1. Januar" wäre
        // ein erfundenes — am Probelauf sichtbar geworden (20.09.2026).
        dated: !ref.watch(weightIsUnseededProvider),
      ),
      data: (series) {
        final latest = ref.watch(latestWeightProvider);
        if (latest == null) return const SizedBox.shrink();

        // Der Stichtag kommt aus dem Verlauf, nicht aus `DateTime.now()`:
        // Sonst rechnete die Karte gegen einen anderen Tag als jede Zahl
        // daneben, sobald ein Test oder eine Vorschau ihn setzt.
        final reference = ref.watch(historyReferenceProvider);
        final window = _windowFor(series, reference);
        return _Block(
          series: series,
          window: window.series,
          range: window.range,
          latest: latest,
          reference: reference,
          unseeded: ref.watch(weightIsUnseededProvider),
          l10n: l10n,
        );
      },
    );
  }

  /// Das gezeigte Fenster: drei Monate, sonst alles.
  static ({WeightSeries series, WeightRange range}) _windowFor(
    WeightSeries series,
    DateTime reference,
  ) {
    final quarter = series.within(WeightRange.threeMonths, reference);
    if (quarter.length >= 2) {
      return (series: quarter, range: WeightRange.threeMonths);
    }
    return (series: series, range: WeightRange.all);
  }

  /// A5 — Skelett in Inhaltsform. Die Titelzeile bleibt sofort stehen: Sie
  /// braucht keine Daten, und ohne sie wanderte der ganze Block beim Eintreffen
  /// der Zahlen um seine eigene Höhe.
  static Widget _loading() => Builder(
        builder: (context) {
          final l10n = AppL10n.of(context);
          return AtemCard.list(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.weightBlockTitle,
                    style: AtemType.titleSmallOrDefault(context)),
                const SizedBox(height: 10),
                AtemSkeleton(
                  semanticLabel: l10n.weightLoadingA11y,
                  blocks: const [
                    AtemSkeletonBlock(height: 22, radius: 6),
                    AtemSkeletonBlock(
                        height: WeightChart.compactHeight, radius: 12),
                  ],
                ),
              ],
            ),
          );
        },
      );
}

/// A6 — der zuletzt bekannte Wert bleibt gedimmt stehen.
///
/// Er ist ja nicht falsch, nur nicht mehr bestätigt frisch. Ihn zu entfernen
/// hiesse, aus einem Netzfehler eine gelöschte Zahl zu machen.
class _Error extends ConsumerWidget {
  const _Error({required this.latest, required this.dated});

  final WeightEntry? latest;

  /// Ob [latest] ein echter Verlaufseintrag ist. Der Profilwert trägt kein
  /// Datum — dann fehlt die Zeile, statt eines zu erfinden.
  final bool dated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final known = latest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (known != null)
          Opacity(
            opacity: 0.55,
            child: AtemCard.list(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.weightBlockTitle,
                      style: AtemType.titleSmallOrDefault(context)),
                  const SizedBox(height: 10),
                  _Value(kg: known.kg),
                  if (dated) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.weightLastKnown(
                          WeightUi.shortDate(context, known.date)),
                      style: AtemType.labelMicro.of(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (known != null) const SizedBox(height: 8),
        AtemNotice(
          title: l10n.weightLoadError,
          body: '',
          semanticLabel: l10n.weightLoadError,
          tone: AtemNoticeTone.error,
          actionLabel: l10n.commonRetry,
          onAction: () => ref.invalidate(weightSeriesProvider),
        ),
      ],
    );
  }
}

/// A1–A4 und A2 — ein Aufbau, fünf Träger.
class _Block extends ConsumerWidget {
  const _Block({
    required this.series,
    required this.window,
    required this.range,
    required this.latest,
    required this.reference,
    required this.unseeded,
    required this.l10n,
  });

  final WeightSeries series;
  final WeightSeries window;
  final WeightRange range;
  final WeightEntry latest;
  final DateTime reference;
  final bool unseeded;
  final AppL10n l10n;

  bool get _hasCurve => window.length >= 2;

  void _openHistory(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const WeightHistoryScreen(),
        ),
      );

  Future<void> _log(BuildContext context, WidgetRef ref) =>
      showWeightEntrySheet(context, ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final change = window.change;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AtemCard.list(
          onTap: () => _openHistory(context),
          semanticLabel: _cardLabel(context, change),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AtemExplainHeader(
                  title: l10n.weightBlockTitle,
                  titleStyle: AtemType.titleSmallOrDefault(context),
                  trailing: _hasCurve
                      ? WeightUi.rangeLabel(l10n, range).toUpperCase()
                      : null,
                  explanation: [
                    l10n.weightExplainBody,
                    l10n.weightExplainChange,
                    l10n.weightExplainGaps,
                    l10n.weightExplainSources,
                    l10n.weightExplainLoad,
                  ],
                ),
                const SizedBox(height: 10),
                _ValueRow(
                  kg: latest.kg,
                  basis: _hasCurve ? l10n.weightEntries(window.length) : null,
                ),
                if (change != null) ...[
                  const SizedBox(height: 6),
                  _ChangeRow(change: change),
                ],
                if (_hasCurve) ...[
                  const SizedBox(height: 10),
                  WeightChart(
                    series: window,
                    semanticLabel: WeightUi.chartLabel(context, l10n, window),
                  ),
                  const SizedBox(height: 5),
                  _Anchors(series: window),
                  if (window.namedGap case final gap?) ...[
                    const SizedBox(height: 4),
                    WeightGapNote(label: l10n.weightGapNote(gap.weeks)),
                  ],
                ] else ...[
                  const SizedBox(height: 6),
                  Text(_singleNote(context), style: AtemType.labelSmall.of(context)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (_hasCurve)
          _LogRow(
            label: l10n.weightLastEntryDays(
              WeightEntry.dayOf(reference)
                  .difference(latest.date)
                  .inDays
                  .clamp(0, 99999),
            ),
            action: l10n.weightEnterCta,
            onTap: () => _log(context, ref),
          )
        else
          _StartRow(
            label: l10n.weightSingleValueTitle,
            action: l10n.weightStartCta,
            onTap: () => _log(context, ref),
          ),
      ],
    );
  }

  /// A2 — woher der eine Wert kommt und warum daraus keine Kurve folgt.
  String _singleNote(BuildContext context) {
    final why = l10n.weightSingleValueWhy;
    if (unseeded) return '${l10n.weightSingleValueSeed} $why';
    final date = WeightUi.shortDate(context, latest.date);
    final note = latest.source == WeightSource.settings
        ? l10n.weightSingleValueNote(date)
        : l10n.weightSingleValueFirst(date);
    return '$note $why';
  }

  /// **Ein Knoten, nicht vier.** Wert, Grundlage und Veränderung stehen in
  /// einem Satz; die Kinder der Karte sind für Vorleseprogramme ausgeschlossen.
  String _cardLabel(BuildContext context, WeightChange? change) {
    final kg = WeightUi.kg(context, latest.kg);
    // Das Ziel gehört ins Label: `AtemCard` kennt keinen eigenen Hinweis, und
    // ein Knopf ohne Ziel ist für ein Vorleseprogramm eine Überraschung.
    final hint = l10n.weightCardOpenHint;
    if (change == null || !_hasCurve) {
      return '${l10n.weightCardSingleA11y(kg)}. $hint';
    }
    final basis = l10n.weightBasis(
      window.length,
      WeightUi.longDate(context, window.first!.date),
    );
    final label = l10n.weightCardA11y(
        kg, basis, WeightUi.changeA11y(context, l10n, change));
    return '$label. $hint';
  }
}

/// Die Wertzeile: Zahl, Einheit und die Zählung als Grundlage.
class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.kg, this.basis});

  final double kg;
  final String? basis;

  @override
  Widget build(BuildContext context) {
    final count = basis;
    // Volle Breite, sonst hat `spaceBetween` keinen Raum zu verteilen und der
    // Nenner klebte am Wert (am Render gesehen, 20.09.2026).
    return SizedBox(
      width: double.infinity,
      // Bei grosser Systemschrift wandert der Nenner unter den Wert statt
      // daneben (Board 14, A7) — sonst teilen sich zwei Mono-Zeilen 320 dp.
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        alignment: WrapAlignment.spaceBetween,
        spacing: 10,
        runSpacing: 2,
        children: [
          _Value(kg: kg),
          if (count != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(count.toUpperCase(),
                  style: AtemType.labelMicro.of(context)),
            ),
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.kg});

  final double kg;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(WeightUi.kg(context, kg),
              style: AtemType.valueLarge.of(context)),
          const SizedBox(width: 5),
          Text(AppL10n.of(context).weightUnitKg,
              style: AtemType.labelMicro.of(context)),
        ],
      );
}

/// Die Veränderungszeile — Glyph und Satz, **keine Ampelfarbe**.
class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.change});

  final WeightChange change;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: WeightChangeGlyph(
              up: change.isUp, color: AtemColors.textTertiary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            WeightUi.change(context, l10n, change),
            style: AtemType.labelSmall.of(context),
          ),
        ),
      ],
    );
  }
}

/// Die beiden Datumsanker unter der Kurve.
class _Anchors extends StatelessWidget {
  const _Anchors({required this.series});

  final WeightSeries series;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    // **Nicht labelMicro.** Ein Anker trägt Datum und Zahl mit „·" — genau
    // die Rolle, die `meta` beschreibt. In Mono-Versalien passten die beiden
    // bei 1,15-facher Schrift nicht nebeneinander und wurden ellipsiert
    // („23. JUNI · 80…"), am Render gesehen.
    String anchor(WeightEntry entry) => l10n.weightAnchor(
        WeightUi.shortDate(context, entry.date),
        WeightUi.kg(context, entry.kg));

    // **Umbrechen statt kürzen.** Nebeneinander, solange beide passen; sonst
    // untereinander. Bei 200 % auf 320 dp stand vorher „23. Juni …" und
    // „15. Sept.…" — der Wert war weg, und genau er ist der Anker.
    final style = AtemType.meta.of(context);
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        runSpacing: 2,
        children: [
          Text(anchor(series.first!), style: style),
          Text(anchor(series.latest!), style: style),
        ],
      ),
    );
  }
}

/// Die Zeile „Eintragen" — ein **eigenes** Tap-Ziel neben der Karte.
///
/// Die Karte öffnet den Verlauf, diese Zeile das Eingabeblatt. Zwei Ziele in
/// einer Fläche wären eine Karte, bei der es darauf ankommt, wohin man tippt.
class _LogRow extends StatelessWidget {
  const _LogRow({
    required this.label,
    required this.action,
    required this.onTap,
  });

  final String label;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtemTappable(
        onTap: onTap,
        semanticLabel: action,
        semanticHint: label,
        minTapSize: const Size(0, 48),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AtemColors.card,
            borderRadius: BorderRadius.circular(AtemRadii.statBox),
            border: Border.all(color: AtemColors.border),
          ),
          child: ExcludeSemantics(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 4,
              children: [
                Text(label, style: AtemType.labelSmall.of(context)),
                Text(action.toUpperCase(),
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(color: AtemColors.cyan)),
              ],
            ),
          ),
        ),
      );
}

/// A2 — dieselbe Zeile, betont: Sie ist hier der einzige Weg weiter.
class _StartRow extends StatelessWidget {
  const _StartRow({
    required this.label,
    required this.action,
    required this.onTap,
  });

  final String label;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AtemTappable(
        onTap: onTap,
        semanticLabel: label,
        minTapSize: const Size(0, 48),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AtemColors.cyan.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AtemRadii.statBox),
            border: Border.all(color: AtemColors.cyan.withValues(alpha: 0.4)),
          ),
          child: ExcludeSemantics(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 4,
              children: [
                Text(label,
                    style: AtemType.labelSmall
                        .of(context)
                        .copyWith(color: AtemColors.textPrimary)),
                Text(action.toUpperCase(),
                    style: AtemType.labelMicro
                        .of(context)
                        .copyWith(color: AtemColors.cyan)),
              ],
            ),
          ),
        ),
      );
}
