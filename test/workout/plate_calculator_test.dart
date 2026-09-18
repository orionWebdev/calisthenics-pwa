import 'package:atem/core/domain/plate_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<(double, int)> side(PlateLoading l) =>
      [for (final p in l.perSide) (p.plateKg, p.count)];

  test('100 kg: je Seite 25 + 15', () {
    final l = PlateCalculator.solve(100);
    expect(side(l), [(25.0, 1), (15.0, 1)]);
    expect(l.loadedKg, 100);
    expect(l.isExact, isTrue);
  });

  test('60 kg: je Seite 20', () {
    expect(side(PlateCalculator.solve(60)), [(20.0, 1)]);
  });

  test('101 kg: 1 kg Rest, belegt wird 100', () {
    final l = PlateCalculator.solve(101);
    expect(l.loadedKg, 100);
    expect(l.remainderKg, 1);
    expect(l.isExact, isFalse);
  });

  test('20 kg: leere Stange', () {
    final l = PlateCalculator.solve(20);
    expect(l.isEmptyBar, isTrue);
    expect(l.remainderKg, 0);
  });

  test('15 kg an der 20-kg-Stange: leichter als die Stange', () {
    final l = PlateCalculator.solve(15);
    expect(l.belowBar, isTrue);
    expect(l.perSide, isEmpty);
  });

  test('142,5 kg: 25 + 25 + 10 + 1,25 je Seite, ohne Gleitkommarest', () {
    final l = PlateCalculator.solve(142.5);
    expect(side(l), [(25.0, 2), (10.0, 1), (1.25, 1)]);
    expect(l.remainderKg, 0);
  });

  test('2,5 + 1,25 geht exakt auf', () {
    final l = PlateCalculator.solve(27.5);
    expect(side(l), [(2.5, 1), (1.25, 1)]);
    expect(l.remainderKg, 0);
  });

  test('andere Stangen: 15 und 10 kg', () {
    expect(side(PlateCalculator.solve(55, barKg: 15)), [(20.0, 1)]);
    expect(side(PlateCalculator.solve(40, barKg: 10)), [(15.0, 1)]);
  });

  test('sidePlates zählt jede Scheibe einzeln, schwerste zuerst', () {
    expect(PlateCalculator.solve(142.5).sidePlates, [25, 25, 10, 1.25]);
  });
}
