import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/health_import_providers.dart';
import '../domain/health_session.dart';
import '../domain/session_pairing.dart';
import 'widgets/pair_sheet.dart';
import 'widgets/review_sheet.dart';

/// Der eine Weg in die Prüfung — **erst die Frage, dann das Blatt**.
///
/// ## Warum die Vermutung vorne steht
///
/// Eine Uhr-Einheit, die zu einer App-Einheit gehört, soll keine zweite
/// Einheit werden. Wer sie zuerst prüfte und danach gefragt würde, hätte
/// schon eine angelegt — der Fehler „zwei Einheiten für ein Training" ist
/// der teurere von beiden (Board 15, Entscheidung 6).
///
/// Deshalb: Gibt es eine Vermutung oder mehrere Kandidaten, kommt zuerst das
/// Paar-Blatt. „Getrennt lassen" führt von dort in den normalen
/// Prüfbildschirm — die Einheit wird dann eine eigene.
///
/// Nach einer Zusammenführung ist diese Einheit erledigt, und der Stapel geht
/// mit der nächsten weiter.
Future<void> reviewPending(
  BuildContext context,
  WidgetRef ref,
  List<HealthSession> pending,
) async {
  if (pending.isEmpty) return;

  final first = pending.first;
  final verdict = ref.read(pairVerdictProvider(first));

  if (verdict is! PairNone) {
    final mergedInto = await showPairSheet(
      context,
      measured: first,
      verdict: verdict,
    );
    if (!context.mounted) return;
    if (mergedInto != null) {
      // Die Liste soll die beiden Zeilen noch einmal zeigen und ineinander
      // laufen lassen (Board 15, B6). Geschrieben ist zu diesem Zeitpunkt
      // alles; was hier gesetzt wird, ist nur der Auftrag zur Bewegung — sie
      // läuft erst los, wenn kein Blatt mehr darüber liegt.
      ref.read(mergeAnimationProvider.notifier).arm(mergedInto, first);
      // Erledigt — weiter mit dem Rest des Stapels.
      return reviewPending(context, ref, pending.sublist(1));
    }
  }

  await showHealthReviewSheet(context, pending);
}
