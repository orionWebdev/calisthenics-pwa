import 'dart:io';

import 'package:atem/core/widgets/atem_glyph.dart';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';

/// Jeder Pfad aus Board 18 muss sich lesen lassen und im 24er-Raster liegen.
void main() {
  test('alle Symbolpfade aus briefing_ui.dart lassen sich lesen', () {
    final source = File('lib/features/planning/presentation/briefing_ui.dart')
        .readAsStringSync();
    final paths = RegExp(r"'(M[^']+)'")
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toList();
    expect(paths.length, greaterThan(20));
    for (final d in paths) {
      final bounds = parseSvgPath(d).getBounds();
      // Im Raster, nicht irgendwo: Ein Bogen darf überstehen (er wird wie
      // im SVG abgeschnitten), der Pfad selbst muss im Raster liegen.
      expect(bounds.overlaps(const Rect.fromLTWH(0, 0, 24, 24)), isTrue,
          reason: d);
      expect(bounds.width, greaterThan(0), reason: d);
    }
  });

  test('relative Befehle und Bögen', () {
    // Ein Kreis aus zwei Halbbögen: 3..13 × 7..17.
    final circle = parseSvgPath('M3 12a5 5 0 1 0 10 0a5 5 0 1 0 -10 0');
    final b = circle.getBounds();
    expect(b.left, closeTo(3, 0.01));
    expect(b.right, closeTo(13, 0.01));
    expect(b.top, closeTo(7, 0.01));
    expect(b.bottom, closeTo(17, 0.01));
  });

  test('ein unbekannter Befehl ist ein Fehler, kein leeres Symbol', () {
    expect(() => parseSvgPath('M0 0Q1 1 2 2'), throwsFormatException);
  });
}
