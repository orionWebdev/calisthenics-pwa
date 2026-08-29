import 'dart:async';

import 'package:atem/features/auth/application/auth_providers.dart';
import 'package:atem/features/history/application/history_providers.dart';
import 'package:atem/features/history/application/pending_deletion.dart';
import 'package:atem/features/history/domain/session_draft.dart';
import 'package:atem/features/history/domain/session_patch.dart';
import 'package:atem/features/history/domain/session_repository.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Zählt Löschungen und lässt den Strom von Hand steuern.
class _Repo implements SessionRepository {
  _Repo(this._sessions);

  List<TrainingSession> _sessions;
  final deleted = <String>[];

  final _controller = StreamController<List<TrainingSession>>.broadcast();

  @override
  Stream<List<TrainingSession>> watchSessions(String userId) async* {
    yield _sessions;
    yield* _controller.stream;
  }

  @override
  Future<List<TrainingSession>> fetchSessions(String userId) async => _sessions;

  @override
  Future<String> saveSession(SessionDraft draft) async => 'neu';

  @override
  Stream<bool> watchFromCache(String userId) => Stream.value(false);

  @override
  Future<void> updateSession(String id, SessionPatch patch) async {}

  @override
  @override
  Future<void> updateSessionExercises(
      String id, List<LoggedExercise> exercises) async {}

  @override
  Future<void> deleteSession(String id) async {
    deleted.add(id);
    _sessions = [
      for (final s in _sessions)
        if (s.id != id) s,
    ];
    _controller.add(_sessions);
  }
}

StrengthSession _s(String id) => StrengthSession(
      id: id,
      userId: 'u',
      date: DateTime(2026, 8, 20),
      createdAt: DateTime(2026, 8, 20),
      bodyweight: false,
    );

void main() {
  late _Repo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _Repo([_s('a'), _s('b'), _s('c')]);
    container = ProviderContainer(overrides: [
      sessionRepositoryProvider.overrideWithValue(repo),
      currentUserIdProvider.overrideWithValue('u'),
    ]);
    addTearDown(container.dispose);

    // **Zuhören, nicht nur lesen.** Ohne aktiven Horcher verwirft Riverpod 3
    // einen nur gelesenen Provider sofort wieder — der Strom käme nie über
    // den Ladezustand hinaus.
    container.listen(sessionsProvider, (_, __) {}, fireImmediately: true);
  });

  Future<List<TrainingSession>> visible() async {
    // Den Strom einmal ankommen lassen, dann den abgeleiteten Wert lesen.
    await container.read(sessionStreamProvider.future);
    return container.read(sessionsProvider).value ?? const [];
  }

  test('das Fenster blendet die Einheit sofort aus', () async {
    expect(await visible(), hasLength(3));

    await container
        .read(pendingDeletionProvider.notifier)
        .start('b', label: 'Krafttraining');

    final rest = container.read(sessionsProvider).value!;
    expect(rest.map((s) => s.id), ['a', 'c']);
    expect(repo.deleted, isEmpty,
        reason: 'nur ausgeblendet, noch nicht gelöscht');
  });

  test('Widerruf bringt sie zurück, ohne neu zu laden', () async {
    await visible();
    await container
        .read(pendingDeletionProvider.notifier)
        .start('b', label: 'Krafttraining');
    expect(container.read(sessionsProvider).value, hasLength(2));

    container.read(pendingDeletionProvider.notifier).undo();

    expect(container.read(sessionsProvider).value!.map((s) => s.id),
        ['a', 'b', 'c']);
    expect(repo.deleted, isEmpty);
  });

  test('das Fenster ist dreissig Sekunden lang', () {
    expect(PendingDeletionController.window, const Duration(seconds: 30));
  });

  test('sofort ausführen löscht wirklich', () async {
    await visible();
    await container
        .read(pendingDeletionProvider.notifier)
        .start('b', label: 'x');
    await container.read(pendingDeletionProvider.notifier).commitNow();

    expect(repo.deleted, ['b']);
    expect(container.read(pendingDeletionProvider), isNull);
  });

  test('eine zweite Löschung führt die erste sofort aus', () async {
    await visible();
    final notifier = container.read(pendingDeletionProvider.notifier);

    await notifier.start('a', label: 'erste');
    await notifier.start('c', label: 'zweite');

    expect(repo.deleted, ['a'],
        reason: 'zwei Widerrufe nebeneinander wären nicht zuzuordnen');
    expect(container.read(pendingDeletionProvider)!.sessionId, 'c');
  });

  test('der Name überlebt für den Hinweis', () async {
    await visible();
    await container
        .read(pendingDeletionProvider.notifier)
        .start('b', label: 'Oberkörper A');
    expect(container.read(pendingDeletionProvider)!.label, 'Oberkörper A');
  });

  test('nach dem Ausführen ist nichts mehr schwebend', () async {
    await visible();
    final notifier = container.read(pendingDeletionProvider.notifier);
    await notifier.start('b', label: 'x');
    await notifier.commitNow();
    // Ein zweites Ausführen darf nicht noch einmal löschen.
    await notifier.commitNow();
    expect(repo.deleted, ['b']);
  });

  test('Widerruf nach dem Ausführen bringt nichts zurück', () async {
    await visible();
    final notifier = container.read(pendingDeletionProvider.notifier);
    await notifier.start('b', label: 'x');
    await notifier.commitNow();
    notifier.undo();
    expect(repo.deleted, ['b']);
    expect(container.read(pendingDeletionProvider), isNull);
  });
}
