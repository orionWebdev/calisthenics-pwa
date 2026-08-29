import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/training_session.dart';

/// Übersetzt Firestore-Dokumente der Collection `sessions` in Domänenobjekte.
///
/// Diese Datei ist der einzige Ort, an dem Firestore-Typen die App betreten.
/// Sie hält die beiden Regeln aus `docs/contracts/04-firestore-schema.md`:
///
/// **R1 — niemals `as int`.** Dasselbe Feld trägt über die Dokumente hinweg
/// verschiedene Typen: `duration` ist in 111 Dokumenten integer und in 25
/// double, `distanceKm` in 36 double und in 8 integer. Ein `as int` stürzt auf
/// einem Fünftel des Bestands ab. Alles Numerische geht über [_num].
///
/// **R2 — `null` und „Feld fehlt" sind derselbe Fall.** Beide kommen vor, teils
/// im selben Feld: `notes` ist in 61 Dokumenten eine Zeichenkette, in 59
/// ausdrücklich `null` und in 16 gar nicht vorhanden.
///
/// Ein unbekanntes `type` wird nicht verworfen, sondern zu [UnknownSession] —
/// die PWA schreibt weiter in dieselbe Collection, und ein neuer Wert von dort
/// darf weder abstürzen noch stillschweigend Trainingseinheiten schlucken.
abstract final class SessionMapper {
  /// Baut eine Einheit aus Dokument-ID und Feldern.
  ///
  /// Gibt `null` zurück, wenn die vier Pflichtfelder fehlen — dann ist das
  /// Dokument kein `sessions`-Dokument, und Raten wäre schlimmer als Auslassen.
  static TrainingSession? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;

    final userId = _string(data['userId']);
    final date = _date(data['date']);
    final createdAt = _date(data['createdAt']) ?? date;
    if (userId == null || date == null || createdAt == null) return null;

    final duration = _duration(data);
    final notes = _string(data['notes']);
    final rawType = _string(data['type']);

    // In allen vier Arten vorhanden, in genau denselben Dokumenten.
    final rpe = _int(data['rpe']);
    final energy = _int(data['preWorkoutEnergy']);
    final feeling = _int(data['postWorkoutFeeling']);

    return switch (SessionKind.fromWire(rawType)) {
      SessionKind.strength || SessionKind.bodyweight => StrengthSession(
          id: id,
          userId: userId,
          date: date,
          createdAt: createdAt,
          duration: duration,
          notes: notes,
          bodyweight: rawType == SessionKind.bodyweight.wire,
          exercises: _exercises(data['exercises']),
          planId: _string(data['planId']),
          planName: _string(data['planName']),
          rpe: rpe,
          preWorkoutEnergy: energy,
          postWorkoutFeeling: feeling,
          discipline: _string(data['discipline']),
        ),
      SessionKind.cardio => () {
          final raw = _string(data['activityType']);
          final activity = CardioActivity.fromWire(raw);
          return CardioSession(
            id: id,
            userId: userId,
            date: date,
            createdAt: createdAt,
            duration: duration,
            notes: notes,
            rpe: rpe,
            preWorkoutEnergy: energy,
            postWorkoutFeeling: feeling,
            activity: activity,
            rawActivity: activity == null ? raw : null,
            distanceKm: _double(data['distanceKm']),
            // `pace` steht im Dokument, wird aber nicht gelesen: Tempo ist
            // Ausgabe aus Distanz und Dauer, nie ein eigenes Feld (Board 11).
            avgHr: _int(data['avgHr']),
            maxHr: _int(data['maxHr']),
            name: _string(data['name']),
          );
        }(),
      SessionKind.recovery => () {
          // Dasselbe Feld wie bei Cardio — die Vorgänger-App schreibt die
          // Art der Regeneration ebenfalls nach `activityType`.
          final raw = _string(data['activityType']);
          final kind = RecoveryKind.fromWire(raw);
          return RecoverySession(
            id: id,
            userId: userId,
            date: date,
            createdAt: createdAt,
            duration: duration,
            notes: notes,
            rpe: rpe,
            preWorkoutEnergy: energy,
            postWorkoutFeeling: feeling,
            recoveryKind: kind,
            rawKind: kind == null ? raw : null,
            name: _string(data['name']),
          );
        }(),
      null => UnknownSession(
          id: id,
          userId: userId,
          date: date,
          createdAt: createdAt,
          duration: duration,
          notes: notes,
          rpe: rpe,
          preWorkoutEnergy: energy,
          postWorkoutFeeling: feeling,
          rawType: rawType,
        ),
    };
  }

  static TrainingSession? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      fromMap(doc.id, doc.data());

  // ---------------------------------------------------------------- Helfer

  /// R1: Firestore liefert `num`. Nie `as int`, nie `as double`.
  static num? _num(Object? value) => value is num ? value : null;

  static double? _double(Object? value) => _num(value)?.toDouble();

  /// Rundet statt abzuschneiden — `rpe: 3.0` soll 3 ergeben, nicht 2.
  static int? _int(Object? value) => _num(value)?.round();

  /// R2: `null` und fehlend sind derselbe Fall. Leere Zeichenketten ebenso —
  /// ein leeres `notes` ist keine Notiz.
  static String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _date(Object? value) => switch (value) {
        Timestamp(:final toDate) => toDate(),
        DateTime() => value,
        // Die PWA hat früher ISO-Zeichenketten geschrieben. Im aktuellen
        // Bestand kommt das nicht mehr vor, kostet aber nichts.
        String() => DateTime.tryParse(value),
        _ => null,
      };

  /// `duration` steht in **Minuten**, `durationSec` in Sekunden — am Bestand
  /// geprüft: Wo beide vorkommen, ist das Verhältnis exakt 60.
  ///
  /// `durationSec` hat Vorrang, weil es ganzzahlig ist und keine
  /// Gleitkomma-Ungenauigkeit einschleppt.
  static Duration? _duration(Map<String, dynamic> data) {
    final seconds = _num(data['durationSec']);
    if (seconds != null) return Duration(seconds: seconds.round());

    final minutes = _num(data['duration']);
    if (minutes == null) return null;
    return Duration(milliseconds: (minutes * 60000).round());
  }

  static List<LoggedExercise> _exercises(Object? value) {
    if (value is! List) return const [];
    final out = <LoggedExercise>[];
    for (final entry in value) {
      if (entry is! Map) continue;
      final id = _string(entry['exerciseId']);
      if (id == null) continue;
      out.add(LoggedExercise(
        exerciseId: id,
        sets: _sets(entry['sets']),
        usesBodyweight: entry['usesBodyweight'] is bool
            ? entry['usesBodyweight'] as bool
            : null,
      ));
    }
    return out;
  }

  static List<LoggedSet> _sets(Object? value) {
    if (value is! List) return const [];
    final out = <LoggedSet>[];
    for (final entry in value) {
      // Leere Maps kommen im Bestand vor — ein angelegter, nie ausgefüllter
      // Satz. Er bleibt erhalten, damit die Satzzahl stimmt.
      if (entry is! Map) continue;
      out.add(LoggedSet(
        reps: _int(entry['reps']),
        weight: _double(entry['weight']),
        holdSeconds: _int(entry['holdSec']),
        rawType: _string(entry['type']),
      ));
    }
    return out;
  }
}
