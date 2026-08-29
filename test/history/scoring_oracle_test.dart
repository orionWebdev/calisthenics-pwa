import 'dart:convert';
import 'dart:io';

import 'package:atem/features/history/data/session_mapper.dart';
import 'package:atem/features/history/domain/readiness.dart';
import 'package:atem/features/history/domain/training_form.dart';
import 'package:atem/features/history/domain/training_load.dart';
import 'package:atem/features/history/domain/training_session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die Portierung gegen das Original.
///
/// `tool/scoring_oracle.mjs` führt das **echte** `js/views/sessions/scoring.js`
/// aus und schreibt Eingaben und Ergebnisse nach
/// `test/fixtures/scoring_oracle.json`. Dieser Test schickt dieselben Eingaben
/// durch die Dart-Fassung und vergleicht Zahl für Zahl.
///
/// Ohne diesen Vergleich wäre die Portierung eine Behauptung: Die Formeln sind
/// so verzweigt, dass jede von Hand nachgerechnete Stichprobe an den
/// interessanten Stellen vorbeigeht.
///
/// Erneuern nach jeder Änderung am JavaScript:
///
///     node tool/scoring_oracle.mjs test/fixtures/scoring_oracle.json
void main() {
  final oracle = jsonDecode(
    File('test/fixtures/scoring_oracle.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  final context = LoadContext(
    bodyWeightKg: (oracle['bodyWeightKg'] as num).toDouble(),
  );

  final raw = (oracle['sessions'] as List).cast<Map<String, dynamic>>();

  // Kein `expect` hier: Der Rumpf von `main` läuft beim Laden der Datei, wo
  // noch kein Test aktiv ist — eine fehlgeschlagene Erwartung erschiene dort
  // als Ladefehler ohne Zuordnung.
  final sessions = <TrainingSession>[
    for (var i = 0; i < raw.length; i++)
      SessionMapper.fromMap('s$i', {...raw[i], 'userId': 'u'})!,
  ];

  test('der Prüfbestand ist vollständig übersetzt', () {
    expect(sessions, hasLength(raw.length));
    expect(sessions.whereType<StrengthSession>(), isNotEmpty);
    expect(sessions.whereType<CardioSession>(), isNotEmpty);
    expect(sessions.whereType<RecoverySession>(), isNotEmpty);
  });

  test('die Rohlast jeder einzelnen Einheit stimmt überein', () {
    final expected = (oracle['loads'] as List).cast<Map<String, dynamic>>();

    for (var i = 0; i < sessions.length; i++) {
      final load = TrainingLoad.of(sessions[i], context);
      expect(
        load,
        closeTo((expected[i]['rawLoad'] as num).toDouble(), 1e-9),
        reason: 'Rohlast weicht ab bei Einheit $i: ${raw[i]}',
      );
    }
  });

  test('die Erkennung aktiver Erholung stimmt überein', () {
    final expected = (oracle['loads'] as List).cast<Map<String, dynamic>>();

    for (var i = 0; i < sessions.length; i++) {
      expect(
        TrainingLoad.isRecovery(sessions[i]),
        expected[i]['isRecovery'],
        reason: 'Erholungserkennung weicht ab bei Einheit $i: ${raw[i]}',
      );
    }
  });

  test('die Bewertungskurve stimmt an jeder Stützstelle', () {
    for (final point
        in (oracle['curve'] as List).cast<Map<String, dynamic>>()) {
      final acwr = (point['acwr'] as num).toDouble();
      final score = Readiness.mapScore(acwr);

      expect(score, point['score'],
          reason: 'Punktzahl weicht ab bei ACWR $acwr');
      expect(
        Readiness.mapZone(score, acwr).wire,
        point['zone'],
        reason: 'Zone weicht ab bei ACWR $acwr',
      );
    }
  });

  group('ACWR über den ganzen Zeitraum', () {
    for (final entry
        in (oracle['cases'] as List).cast<Map<String, dynamic>>()) {
      final day = entry['day'];
      final fatigue = entry['applyFatigue'] as bool;

      final dst = entry['dstInWindow'] as bool;

      test(
          'Tag $day, Ermüdungsabzug $fatigue${dst ? ' (Zeitumstellung im Fenster)' : ''}',
          () {
        final result = Readiness.compute(
          sessions,
          DateTime.parse(entry['referenceDate'] as String),
          context: context,
          applyFatigue: fatigue,
        );

        expect(result.acwr, entry['acwr'], reason: 'ACWR');
        expect(result.score, entry['readinessScore'], reason: 'Punktzahl');
        expect(result.zone?.wire, entry['zone'], reason: 'Zone');
        expect(result.fatiguePenalty, entry['fatiguePenalty'],
            reason: 'Ermüdungsabzug');
        expect(result.daysSinceLastSession, entry['daysSinceLastSession'],
            reason: 'Tage seit der letzten Einheit');
        expect(result.todayLoad,
            closeTo((entry['todayLoad'] as num).toDouble(), 1e-9),
            reason: 'Tageslast');
        expect(result.acuteLoad,
            closeTo((entry['acuteLoad'] as num).toDouble(), 1e-9),
            reason: 'akute Last');
        expect(result.chronicLoad,
            closeTo((entry['chronicLoad'] as num).toDouble(), 1e-9),
            reason: 'chronische Last');

        // Ohne Zeitumstellung im Fenster darf die Korrektur nichts ändern —
        // sonst wäre sie keine Korrektur, sondern eine zweite Rechnung.
        if (!dst) {
          final pwa = entry['pwa'] as Map<String, dynamic>;
          expect(result.acwr, pwa['acwr'],
              reason: 'Ohne Zeitumstellung müssen beide Fassungen '
                  'übereinstimmen');
        }
      });
    }
  });

  group('Form-Trend über den ganzen Zeitraum', () {
    for (final entry
        in (oracle['forms'] as List).cast<Map<String, dynamic>>()) {
      final day = entry['day'];
      final dst = entry['dstInWindow'] as bool;

      test('Tag $day${dst ? ' (Zeitumstellung im Fenster)' : ''}', () {
        final result = TrainingForm.compute(
          sessions,
          DateTime.parse(entry['referenceDate'] as String),
          context: context,
          // Das Orakel prüft die **Portierung**, nicht die App. Regeneration
          // bricht in der Vorgänger-App die Pause nicht; mit dem Vorgabewert
          // wäre jede Abweichung hier eine gewollte und der Test damit blind
          // für ungewollte. Was ATEM stattdessen tut, prüft
          // `recovery_activity_test.dart`.
          countRecoveryAsActivity: false,
        );

        expect(result.score, entry['formScore'], reason: 'Formwert');
        expect(result.zone?.wire, entry['zone'], reason: 'Zone');
        expect(result.consistency, entry['consistency'], reason: 'Konstanz');
        expect(result.loadLevel, entry['loadLevel'], reason: 'Lastentwicklung');
        expect(result.recency, entry['recency'], reason: 'Aktualität');
        expect(result.trend.wire, entry['trend'], reason: 'Richtung');
        expect(result.daysSinceLastSession, entry['daysSinceLastSession'],
            reason: 'Tage seit der letzten Einheit');

        if (!dst) {
          final pwa = entry['pwa'] as Map<String, dynamic>;
          expect(result.score, pwa['formScore'],
              reason: 'Ohne Zeitumstellung müssen beide Fassungen '
                  'übereinstimmen');
        }
      });
    }
  });
}
