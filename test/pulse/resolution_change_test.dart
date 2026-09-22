import 'package:atem/core/domain/pulse_profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wo eine Kurve ihre Dichte wechselt — und wo eben nicht.
///
/// Board 16, Nachtrag, „Wechselmarke · Regel": Ein Wechsel liegt nur vor,
/// wenn in **einer** Einheit zwei verschiedene gespeicherte Auflösungen
/// liegen. Ungleiche Abstände sind zuerst Lücken.
void main() {
  PulseProfile of(Map<int, int> curve, {int window = 3600}) => PulseProfile(
        secondsByBpm: const {120: 600},
        windowSeconds: window,
        curve: curve,
        slotSeconds: PulseProfile.fineSlotSeconds,
      );

  test('durchweg dieselbe Dichte hat keinen Wechsel', () {
    expect(of({for (var s = 0; s < 20; s++) s: 120}).resolutionChangeSlot,
        isNull);
  });

  test('erst minütlich, dann alle zehn Sekunden', () {
    // Schlitze 0, 6, 12, 18 (minütlich), dann 19, 20, 21, 22 (fein).
    final curve = {
      for (var i = 0; i < 4; i++) i * 6: 120,
      for (var s = 19; s < 24; s++) s: 150,
    };
    expect(of(curve).resolutionChangeSlot, 19);
  });

  test('ein einzelner grösserer Abstand ist eine Lücke, kein Wechsel', () {
    // Dicht, ein Sprung von vier Schlitzen (40 s — die Linie läuft durch),
    // dann wieder dicht. Nur **ein** Abstand dieser Grösse: keine zweite
    // Auflösung, nur eine Messpause.
    final curve = {
      for (var s = 0; s < 6; s++) s: 120,
      for (var s = 10; s < 16; s++) s: 130,
    };
    expect(of(curve).resolutionChangeSlot, isNull);
  });

  test('über eine echte Lücke hinweg gibt es keinen Wechsel', () {
    // Zwei Abschnitte, jeder für sich gleichmässig — dazwischen mehr als
    // eine Minute. Die Linie läuft dort nicht durch, also markiert nichts.
    final curve = {
      for (var s = 0; s < 6; s++) s: 120,
      for (var i = 0; i < 4; i++) 20 + i * 6: 130,
    };
    final profile = of(curve);
    expect(profile.curveSections.length, 2);
    expect(profile.resolutionChangeSlot, isNull);
  });

  test('eine zu kurze gröbere Strecke ist eine Lücke', () {
    // Nur ein einziger Abstand von sechs Schlitzen zwischen dichten Werten.
    final curve = {
      for (var s = 0; s < 5; s++) s: 120,
      10: 130,
      for (var s = 11; s < 16; s++) s: 140,
    };
    expect(of(curve).resolutionChangeSlot, isNull);
  });
}
