import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../domain/comparison_basis.dart';
import '../../domain/session_comparison.dart';
import '../../domain/training_session.dart';
import 'basis_capsule.dart';

/// Der Vergleich im Einheitendetail — **eine Zahl bekommt einen Bezug**.
///
/// ## Was die Karte nicht sagt
///
/// Nicht, ob die Einheit gut war. „+32 Last" ist Richtung und Größe, keine
/// Bewertung: Mehr Last kann Fortschritt sein oder Übermut, und was davon
/// zutrifft, entscheidet der ACWR daneben — nicht diese Karte.
///
/// ## Vier Zeilen, und bei Stufe C zwei davon leer
///
/// Dauer, Last, Volumen, Sätze. Beruht der Vergleich nur auf der Art der
/// Einheit, tragen Volumen und Sätze ein „—": Sie hängen an den Übungen, und
/// zwei Krafteinheiten mit verschiedenen Übungen haben kein vergleichbares
/// Volumen. Die Zeilen verschwinden nicht — ihr Fehlen ist die Aussage.
class ComparisonCard extends StatelessWidget {
  const ComparisonCard({
    super.key,
    required this.comparison,
    required this.languageTag,
  });

  final SessionComparison comparison;
  final String languageTag;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    if (!comparison.hasReference) return _Empty(comparison: comparison);

    final previous = comparison.previous!;
    final current = comparison.current;
    final median = comparison.basis == ComparisonBasis.sameKind;

    return AtemCard.list(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BasisCapsule(
            basis: comparison.basis!,
            dateLabel: DateFormat.MMMd(languageTag)
                .format(comparison.referenceDate!),
            daysAgo: comparison.daysBetween ?? 0,
            medianCount: comparison.medianCount,
          ),
          const SizedBox(height: 14),
          _Row(
            label: l10n.detailDuration,
            value: _minutes(l10n, current.duration),
            reference: _minutes(l10n, previous.duration),
            median: median,
            delta: _delta(
              current.duration?.inMinutes,
              previous.duration?.inMinutes,
            ),
          ),
          _Row(
            label: l10n.detailLoad,
            value: current.load.round().toString(),
            reference: previous.load.round().toString(),
            median: median,
            delta: _delta(current.load.round(), previous.load.round()),
          ),
          _Row(
            label: l10n.detailVolume,
            value: _kilograms(l10n, current.volume),
            // Bei Stufe C ohne Bezug — das „—" ist die Aussage.
            reference: comparison.comparesVolume
                ? _kilograms(l10n, previous.volume)
                : null,
            median: median,
            delta: comparison.comparesVolume
                ? _percent(current.volume, previous.volume)
                : null,
          ),
          _Row(
            label: l10n.planEntrySets,
            value: current.sets?.toString() ?? l10n.commonNotAvailable,
            reference: comparison.comparesVolume
                ? previous.sets?.toString()
                : null,
            median: median,
            delta: comparison.comparesVolume
                ? _delta(current.sets, previous.sets)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            switch (comparison.basis!) {
              ComparisonBasis.samePlan => l10n.compareNotePlan(
                  _planName(comparison) ?? l10n.commonNotAvailable),
              ComparisonBasis.sameExercises => l10n.compareBasisExercises,
              ComparisonBasis.sameKind => l10n.compareNoteMedian,
            },
            style: AtemType.meta.of(context),
          ),
        ],
      ),
    );
  }

  static String? _planName(SessionComparison comparison) {
    final session = comparison.session;
    return session is StrengthSession ? session.planName : null;
  }

  static String _minutes(AppL10n l10n, Duration? value) =>
      value == null ? l10n.commonNotAvailable : l10n.durationMinutes(value.inMinutes);

  static String _kilograms(AppL10n l10n, double? value) =>
      value == null ? l10n.commonNotAvailable : l10n.unitKilograms(value.round().toString());

  /// Ein absolutes Delta, oder `null`, wenn eine Seite fehlt.
  static (String, bool)? _delta(num? now, num? before) {
    if (now == null || before == null || now == before) return null;
    final diff = now - before;
    final sign = diff > 0 ? '+' : '−';
    return ('$sign${diff.abs()}', diff > 0);
  }

  /// Volumen als Prozent — absolute Kilogramm wären vierstellig und sagen
  /// weniger als „+8 %".
  static (String, bool)? _percent(double? now, double? before) {
    if (now == null || before == null || before == 0) return null;
    final change = ((now - before) / before * 100).round();
    if (change == 0) return null;
    final sign = change > 0 ? '+' : '−';
    return ('$sign${change.abs()} %', change > 0);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.reference,
    required this.median,
    required this.delta,
  });

  final String label;
  final String value;

  /// `null` heißt: kein Bezug für diese Zeile.
  final String? reference;

  final bool median;
  final (String, bool)? delta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final hasReference = reference != null;

    // **Das „—" ist nie stumm.** Ein übersprungenes Zeichen läse sich wie ein
    // fehlendes Datum.
    final spoken = hasReference
        ? '$label $value, ${median ? l10n.compareMedian(reference!) : l10n.comparePrev(reference!)}'
            '${delta == null ? '' : ', ${delta!.$1}'}'
        : '$label $value, ${l10n.compareNoneValue}';

    return Semantics(
      label: spoken,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          // **Untereinander statt zwei Spalten.** Bei 320 dp passen zwei
          // Spalten mit vierstelligen Werten nicht — das steht so in der
          // Bausteinliste des Boards.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AtemType.labelMicro.of(context)),
              const SizedBox(height: 3),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    value,
                    style: AtemType.valueMedium.of(context).copyWith(
                          color: hasReference
                              ? AtemColors.textPrimary
                              : AtemColors.textSecondary,
                        ),
                  ),
                  Text(
                    hasReference
                        ? (median
                            ? l10n.compareMedian(reference!)
                            : l10n.comparePrev(reference!))
                        : l10n.compareNoneValue,
                    style: AtemType.labelMicro.of(context),
                  ),
                  if (delta case final d?)
                    DeltaCapsule(delta: d.$1, rises: d.$2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kein Bezug — **ein Satz, keine leere Karte**.
class _Empty extends StatelessWidget {
  const _Empty({required this.comparison});

  final SessionComparison comparison;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemCard.list(
      padding: const EdgeInsets.all(16),
      child: Text(
        l10n.compareEmptyType,
        style: AtemType.labelSmall.of(context),
      ),
    );
  }
}
