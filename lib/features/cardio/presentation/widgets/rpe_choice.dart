import 'package:flutter/widgets.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../cardio_ui.dart';

/// Die RPE-Auswahl 1–5 — [AtemScaleChoice] mit den Wörtern aus Board 11.
///
/// Es ist **die Schwierigkeitsauswahl aus Modul 7 mit anderer Beschriftung**
/// (Board 11, Sektion I): gleiche fünf Felder, gleiche Reihe, gleiche Regel —
/// keine Vorbelegung. Seit beide auf demselben Baustein sitzen, ist das nicht
/// mehr nur eine Aussage im Kommentar.
///
/// Sichtbar 44 dp hoch (Spezifikation F), Trefferfläche 48. Die Fläche ist
/// [AtemColors.surfaceSolid], weil die Auswahl im Formular auf blankem Grund
/// steht und nicht auf einer Karte.
class RpeChoice extends StatelessWidget {
  const RpeChoice({super.key, required this.value, required this.onChanged});

  /// `null` heisst: nichts gewählt. Puls und RPE sind optional — leer lassen
  /// ist der Normalfall.
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return AtemScaleChoice(
      value: value,
      onChanged: onChanged,
      groupLabel: l10n.formRpe,
      wordFor: (level) => rpeWord(l10n, level),
      semanticLabelFor: (level) => '${l10n.formRpe} $level, '
          '${rpeWord(l10n, level)}, $level ${l10n.commonOf} 5',
      surface: AtemColors.surfaceSolid,
      visibleHeight: 44,
    );
  }
}
