import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../application/history_providers.dart';
import '../application/pending_deletion.dart';
import '../domain/session_consequence.dart';
import '../domain/training_load.dart';
import '../domain/training_session.dart';
import 'session_ui.dart';
import 'widgets/consequence_table.dart';

/// Eine Einheit löschen — **eine Bestätigung, dann dreißig Sekunden Widerruf**.
///
/// ## Warum hier nur einmal bestätigt wird
///
/// Der Vertrag verlangt zwei Bestätigungen, wenn Löschen Arbeit vernichtet.
/// Hier tritt an die Stelle der zweiten das Zeitfenster: Wer bestätigt hat,
/// sieht die Einheit verschwinden und behält dreißig Sekunden lang die
/// Möglichkeit, es zurückzunehmen.
///
/// Das ist mehr Sicherheit als ein zweiter Dialog, nicht weniger. Ein zweiter
/// Dialog fragt dieselbe Frage noch einmal und wird deshalb genauso schnell
/// weggetippt wie der erste. Ein Widerruf greift auch dann noch, wenn beide
/// Dialoge schon durchgeklickt sind.
///
/// Beim **Löschen einer Übung** ist es umgekehrt: Dort gibt es keinen
/// Widerruf — die Kette in Pläne und Einheiten hinein lässt sich nicht
/// verlässlich zurückdrehen —, und deshalb wird dort zweimal gefragt.
///
/// Gibt `true` zurück, wenn das Fenster begonnen hat.
Future<bool> confirmDeleteSession(
  BuildContext context,
  WidgetRef ref,
  TrainingSession session,
) async {
  final l10n = AppL10n.of(context);

  final consequence = SessionConsequence.ofDeleting(
    ref.read(sessionsProvider).value ?? const [],
    session.id,
    ref.read(historyReferenceProvider),
    context: LoadContext(bodyWeightKg: ref.read(bodyWeightProvider).value ?? 0),
  );

  final confirmed = await AtemDialog.show<bool>(
    context,
    kind: AtemDialogKind.destructive,
    title: l10n.sessionDeleteTitle,
    message: l10n.sessionDeleteBody,
    confirmLabel: l10n.commonDelete,
    dismissLabel: l10n.commonCancel,
    barrierLabel: l10n.sessionDeleteBarrier,
    // **Die Folgen stehen im Dialog, nicht als Warnsatz.** Wer hier „Pause
    // 50 → 32" liest, entscheidet informiert; wer „das wirkt sich aus" liest,
    // entscheidet genauso uninformiert wie vorher.
    detail: ConsequenceTable(consequence: consequence),
    onConfirm: () => Navigator.of(context).pop(true),
  );

  if (confirmed != true) return false;

  await ref.read(pendingDeletionProvider.notifier).start(
        session.id,
        label: sessionName(l10n, session),
      );
  return true;
}
