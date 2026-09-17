import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rendert einen Bildschirm **mit den echten Schriften** als PNG.
///
/// Widget-Tests zeichnen sonst mit der Testschrift Ahem — jedes Zeichen ein
/// Quadrat. Umbrüche und Abstände sehen damit anders aus als auf dem Gerät.
/// Dieses Werkzeug lädt Poppins, JetBrains Mono und die Material-Icons und
/// schreibt ein Bild, das dem Honor (361 dp, Schrift 1,15) nahekommt.
///
/// Nur für die Sichtprüfung gedacht, kein Golden-Test: Die Bilder landen in
/// einem Ordner ausserhalb des Repos (Umgebungsvariable `ATEM_RENDER_DIR`)
/// und werden nirgends verglichen. Ohne die Variable tut das Werkzeug nichts.
Future<void> loadRealFonts() async {
  Future<void> family(String name, List<String> assets) async {
    final loader = FontLoader(name);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await family('Poppins', [
    'assets/fonts/Poppins-Regular.ttf',
    'assets/fonts/Poppins-Medium.ttf',
    'assets/fonts/Poppins-SemiBold.ttf',
    'assets/fonts/Poppins-Bold.ttf',
  ]);
  await family('JetBrainsMono', [
    'assets/fonts/JetBrainsMono-Regular.ttf',
    'assets/fonts/JetBrainsMono-Medium.ttf',
    'assets/fonts/JetBrainsMono-SemiBold.ttf',
    'assets/fonts/JetBrainsMono-Bold.ttf',
  ]);
  const iconFont =
      '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  if (File(iconFont).existsSync()) {
    final bytes = File(iconFont).readAsBytesSync();
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }
}

/// Ob gerendert werden soll — nur mit gesetztem `ATEM_RENDER_DIR`.
bool get renderEnabled =>
    (Platform.environment['ATEM_RENDER_DIR'] ?? '').isNotEmpty;

/// Schreibt den aktuellen Baum unter [RepaintBoundary] [key] als PNG.
Future<void> writePng(WidgetTester tester, GlobalKey key, String name) async {
  final dir = Platform.environment['ATEM_RENDER_DIR'];
  if (dir == null || dir.isEmpty) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(dir).createSync(recursive: true);
    File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}
