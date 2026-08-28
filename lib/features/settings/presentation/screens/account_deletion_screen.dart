import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../history/application/history_providers.dart';
import '../../../exercises/application/exercise_providers.dart';
import '../../application/settings_providers.dart';

/// Stufe 2 des Löschens: **das getippte Wort**.
///
/// ## Warum nicht ein zweiter Ja-Nein-Dialog
///
/// Ein zweiter Dialog stellt dieselbe Frage noch einmal und wird deshalb
/// genauso schnell weggetippt wie der erste — zwei Tipps an derselben Stelle
/// des Bildschirms sind kein Schutz, sondern eine Wiederholung.
///
/// Ein Wort zu tippen unterbricht die Bewegung. Es lässt sich nicht aus
/// Versehen tun, und es zwingt dazu, den Satz darüber zu lesen.
///
/// ## Warum ein eigener Bildschirm und kein Dialog
///
/// Ein Dialog trägt höchstens drei Wege, und hier sind es vier Dinge: der
/// Satz, das Feld, der Fehlerfall und der Ladezustand, der eine halbe Minute
/// dauern kann. Ein Dialog, der so lange steht, ist ein Bildschirm ohne
/// Zurück-Taste.
class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() =>
      _AccountDeletionScreenState();
}

class _AccountDeletionScreenState
    extends ConsumerState<AccountDeletionScreen> {
  final _confirm = TextEditingController();
  var _running = false;
  String? _error;

  /// Wie viele Sammlungen fertig sind. `null`, solange nicht gelöscht wird.
  int? _done;
  int _total = 0;

  /// Wie lange der Bestand zurückreicht und wie gross er ist.
  ///
  /// Die zweite Stufe nennt es noch einmal — nicht als neue Information,
  /// sondern damit beim Tippen des Wortes dasteht, worauf es sich bezieht.
  int get _years => _span ~/ 365;
  int get _months => (_span % 365) ~/ 30;

  int get _span {
    final sessions = ref.read(sessionsProvider).value ?? const [];
    if (sessions.isEmpty) return 0;
    final first =
        sessions.reduce((a, b) => a.date.isBefore(b.date) ? a : b).date;
    return ref.read(historyReferenceProvider).difference(first).inDays;
  }

  int get _sessions => (ref.read(sessionsProvider).value ?? const []).length;

  int get _ownExercises => (ref.read(exercisesProvider).value ?? const [])
      .where((e) => e.isOwn)
      .length;

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  bool _matches(AppL10n l10n) =>
      _confirm.text.trim() == l10n.accountDelete2TypeWord;

  Future<void> _delete() async {
    final l10n = AppL10n.of(context);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() {
      _running = true;
      _error = null;
    });

    try {
      // Erst die Daten, dann das Konto. Umgekehrt verweigerten die Regeln
      // jeden Zugriff, und der Bestand bliebe unerreichbar liegen.
      await ref.read(accountRepositoryProvider).deleteData(
            userId,
            onProgress: (done, total, _) {
              if (!mounted) return;
              setState(() {
                _done = done;
                _total = total;
              });
            },
          );
      await ref.read(accountRepositoryProvider).deleteAccount();

      if (!mounted) return;
      // Der Abschlussbildschirm ersetzt diesen: Zurückzugehen gäbe es nichts.
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const AccountDeletedScreen(),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _running = false;
        // Wie weit es gekommen ist — nicht „ein Teil ist noch da".
        _error = l10n.accountPartialBody(_done ?? 0, _total);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final word = l10n.accountDelete2TypeWord;

    return Scaffold(
      backgroundColor: AtemColors.base,
      appBar: AppBar(
        backgroundColor: AtemColors.base,
        title: Text(l10n.accountDelete,
            style: AtemType.titleMedium.of(context)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AtemSpacing.screenPadding,
                    0, AtemSpacing.screenPadding, 24),
                children: [
                  Text(l10n.accountDelete2Title,
                      style: AtemType.titleLarge.of(context)),
                  const SizedBox(height: 12),
                  // Jahre, Monate, Einheiten und eigene Übungen — die
                  // zweite Stufe wiederholt in Zahlen, was verschwindet.
                  Text(
                    l10n.accountDelete2Body(_years, _months, _sessions,
                        _ownExercises),
                    style: AtemType.body.of(context),
                  ),
                  const SizedBox(height: 28),
                  AtemFieldLabel(
                    label: l10n.accountDelete2TypeLabel,
                    hint: l10n.accountDelete2TypeLabel,
                  ),
                  if (_running) ...[
                    const SizedBox(height: 20),
                    // Nicht abbrechbar — also muss sie sagen, wo sie steht.
                    Semantics(
                      liveRegion: true,
                      label: '${l10n.accountDeleting}. '
                          '${l10n.accountPartialBody(_done ?? 0, _total)}',
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.accountDeleting,
                                style: AtemType.labelMedium.of(context)),
                            const SizedBox(height: 8),
                            AtemProgressBar.share(
                              value: _total == 0
                                  ? 0
                                  : (_done ?? 0) / _total,
                              semanticLabel: '',
                              accent: AtemColors.magenta,
                            ),
                            const SizedBox(height: 8),
                            Text(l10n.accountDeletingWait,
                                style: AtemType.labelMicro.of(context)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  AtemTextField(
                    controller: _confirm,
                    semanticLabel: l10n.accountDelete2TypeLabel,
                    hint: word,
                    enabled: !_running,
                    // Keine automatische Großschreibung des ersten Buchstabens:
                    // Verlangt wird ein Wort in Versalien, und eine halbe
                    // Hilfe wäre hier eine Falle.
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AtemSpacing.screenPadding, 8, AtemSpacing.screenPadding, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AtemNoticeSlot(
                    notice: _error == null
                        ? null
                        : AtemNotice(
                            tone: AtemNoticeTone.error,
                            title: l10n.accountPartialTitle,
                            body: _error!,
                            semanticLabel:
                                '${l10n.accountPartialTitle}. $_error',
                            actionLabel: l10n.accountPartialResume,
                            onAction: _delete,
                          ),
                  ),
                  AtemButton.outline(
                    label: _running
                        ? l10n.accountDeleting
                        : l10n.accountDelete,
                    semanticLabel: _running
                        ? l10n.accountDeleting
                        : l10n.accountDelete,
                    accent: AtemColors.magenta,
                    size: AtemButtonSize.regular,
                    busy: _running,
                    onPressed: _matches(l10n) && !_running ? _delete : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Was danach kommt.
///
/// ## Warum es diesen Bildschirm gibt
///
/// Nach dem Löschen fällt die App auf die Anmeldung zurück. Genau dort
/// entstünde ein Missverständnis: Wer sich erneut anmeldet, ist **wieder
/// drin** — die Freischaltung steht in einer Liste, die zum Programm gehört
/// und nicht zum Konto, und die Regeln lassen niemanden sie bearbeiten.
///
/// Ohne diesen Bildschirm sähe das aus, als hätte das Löschen nicht
/// funktioniert. Mit ihm ist es eine Auskunft.
class AccountDeletedScreen extends ConsumerWidget {
  const AccountDeletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AtemColors.base,
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AtemSpacing.screenPadding),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 40),
                    Text(l10n.accountDoneTitle,
                        style: AtemType.titleLarge.of(context)),
                    const SizedBox(height: 10),
                    Text(l10n.accountDoneBody,
                        style: AtemType.body.of(context)),
                    const SizedBox(height: 28),
                    AtemNotice(
                      title: l10n.accountDoneAccessTitle,
                      body: l10n.accountDoneAccessBody,
                      semanticLabel: '${l10n.accountDoneAccessTitle}. '
                          '${l10n.accountDoneAccessBody}',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AtemButton.gradient(
                  label: l10n.accountDoneToLogin,
                  semanticLabel: l10n.accountDoneToLogin,
                  onPressed: () async {
                    // Abmelden bringt die App an den Anfang zurück. Das Konto
                    // ist bereits weg; das hier räumt nur den lokalen Rest.
                    await ref.read(authRepositoryProvider).signOut();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
