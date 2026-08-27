import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../widgets/brand_block.dart';

/// Der unentschiedene erste Moment.
///
/// Firebase weiß beim Start noch nicht, ob jemand angemeldet ist. Dieser
/// Bildschirm füllt genau diese Lücke — und er darf **nicht** wie „abgemeldet"
/// aussehen: Stünde hier die Anmeldung, blitzte sie bei jedem Start auf,
/// obwohl der Nutzer längst angemeldet ist.
///
/// ## Die 300-Millisekunden-Regel
///
/// Der unbestimmte Fortschrittsbalken erscheint **erst nach 300 ms**. Ist die
/// Antwort schneller da — und aus dem lokalen Zwischenspeicher ist sie das
/// meistens —, sieht niemand ein Ladeelement. Ein Balken, der für 80 ms
/// aufblitzt, meldet ein Problem, das es nicht gibt.
///
/// Keine interaktiven Elemente. Die Ansage trägt den Zustand.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Ab hier lohnt sich ein sichtbares Warten.
  static const showProgressAfter = Duration(milliseconds: 300);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showProgress = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.showProgressAfter, () {
      if (mounted) setState(() => _showProgress = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AtemColors.base,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandBlock(semanticLabel: l10n.splashStarting),
              const SizedBox(height: 28),
              // Der Platz wird reserviert, damit der Balken nichts verschiebt,
              // wenn er doch erscheint.
              SizedBox(
                height: 4,
                width: 120,
                // `value: null` heisst unbestimmt. Aus den Semantics
                // ausgeschlossen: Der Zustand steckt schon in der Ansage am
                // Markenblock, zweimal wäre er nur Lärm.
                child: _showProgress
                    ? const ExcludeSemantics(
                        child: AtemProgressBar.share(
                          value: null,
                          semanticLabel: '',
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
