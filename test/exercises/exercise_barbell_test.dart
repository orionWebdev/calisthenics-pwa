import 'package:atem/features/exercises/domain/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wo die Scheibenrechnung erscheint — und wo nicht.
///
/// Der Rechner war zuerst bei **jeder** Übung ohne Körpergewicht zu sehen, also
/// auch am Latzug und an der Kurzhantel. Dort ergibt er keinen Sinn: Man wählt
/// ein Gewicht, man steckt keines zusammen.
void main() {
  Exercise withEquipment(List<String> equipment) => Exercise(
        id: 'e',
        name: 'Übung',
        source: ExerciseSource.curated,
        equipment: equipment,
      );

  test('Langhantel bekommt die Rechnung', () {
    expect(withEquipment(['barbell']).usesBarbell, isTrue);
    expect(withEquipment(['barbell', 'bench']).usesBarbell, isTrue);
  });

  test('eine deutsch benannte eigene Übung ebenso', () {
    expect(withEquipment(['Langhantel']).usesBarbell, isTrue);
    expect(withEquipment(['langhantel, Bank']).usesBarbell, isTrue);
  });

  test('Kurzhantel bekommt sie nicht — trotz ähnlichem Wort', () {
    expect(withEquipment(['dumbbell']).usesBarbell, isFalse);
  });

  test('Maschine, Kettlebell und Klimmzugstange bekommen sie nicht', () {
    for (final item in ['machine', 'kettlebell', 'pull-up-bar', 'rings']) {
      expect(withEquipment([item]).usesBarbell, isFalse, reason: item);
    }
  });

  test('ohne Geräteangabe keine Rechnung', () {
    // 13 der 155 Übungen im Bestand nennen kein Gerät, und sie sind bis auf
    // zwei Körpergewichtsübungen. Raten wäre hier also meist falsch.
    expect(withEquipment(const []).usesBarbell, isFalse);
    expect(
      const Exercise(id: 'x', name: 'Eigene', source: ExerciseSource.own)
          .usesBarbell,
      isFalse,
    );
  });
}
