import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/firestore_training_goal_repository.dart';
import '../domain/briefing_question.dart';
import '../domain/training_goal.dart';
import '../domain/training_goal_repository.dart';

final trainingGoalRepositoryProvider = Provider<TrainingGoalRepository>(
  (ref) => FirestoreTrainingGoalRepository(FirebaseFirestore.instance),
);

/// Die Trainingsangaben des angemeldeten Kontos.
///
/// Ohne Anmeldung leer statt kaputt — wie Gewicht und Einstellungen.
final trainingGoalProvider = StreamProvider<TrainingGoal>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(TrainingGoal.empty);
  return ref.watch(trainingGoalRepositoryProvider).watch(userId);
});

/// Eine abgelehnte Antwort — sie steht im Block, nicht in einem Toast.
class BriefingSaveError {
  const BriefingSaveError({
    required this.question,
    required this.attempted,
    required this.previous,
    required this.retry,
  });

  final BriefingQuestion question;

  /// Was jemand gewählt hat, in Worten („Kraft 4×").
  final String attempted;

  /// Was stattdessen weiter gilt („Kraft 3×" oder „Offen").
  final String previous;

  final void Function() retry;
}

/// Was der Bildschirm über die letzte Handlung wissen muss.
class BriefingActivity {
  const BriefingActivity({this.saved, this.tick = 0, this.error});

  /// Die Frage, deren Antwort zuletzt geschrieben wurde — für den
  /// Speicher-Scan über ihrem Block.
  final BriefingQuestion? saved;

  /// Zählt jede Handlung, damit derselbe Block ein zweites Mal scannen kann.
  final int tick;

  final BriefingSaveError? error;
}

/// Schreibt Antworten — jede einzeln, optimistisch.
///
/// ## Optimistisch ohne Schattenstand
///
/// Firestore zeigt den eigenen Schreibvorgang sofort im Strom und nimmt
/// einen abgelehnten von selbst zurück. Der Controller hält deshalb keinen
/// eigenen Stand der Antworten, nur die Quittungen: welcher Block gerade
/// geschrieben hat, und welcher abgelehnt wurde. Die Auswahl „springt
/// sichtbar zurück" (Board 18, A6), weil der Strom zurückspringt.
///
/// ## Warum der Controller nichts übersetzt
///
/// Snackbar und Fehlertext brauchen Worte; die Worte gehören der
/// Oberfläche. [apply] gibt deshalb zurück, was weggefallen ist, und die
/// Oberfläche sagt es.
class TrainingGoalController extends Notifier<BriefingActivity> {
  @override
  BriefingActivity build() => const BriefingActivity();

  TrainingGoal get current =>
      ref.read(trainingGoalProvider).value ?? TrainingGoal.empty;

  /// Gibt eine Antwort. [edit] rechnet den nächsten Stand aus dem aktuellen;
  /// geschrieben wird die Differenz. Rückgabe: was mit ihr weggefallen ist,
  /// oder `null` — dann gibt es keine Snackbar.
  Removal? apply(
    BriefingQuestion question,
    TrainingGoal Function(TrainingGoal) edit, {
    required String attempted,
    required String previous,
  }) {
    final before = current;
    final after = edit(before);
    final changes = before.diff(after);
    if (changes.isEmpty) return null;

    state = BriefingActivity(saved: question, tick: state.tick + 1);
    _write(
      changes,
      onError: () => state = BriefingActivity(
        saved: state.saved,
        tick: state.tick,
        error: BriefingSaveError(
          question: question,
          attempted: attempted,
          previous: previous,
          retry: () => apply(
            question,
            edit,
            attempted: attempted,
            previous: previous,
          ),
        ),
      ),
    );
    return TrainingGoal.removedBy(before, after);
  }

  /// Stellt einen früheren Stand wieder her — „Rückgängig". Die alten
  /// Antwortdaten kommen mit: Ein zurückgeholtes „Kraft 3×" ist die Angabe
  /// vom 14. Sept, nicht eine neue von heute.
  void restore(TrainingGoal target) {
    final changes = current.diff(target);
    if (changes.isEmpty) return;
    state = BriefingActivity(tick: state.tick + 1);
    _write(changes, answeredAt: target.answeredAt);
  }

  /// „Alle Angaben entfernen". Rückgabe: der Stand davor, für Rückgängig.
  TrainingGoal clearAll() {
    final before = current;
    final userId = ref.read(currentUserIdProvider);
    state = BriefingActivity(tick: state.tick + 1);
    if (userId != null) {
      ref.read(trainingGoalRepositoryProvider).clear(userId).ignore();
    }
    return before;
  }

  /// Die Fehlerzeile steht bis zum nächsten Tippen.
  void dismissError() {
    if (state.error == null) return;
    state = BriefingActivity(saved: state.saved, tick: state.tick);
  }

  void _write(
    Map<String, Object?> changes, {
    Map<String, DateTime> answeredAt = const {},
    void Function()? onError,
  }) {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    // Nicht abwarten: Offline steht die Antwort sofort da und der
    // Schreibvorgang in der Warteschlange. Nur eine Ablehnung meldet sich.
    ref
        .read(trainingGoalRepositoryProvider)
        .write(userId, changes, answeredAt: answeredAt)
        .then<void>((_) {}, onError: (Object _) {
      if (ref.mounted) onError?.call();
    });
  }
}

final trainingGoalControllerProvider =
    NotifierProvider<TrainingGoalController, BriefingActivity>(
  TrainingGoalController.new,
);
