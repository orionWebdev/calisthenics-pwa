import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../history/domain/training_session.dart';
import '../../workout/domain/workout_clock.dart';

/// Was die Live-Uhr zwischen zwei Blicken aufhebt.
///
/// Board 11, B2/3: „Sie zählt weiter, wenn die App im Hintergrund liegt, und
/// übersteht einen Prozesskill: Startzeitpunkt und Pausenspanne liegen
/// persistent, die Anzeige wird daraus gerechnet."
///
/// Die Uhr ist die [WorkoutClock] aus dem Runner — zwei Zeitpunkte und eine
/// Pausensumme, kein Zähler. Sie hat denselben Fehler schon einmal behoben
/// (43 Minuten, gespeichert als 15).
class CardioLiveDraft {
  const CardioLiveDraft({
    required this.activity,
    required this.clock,
    this.distanceText = '',
  });

  final CardioActivity activity;
  final WorkoutClock clock;

  /// Die Distanz, wie sie getippt wurde — Text, damit ein halb getipptes
  /// „6," beim Wiederfinden nicht zu 6 wird.
  final String distanceText;

  CardioLiveDraft copyWith({WorkoutClock? clock, String? distanceText}) =>
      CardioLiveDraft(
        activity: activity,
        clock: clock ?? this.clock,
        distanceText: distanceText ?? this.distanceText,
      );

  Map<String, Object?> toJson() => {
        'activity': activity.wire,
        'clock': clock.toJson(),
        'distanceText': distanceText,
      };

  static CardioLiveDraft? fromJson(Map<String, Object?> json) {
    final activity = CardioActivity.fromWire(json['activity'] as String?);
    final clock = WorkoutClock.fromJson(
        (json['clock'] as Map?)?.cast<String, Object?>() ?? const {});
    if (activity == null || clock == null) return null;
    return CardioLiveDraft(
      activity: activity,
      clock: clock,
      distanceText: json['distanceText'] as String? ?? '',
    );
  }
}

/// Die Datei hinter der Live-Uhr — **eine je Gerät**, wie beim Runner.
///
/// Kein Firestore: Ein Zwischenstand ist kein Bestand. Er ändert sich jede
/// Sekunde und darf in keiner Auswertung auftauchen.
class CardioLiveStore {
  const CardioLiveStore();

  static const fileName = 'atem-cardio-live.json';

  /// Älter als das: nicht mehr anbieten. Eine Uhr, die seit zwölf Stunden
  /// läuft, misst kein Training mehr, sondern ein Vergessen.
  static const maxAge = Duration(hours: 12);

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<void> save(CardioLiveDraft draft) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(draft.toJson()));
  }

  Future<CardioLiveDraft?> read(DateTime now) async {
    try {
      final file = await _file();
      if (!file.existsSync()) return null;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, Object?>) return null;
      final draft = CardioLiveDraft.fromJson(json);
      if (draft == null) return null;
      if (now.difference(draft.clock.startedAt) > maxAge) {
        await clear();
        return null;
      }
      return draft;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final file = await _file();
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // Bleibt sie liegen, wird sie beim nächsten Lesen überschrieben oder
      // als zu alt verworfen.
    }
  }
}
