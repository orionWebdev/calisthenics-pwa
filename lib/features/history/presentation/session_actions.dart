import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/application/snackbar_providers.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/gen/app_l10n.dart';
import '../application/history_providers.dart';
import '../application/pending_deletion.dart';
import '../domain/session_consequence.dart';
import '../domain/training_session.dart';
import 'session_ui.dart';
import 'widgets/consequence_table.dart';

/// Eine Einheit löschen — **zwei Stufen, dann dreissig Sekunden Widerruf**.
///
/// ## Warum beides
///
/// Die Schreibmatrix des Boards führt diese Aktion als die einzige, die „245
/// Tage Auswertung verändert". Sie bekommt deshalb beides: die zwei Stufen,
/// weil sie unwiderruflich in die Historie greift, und das Fenster, weil sich
/// die Folge erst zeigt, wenn man sie sieht.
///
/// Die zwei Stufen sind nicht zweimal dieselbe Frage. **Stufe 1 informiert**
/// — vier Kennzahlen mit Vorher und Nachher. **Stufe 2 entscheidet**, mit
/// genau zwei Wegen und ohne neue Information.
///
/// Gibt `true` zurück, wenn das Fenster begonnen hat.
Future<bool> confirmDeleteSession(
  BuildContext context,
  WidgetRef ref,
  TrainingSession session,
) async {
  final l10n = AppL10n.of(context);
  final sessions = ref.read(sessionsProvider).value ?? const [];

  final consequence = SessionConsequence.ofDeleting(
    sessions,
    session.id,
    ref.read(historyReferenceProvider),
    context: ref.read(loadContextProvider),
  );

  // Die vierte Zeile zählt die Einheiten derselben Art — „Cardio-Einheiten
  // 51 → 50". Sie sagt, in welchem Teil des Bestands die Lücke entsteht.
  final kindLabel = sessionKindLabel(l10n, session);
  final ofKind = sessions.where((s) => s.kind == session.kind).length;

  final first = await AtemDialog.show<bool>(
    context,
    kind: AtemDialogKind.destructive,
    title: l10n.sessionDeleteQ,
    message: l10n.sessionDeleteBody,
    confirmLabel: l10n.deleteStep1Continue,
    dismissLabel: l10n.commonCancel,
    barrierLabel: l10n.sessionDeleteQ,
    detail: ConsequenceTable(
      rows: ConsequenceTable.forDeleting(
        l10n,
        consequence,
        kindLabel,
        ofKind,
        ofKind - 1,
      ),
    ),
    onConfirm: () => Navigator.of(context, rootNavigator: true).pop(true),
  );
  if (first != true || !context.mounted) return false;

  // Stufe 2 bringt keine neue Information — sie fragt nur noch, ob es gilt.
  final second = await AtemDialog.show<bool>(
    context,
    kind: AtemDialogKind.destructive,
    title: l10n.deleteStep2Title,
    message: l10n.sessionDeleteWindow,
    confirmLabel: l10n.deleteConfirm,
    dismissLabel: l10n.deleteKeep,
    barrierLabel: l10n.sessionDeleteQ,
    onConfirm: () => Navigator.of(context, rootNavigator: true).pop(true),
  );
  if (second != true) return false;

  await ref.read(pendingDeletionProvider.notifier).start(
        session.id,
        label: sessionName(l10n, session),
      );

  // Die Meldung nennt die Folge, nicht nur die Tat: „Einheiten 63 → 62" ist
  // der Grund, warum jemand den Widerruf überhaupt in Erwägung zieht.
  final before = consequence.sessionsBefore.toString();
  final after = consequence.sessionsAfter.toString();
  final message = l10n.sessionDeletedSnack(before, after);

  ref.read(snackbarProvider.notifier).show(
        AtemSnack(
          message: message,
          semanticLabel: message,
          actionLabel: l10n.commonUndo,
          onAction: () => ref.read(pendingDeletionProvider.notifier).undo(),
        ),
      );
  return true;
}
