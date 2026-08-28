import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';

/// Eine Meldung, die gerade steht.
@immutable
class AtemSnack {
  const AtemSnack({
    required this.message,
    required this.semanticLabel,
    this.tone = AtemSnackTone.neutral,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String semanticLabel;
  final AtemSnackTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  bool get hasAction => actionLabel != null && onAction != null;

  /// Vier Sekunden ohne Weg zurück, dreissig mit.
  Duration get duration =>
      hasAction ? AtemSnackbar.undoDuration : AtemSnackbar.shortDuration;
}

/// Der eine Meldungskanal der App.
///
/// ## Warum zentral und nicht je Bildschirm
///
/// Fast jede Meldung überlebt den Bildschirm, der sie ausgelöst hat: Wer eine
/// Einheit im Detail löscht, landet danach in der Liste; wer einen Planeintrag
/// entfernt, scrollt weiter. Eine Meldung, die am auslösenden Bildschirm
/// hinge, verschwände genau in dem Moment, in dem der Widerruf gebraucht wird.
///
/// Deshalb steht sie in der Hülle, über der Navigationsleiste, und überlebt
/// jeden Wechsel.
///
/// ## Eine zur Zeit
///
/// Eine neue verdrängt die alte, und die alte gilt damit als angenommen. Zwei
/// Widerrufe übereinander wären nicht zuzuordnen — und drei Meldungen
/// nacheinander eine Warteschlange, die niemand liest.
class SnackbarController extends Notifier<AtemSnack?> {
  Timer? _timer;

  @override
  AtemSnack? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void show(AtemSnack snack) {
    _timer?.cancel();
    state = snack;
    _timer = Timer(snack.duration, dismiss);
  }

  void dismiss() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }
}

final snackbarProvider =
    NotifierProvider<SnackbarController, AtemSnack?>(SnackbarController.new);
