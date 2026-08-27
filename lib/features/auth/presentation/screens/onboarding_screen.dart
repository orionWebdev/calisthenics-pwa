import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_user.dart';

/// Gewichtseinheit — Anzeige, nicht Speicherformat.
enum WeightUnit {
  kg('metric', 30, 250, 1),
  lbs('imperial', 66, 550, 0.45359237);

  const WeightUnit(this.wire, this.min, this.max, this.toKilograms);

  /// Wie es im Profil steht — `unitSystem` im Bestand.
  final String wire;

  final double min;
  final double max;

  /// Faktor zur Umrechnung in Kilogramm.
  final double toKilograms;

  double kilogramsFrom(double value) => value * toKilograms;
}

/// Onboarding — ein Schritt, eine Zahl.
///
/// ## Warum nur das Körpergewicht
///
/// Der Leitsatz macht die Grenze prüfbar: **Nur was ohne Angabe eine falsche
/// Zahl erzeugt, darf den Einstieg blockieren.** Das ist genau das
/// Körpergewicht. Ohne es rechnet jede Körpergewichtsübung mit einer
/// Trainingslast von null — die App zeigte also eine Zahl, die falsch ist, und
/// niemand könnte es sehen.
///
/// Trainingsniveau, Stil und Pausenzeit haben einen sicheren Standard und
/// wohnen in den Einstellungen. Nach zwei Sessions beantwortet die App sie
/// ohnehin besser als der Nutzer am ersten Tag.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.user});

  final AuthUser user;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = TextEditingController();
  WeightUnit _unit = WeightUnit.kg;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _value => AtemNumberField.parse(_controller.text);

  bool get _valid {
    final v = _value;
    return v != null && v >= _unit.min && v <= _unit.max;
  }

  /// Prüft bei Verlassen des Feldes und beim Abschluss — **nie je Tastendruck**.
  /// Wer „8" tippt, um „82,5" zu schreiben, hat noch keinen Fehler gemacht.
  void _validate() {
    final l10n = AppL10n.of(context);
    setState(() {
      _error = _controller.text.trim().isEmpty || _valid
          ? null
          : l10n.onbErrorRange(
              // Ganzzahlige Grenzen — hier braucht es kein Trennzeichen und
              // damit auch keine Lokalisierung der Zahl.
              _unit.min.toStringAsFixed(0),
              _unit.max.toStringAsFixed(0),
              _unitLabel(l10n),
            );
    });
  }

  /// **Der Einheitenwechsel rechnet nicht um.**
  ///
  /// 82,5 kg würde beim Umschalten zu 181,9 lbs — das wirkt klug und zerstört
  /// die Eingabe. Wer umschaltet, tut es fast immer, weil die *Einheit* falsch
  /// war, nicht die Ziffern. Die Ziffern bleiben also stehen und werden in der
  /// neuen Einheit neu geprüft.
  void _switchUnit(WeightUnit unit) {
    setState(() => _unit = unit);
    if (_controller.text.trim().isNotEmpty) _validate();
  }

  String _unitLabel(AppL10n l10n) =>
      _unit == WeightUnit.kg ? l10n.onbUnitKg : l10n.onbUnitLbs;

  Future<void> _finish() async {
    _validate();
    final value = _value;
    if (!_valid || value == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).saveBodyWeight(
            widget.user.uid,
            kilograms: _unit.kilogramsFrom(value),
            unitSystem: _unit.wire,
          );
      ref.invalidate(accessProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AtemColors.base,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AtemSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                // Scrollt frei: Bei 200 % Schrift passt der Inhalt sonst nicht
                // über dem Knopf.
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(l10n.onbKicker,
                          style: AtemType.labelMicro.of(context)),
                      const SizedBox(height: 10),
                      Text(l10n.onbTitle,
                          style: AtemType.titleLarge.of(context)),
                      const SizedBox(height: 12),
                      Text(l10n.onbWhy, style: AtemType.labelSmall.of(context)),
                      const SizedBox(height: 28),
                      AtemSegmented<WeightUnit>(
                        value: _unit,
                        enabled: !_saving,
                        groupSemanticLabel: l10n.onbUnitGroupA11y,
                        onChanged: _switchUnit,
                        segments: [
                          AtemSegment(
                            value: WeightUnit.kg,
                            label: l10n.onbUnitKg,
                            semanticLabel: l10n.onbUnitKgA11y,
                          ),
                          AtemSegment(
                            value: WeightUnit.lbs,
                            label: l10n.onbUnitLbs,
                            semanticLabel: l10n.onbUnitLbsA11y,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Focus(
                        onFocusChange: (has) {
                          if (!has) _validate();
                        },
                        child: AtemNumberField.large(
                          controller: _controller,
                          semanticLabel: l10n.onbFieldA11y(_unitLabel(l10n)),
                          suffix: _unitLabel(l10n),
                          locked: _saving,
                          hasError: _error != null,
                          onChanged: (_) {
                            // Nur den Knopf freischalten, nicht prüfen.
                            setState(() {});
                          },
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: AtemType.labelSmall
                                .of(context)
                                .copyWith(color: AtemColors.magenta),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(l10n.onbHintSettings,
                          style: AtemType.labelSmall.of(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Gesperrt **mit Begründung**: Ein toter Knopf ohne Erklärung ist
              // eine Sackgasse.
              if (!_valid && !_saving) ...[
                Text(
                  l10n.onbCtaLocked,
                  textAlign: TextAlign.center,
                  style: AtemType.labelSmall.of(context),
                ),
                const SizedBox(height: 10),
              ],
              AtemButton.gradient(
                label: _saving ? l10n.onbSaving : l10n.onbCta,
                semanticLabel: _saving ? l10n.onbSaving : l10n.onbCta,
                semanticHint: _valid ? null : l10n.onbCtaLockedA11y,
                leading: _saving ? const AtemButtonSpinner() : null,
                onPressed: _valid && !_saving ? _finish : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
