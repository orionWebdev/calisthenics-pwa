import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/health_import_providers.dart';
import '../domain/health_session.dart';
import '../domain/session_pairing.dart';
import 'widgets/merge_motion.dart';
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
/// Der Einstieg: prüfen und danach die Bewegung zeigen.
///
/// **Scharfgestellt wird erst hier**, nachdem [reviewPending] zurückgekehrt
/// ist — und das ist es erst, wenn das letzte Blatt vollständig ausgefahren
/// ist. Vorher scharfgestellt lief die Verschmelzung los, während das Blatt
/// noch über der Liste herunterfuhr: Von 420 ms lagen 300 dahinter, sichtbar
/// blieb der Punkt. Am 21.09.2026 sah der Nutzer sie dreimal nicht.
Future<void> runReview(
  BuildContext context,
  WidgetRef ref,
  List<HealthSession> pending,
) async {
  final merged = await reviewPending(context, ref, pending);
  if (merged == null) return;
  await Future<void>.delayed(AtemMergeMotion.afterSheet);
  if (!context.mounted) return;
  ref
      .read(mergeAnimationProvider.notifier)
      .arm(merged.sessionId, merged.measured);
}

/// Prüft den Stapel ab und meldet die **letzte** Zusammenführung zurück.
///
/// Nur die letzte: Wer einen Stapel durchgeht und zweimal zusammenführt,
/// sieht die Bewegung, die beim Schliessen des Blatts noch auf dem
/// Bildschirm liegt. Zwei nacheinander abzuspielen hiesse, jemanden auf eine
/// Animation warten zu lassen, die er nicht angefordert hat.
Future<MergeAnimation?> reviewPending(
  BuildContext context,
  WidgetRef ref,
  List<HealthSession> pending,
) async {
  if (pending.isEmpty) return null;

  final first = pending.first;
  final verdict = ref.read(pairVerdictProvider(first));

  if (verdict is! PairNone) {
    final mergedInto = await showPairSheet(
      context,
      measured: first,
      verdict: verdict,
    );
    final mine = mergedInto == null
        ? null
        : MergeAnimation(sessionId: mergedInto, measured: first);
    if (!context.mounted) return mine;
    if (mine != null) {
      // Erledigt — weiter mit dem Rest des Stapels. Eine spätere
      // Zusammenführung sticht diese aus.
      return await reviewPending(context, ref, pending.sublist(1)) ?? mine;
    }
  }

  await showHealthReviewSheet(context, pending);
  return null;
}
