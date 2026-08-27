import 'package:atem/features/dashboard/presentation/readiness_zone_ui.dart';
import 'package:atem/features/history/domain/readiness.dart';
import 'package:atem/l10n/gen/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Der Punkt, um den es geht: **Derselbe Wert, entgegengesetzte Bedeutung.**
void main() {
  late AppL10n l10n;

  setUp(() async {
    l10n = await AppL10n.delegate.load(const Locale('de'));
  });

  test('gleicher Punktwert, gegenteilige Zone — je nach ACWR', () {
    // 40 Punkte aus zu wenig Training …
    const score = 40;
    final zuWenig = Readiness.mapZone(score, 0.5);
    // … und 40 Punkte aus zu viel.
    final zuViel = Readiness.mapZone(score, 1.5);

    expect(zuWenig, ReadinessZone.formLoss);
    expect(zuViel, ReadinessZone.fatigued);
  });

  test('und deshalb gegenteilige Empfehlungen', () {
    final aufbauen = ReadinessZone.formLoss.tag(l10n);
    final zuruecknehmen = ReadinessZone.fatigued.tag(l10n);

    expect(aufbauen, isNot(zuruecknehmen));
    // Wer drei Wochen nicht trainiert hat, soll nicht „aktiv erholen".
    expect(aufbauen.toLowerCase(), contains('aufbauen'));
    expect(zuruecknehmen.toLowerCase(), contains('reduzieren'));
  });

  test('jede Zone hat Farbe, Name und Empfehlung', () {
    for (final zone in ReadinessZone.values) {
      expect(zone.label(l10n), isNotEmpty, reason: zone.name);
      expect(zone.tag(l10n), isNotEmpty, reason: zone.name);
      // Violet erreicht als Text kein AA — Vertrag R4.
      expect(zone.color, isNotNull, reason: zone.name);
    }
  });

  test('Überreizung rät ausdrücklich ab', () {
    expect(ReadinessZone.overreaching.tag(l10n).toLowerCase(),
        contains('nicht trainieren'));
  });
}
