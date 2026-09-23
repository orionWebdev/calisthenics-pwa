import 'package:flutter/widgets.dart';

/// Ein Symbol aus einem SVG-Pfad im 24er-Raster — gezeichnet, nicht gesetzt.
///
/// ## Warum ein Pfad und kein Icon
///
/// Die Boards geben ihre Symbole als Pfade vor (`M6.5 6.5v11…`), als
/// Strich mit runden Enden. Material-Icons sind gefüllte Formen mit anderem
/// Gewicht — neben einem Board-Symbol sähe jedes wie aus einem anderen
/// Satz aus. Der Pfad wird deshalb unverändert übernommen, und ein Board
/// lässt sich Zeichen für Zeichen gegen den Code prüfen.
///
/// Verstanden wird, was die Boards benutzen: `M L H V C S A Z`, gross und
/// klein. Bögen gehen direkt über [Path.arcToPoint], das die Endpunktform
/// von SVG kennt.
///
/// Dekorativ: Das Symbol trägt nie allein eine Aussage und ist aus den
/// Semantics ausgeschlossen. Das Wort daneben spricht.
class AtemGlyph extends StatelessWidget {
  const AtemGlyph(
    this.path, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth = 1.9,
  });

  /// SVG-Pfaddaten im Raster 0–24.
  final String path;
  final Color color;
  final double size;

  /// Strichstärke im 24er-Raster; skaliert mit [size].
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _GlyphPainter(path, color, strokeWidth),
        ),
      );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.data, this.color, this.strokeWidth);

  final String data;
  final Color color;
  final double strokeWidth;

  static final _cache = <String, Path>{};

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    canvas.save();
    // Wie ein SVG: Was über das Raster ragt, ist abgeschnitten. Der Mond
    // „Abends" aus Board 18 reicht mit seinem grossen Bogen darüber hinaus
    // und ist im Board genau so gekappt.
    canvas.clipRect(Offset.zero & size);
    canvas.scale(scale);
    canvas.drawPath(
      _cache.putIfAbsent(data, () => parseSvgPath(data)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.data != data || old.color != color || old.strokeWidth != strokeWidth;
}

/// Liest SVG-Pfaddaten. Öffentlich, damit ein Test jeden Board-Pfad prüfen
/// kann, ohne zu zeichnen.
Path parseSvgPath(String d) {
  final tokens = RegExp(r'[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?')
      .allMatches(d)
      .map((m) => m.group(0)!)
      .toList();
  final path = Path();
  var i = 0;
  var cmd = '';
  var x = 0.0, y = 0.0;
  var startX = 0.0, startY = 0.0;
  // Letzter Kontrollpunkt für `S`.
  double? cx2, cy2;

  bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double next() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    if (isCmd(tokens[i])) cmd = tokens[i++];
    final rel = cmd == cmd.toLowerCase();
    final ox = rel ? x : 0.0;
    final oy = rel ? y : 0.0;
    switch (cmd.toUpperCase()) {
      case 'M':
        x = ox + next();
        y = oy + next();
        path.moveTo(x, y);
        startX = x;
        startY = y;
        // Weitere Paare nach einem M sind Linien.
        cmd = rel ? 'l' : 'L';
        cx2 = null;
      case 'L':
        x = ox + next();
        y = oy + next();
        path.lineTo(x, y);
        cx2 = null;
      case 'H':
        x = ox + next();
        path.lineTo(x, y);
        cx2 = null;
      case 'V':
        y = oy + next();
        path.lineTo(x, y);
        cx2 = null;
      case 'C':
        final x1 = ox + next(), y1 = oy + next();
        final x2 = ox + next(), y2 = oy + next();
        x = ox + next();
        y = oy + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        cx2 = x2;
        cy2 = y2;
      case 'S':
        final x1 = cx2 == null ? x : 2 * x - cx2;
        final y1 = cy2 == null ? y : 2 * y - cy2;
        final x2 = ox + next(), y2 = oy + next();
        x = ox + next();
        y = oy + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        cx2 = x2;
        cy2 = y2;
      case 'A':
        final rx = next(), ry = next(), rot = next();
        final large = next() != 0, sweep = next() != 0;
        x = ox + next();
        y = oy + next();
        path.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(rx, ry),
          rotation: rot,
          largeArc: large,
          clockwise: sweep,
        );
        cx2 = null;
      case 'Z':
        path.close();
        x = startX;
        y = startY;
        cx2 = null;
        // Z nimmt keine Zahlen; ein Folgebefehl muss ausdrücklich stehen.
        if (i < tokens.length && !isCmd(tokens[i])) {
          throw FormatException('Zahl nach Z in „$d"');
        }
      default:
        throw FormatException('Unbekannter Befehl „$cmd" in „$d"');
    }
  }
  return path;
}
