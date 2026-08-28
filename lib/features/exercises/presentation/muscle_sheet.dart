import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../domain/muscle.dart';
import 'muscle_ui.dart';
import 'widgets/exercise_bits.dart';

/// Muskelauswahl in einem Blatt — **Abweichung vom Board, auf Wunsch**.
///
/// ## Was das Board sagt und warum es trotzdem anders ist
///
/// Modul 7 zeichnet neun Chips direkt im Formular. Sie zeigen die Farbe schon
/// vor dem Antippen, und die Zuordnung Muskel–Farbe ist damit lernbar, ohne
/// dass man etwas tun muss.
///
/// Der Einwand aus der Erprobung war der Platz: Neun Chips brauchen im
/// Formular drei Zeilen und schieben Stufe und Speichern-Knopf unter die
/// Falz — auf 320 dp und bei grosser Schrift noch weiter.
///
/// ## Der Kompromiss
///
/// Die Auswahl wandert ins Blatt, **die Farben bleiben**: Jede Zeile trägt
/// links die Muskelkugel in ihrem Ton. Das Feld im Formular fasst zusammen
/// („3 gewählt · Brust, Trizeps, Schultern"), sodass die Auswahl auch ohne
/// Öffnen ablesbar ist.
///
/// Verloren geht, dass man die Farbzuordnung sieht, ohne zu tippen. Das ist
/// der Preis, und er steht hier, damit er nicht vergessen wird.
abstract final class MuscleSheet {
  /// Gibt die neue Auswahl zurück, oder `null` beim Abbrechen.
  static Future<Set<MuscleGroup>?> show(
    BuildContext context,
    Set<MuscleGroup> selected,
  ) {
    final l10n = AppL10n.of(context);
    return AtemSheet.show<Set<MuscleGroup>>(
      context,
      title: l10n.muscleSheetTitle,
      closeLabel: l10n.commonClose,
      child: _Body(initial: selected),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.initial});

  final Set<MuscleGroup> initial;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final Set<MuscleGroup> _chosen = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.muscleSheetHint, style: AtemType.labelSmall.of(context)),
        const SizedBox(height: 12),
        for (final muscle in MuscleGroup.filters)
          _Row(
            muscle: muscle,
            chosen: _chosen.contains(muscle),
            total: _chosen.length,
            onTap: () => setState(() {
              if (!_chosen.remove(muscle)) _chosen.add(muscle);
            }),
          ),
        const SizedBox(height: 14),
        AtemButton.gradient(
          label: l10n.commonDone,
          semanticLabel: l10n.commonDone,
          size: AtemButtonSize.compact,
          onPressed: () => Navigator.of(context).pop(_chosen),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.muscle,
    required this.chosen,
    required this.total,
    required this.onTap,
  });

  final MuscleGroup muscle;
  final bool chosen;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final label = muscle.label(l10n);

    return AtemTappable(
      onTap: onTap,
      // Rolle Kontrollkästchen: Ein Screenreader muss ansagen können, dass
      // mehrere gewählt sein dürfen — und wie viele es sind.
      semanticLabel: '$label, ${l10n.exerciseFieldMusclesCount(total)}',
      selected: chosen,
      minTapSize: const Size(0, 52),
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            // Die Farbe bleibt sichtbar — das ist die Bedingung, unter der
            // die Auswahl überhaupt aus dem Formular wandern durfte.
            MuscleOrb(color: muscle.color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AtemType.body.of(context).copyWith(
                      color: chosen ? muscle.color : AtemColors.textPrimary,
                      fontWeight: chosen ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(width: 10),
            _Box(chosen: chosen, color: muscle.color),
          ],
        ),
      ),
    );
  }
}

/// Das Kästchen. Haken und Farbe — nie die Farbe allein.
class _Box extends StatelessWidget {
  const _Box({required this.chosen, required this.color});

  final bool chosen;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: chosen ? color.withValues(alpha: 0.18) : AtemColors.card,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: chosen ? color : AtemColors.border),
        ),
        child: chosen ? Icon(Icons.check, size: 15, color: color) : null,
      );
}
