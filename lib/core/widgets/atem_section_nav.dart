import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'atem_tab_theme.dart';
import 'atem_tappable.dart';

/// Ein Thema eines One-Pagers.
///
/// [label] steht in der Ortszeile **und ist zugleich die Überschrift des
/// Themas** — deshalb trägt der Inhalt seinen Namen kein zweites Mal
/// (Board 13, Entscheidung 6).
@immutable
class AtemSection {
  const AtemSection({required this.label, required this.child});

  /// Der Name in der Ortszeile. Kommt aus dem ARB, nie als Literal.
  final String label;

  /// Der Inhalt — **nicht scrollend**. Die Seite scrollt als Ganzes.
  final Widget child;
}

/// Die **Ortszeile** — eine Navigation, die nie ein Wort abschneidet.
///
/// ## Warum ein Wort und nicht vier
///
/// Vier Themen passen als vier Wörter auf 361 dp nicht nebeneinander, bei
/// 200 % nicht einmal zwei. Eine seitlich scrollende Reiterleiste scheitert
/// genau am Grenzfall: Sie verstümmelt ihre eigenen Beschriftungen
/// ausgerechnet dort, wo sie am wichtigsten sind (Board 13, Entscheidung 1).
/// Symbole statt Wörter fallen aus, weil „Verlauf" und „Auswertung" als
/// Diagramm gegen Diagramm nicht unterscheidbar sind (Entscheidung 2).
///
/// Die Zeile zeigt deshalb **immer nur ein Wort** — das, in dem man steht —
/// und hält die anderen einen Tipp entfernt als vollständige Wörter in einer
/// Liste, die vertikal wachsen darf. Damit existiert das Platzproblem nicht
/// mehr, bei keiner Schriftgrösse.
///
/// ## Vier Träger, Farbe ist der letzte
///
/// 1. **Das Wort** — welches Thema. `titleMedium`, weiss, nie gekürzt.
/// 2. **Der Zähler** „2 / 4" — die Position, farbunabhängig.
/// 3. **Der Chevron** — sagt „öffnet sich", nicht „scrollt seitlich".
/// 4. **Die Marken** — wie viele es gibt und wie weit man im Thema ist.
///    Erledigt grau gefüllt, aktuell im Bereichston mitwachsend, offen leer:
///    drei **Formzustände**, nicht drei Farben.
///
/// ## Sie blendet nie aus
///
/// Seit es keinen Tab-Kopf mehr gibt, ist sie das Einzige, was „wo bin ich"
/// beantwortet — und der Markenstreifen macht sie zum Fortschrittsanzeiger.
/// Ein Fortschritt, der sich beim Scrollen versteckt, ist keiner
/// (Entscheidung 7).
///
/// Deckende Fläche, **kein Blur**: Sie sitzt über dem teuersten Scrollbereich
/// der App, und `surfaceSolid` ist bereits Tokenfläche (Entscheidung 8).
class AtemSectionBar extends StatelessWidget {
  const AtemSectionBar({
    super.key,
    required this.labels,
    required this.current,
    required this.progress,
    required this.open,
    required this.onToggle,
    required this.onPick,
    required this.barSemanticLabel,
    required this.jumpSemanticLabel,
    required this.hereLabel,
    this.accent,
    this.pulse,
    this.horizontalPadding = AtemSpacing.screenPadding,
  });

  final List<String> labels;

  /// Das Thema, in dem die Seite steht.
  final int current;

  /// Wie weit dieses Thema gelesen ist, 0 bis 1 — die Füllung seiner Marke.
  final double progress;

  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<int> onPick;

  /// „Thema Verlauf, 2 von 4. Öffnet die Themenliste."
  final String barSemanticLabel;

  /// „Zu {name} springen, {n} von {total}".
  final String Function(String label, int index, int total) jumpSemanticLabel;

  /// „HIER" — echter Text neben dem Haken, kein blosses Zeichen.
  final String hereLabel;

  /// `null` nimmt den Ton des Bereichs.
  final Color? accent;

  /// Die Quittung des Themenwechsels — eine 2-dp-Linie an der Unterkante,
  /// 0 → 1 → 0. `null` heisst: keine.
  ///
  /// Raum wirkt beim langsamen Lesen; beim schnellen Wischen rauscht die
  /// Zäsur in unter 60 ms vorbei. Für diesen Fall quittiert die Zeile den
  /// Wechsel (Board 17, Entscheidung 16).
  final Animation<double>? pulse;

  final double horizontalPadding;

  /// Schriftgrösse des Themennamens.
  static const nameSize = 16.0;

  /// Stärke der Pulslinie.
  static const pulseHeight = 2.0;

  /// Höhe des Markenstreifens.
  ///
  /// Das Board setzt 2 dp. Am Gerät war der Streifen damit kaum zu erkennen —
  /// er sitzt an der Unterkante der Zeile, und `#16161F` auf `#0B0C14` hat
  /// fast keinen Abstand. Auf Rückmeldung des Nutzers (20.09.2026) auf 4 dp,
  /// und der Track trägt `border` statt `track`: Ein Fortschrittsanzeiger,
  /// den man suchen muss, ist keiner.
  static const markHeight = 4.0;

  /// Die Marke des aktuellen Themas ist nie ganz leer — sonst sähe das
  /// laufende Thema aus wie ein noch nicht besuchtes.
  static const minMarkFill = 0.04;

  static const _markGap = 4.0;

  /// Wie hoch die Zeile bei der gegebenen Schriftskalierung baut.
  ///
  /// Die geheftete Kopfzeile braucht ihre Höhe **vor** dem Layout — deshalb
  /// als Rechnung und nicht als Messung. 50 dp bei 100 %, 69 dp bei 200 %.
  static double extentOf(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(nameSize);
    return math.max(48, scaled * 1.35 + 24) + markHeight;
  }

  /// Höhe einer Zeile der Sprungliste — 48 dp bei 100 %, rund 68 bei 200 %.
  static double jumpRowOf(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(14);
    return math.max(48, scaled * 1.35 + 30);
  }

  @override
  Widget build(BuildContext context) {
    final tone = accent ?? AtemTabTheme.of(context);
    final rowHeight = extentOf(context) - markHeight;

    final beat = pulse;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AtemColors.surfaceSolid,
        // Dauerhaft, nicht erst beim Scrollen: Unter der Zeile läuft immer
        // Inhalt durch.
        border: Border(bottom: BorderSide(color: AtemColors.border)),
      ),
      child: _WithPulse(
        pulse: beat,
        tone: tone,
        child: AtemTappable(
        onTap: onToggle,
        semanticLabel: barSemanticLabel,
        expanded: open,
        pressScale: AtemPressScale.none,
        minTapSize: Size(0, rowHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: rowHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: _Word(
                        label: labels[current],
                        index: current,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${current + 1} / ${labels.length}',
                      style: AtemType.labelMicro.of(context).copyWith(
                            fontFeatures: const [
                              ui.FontFeature.tabularFigures()
                            ],
                          ),
                    ),
                    const SizedBox(width: 8),
                    _Chevron(open: open),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++) ...[
                    if (i > 0) const SizedBox(width: _markGap),
                    Expanded(
                      child: _Mark(
                        fill: i < current
                            ? 1.0
                            : i == current
                                ? math.max(minMarkFill, progress)
                                : 0.0,
                        done: i < current,
                        tone: tone,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

/// Die Pulslinie liegt **über** der Zeile statt in ihr: Als weiteres Kind
/// einer Spalte hätte sie die Zeile um 2 dp wachsen lassen — und die
/// geheftete Kopfzeile muss ihre Höhe vor dem Layout kennen.
class _WithPulse extends StatelessWidget {
  const _WithPulse({
    required this.pulse,
    required this.tone,
    required this.child,
  });

  final Animation<double>? pulse;
  final Color tone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final beat = pulse;
    if (beat == null) return child;

    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: AtemSectionBar.pulseHeight,
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: beat,
              builder: (context, _) => beat.value == 0
                  ? const SizedBox.shrink()
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            tone.withValues(alpha: 0),
                            tone.withValues(alpha: beat.value),
                            tone.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Das Wort wechselt, es springt nicht: Das alte geht 4 dp nach oben und
/// blendet aus, das neue kommt 5 dp von unten und blendet ein.
class _Word extends StatefulWidget {
  const _Word({required this.label, required this.index});

  final String label;
  final int index;

  @override
  State<_Word> createState() => _WordState();
}

class _WordState extends State<_Word> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );

  String? _previous;

  @override
  void didUpdateWidget(_Word old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _previous = old.label;
    if (AtemMotion.reduced(context)) {
      _c.value = 1;
      _previous = null;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = AtemType.titleMedium.of(context).copyWith(
          fontSize: AtemSectionBar.nameSize,
          fontWeight: FontWeight.w600,
          color: AtemColors.textPrimary,
        );

    Widget word(String text) => Text(
          text,
          maxLines: 1,
          softWrap: false,
          // Nie ellipsiert, nie verkleinert — das ist der ganze Punkt der
          // Ortszeile.
          style: style,
        );

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_c.value);
        final previous = _previous;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (previous != null && t < 1)
              Opacity(
                opacity: 1 - t,
                child: Transform.translate(
                  offset: Offset(0, -4 * t),
                  child: word(previous),
                ),
              ),
            Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 5 * (1 - t)),
                child: word(widget.label),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Sagt „öffnet sich", nicht „scrollt seitlich".
class _Chevron extends StatelessWidget {
  const _Chevron({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: AnimatedRotation(
          turns: open ? 0.5 : 0,
          duration: AtemMotion.duration(
              context, const Duration(milliseconds: 200)),
          curve: Curves.easeOut,
          child: const CustomPaint(
            size: Size(11, 7),
            painter: _ChevronPainter(),
          ),
        ),
      );
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(1, 1)
        ..lineTo(size.width / 2, size.height - 1.5)
        ..lineTo(size.width - 1, 1),
      Paint()
        ..color = AtemColors.textSecondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => false;
}

/// Eine Marke: wie viele Themen es gibt, und wie weit das laufende gelesen
/// ist. Drei Formzustände, nicht drei Farben.
class _Mark extends StatelessWidget {
  const _Mark({required this.fill, required this.done, required this.tone});

  final double fill;
  final bool done;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final reduced = AtemMotion.reduced(context);

    return ExcludeSemantics(
      child: SizedBox(
        height: AtemSectionBar.markHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AtemColors.border,
            borderRadius:
                BorderRadius.circular(AtemSectionBar.markHeight),
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(AtemSectionBar.markHeight),
            // Die Breite folgt dem Scroll, 120 ms nachlaufend — bei
            // reduzierter Bewegung sofort. Sie bleibt in jedem Fall: Der
            // Fortschritt ist funktional, keine Zierde.
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: fill),
              duration: reduced
                  ? Duration.zero
                  : const Duration(milliseconds: 120),
              curve: Curves.linear,
              builder: (context, value, _) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: value.clamp(0.0, 1.0),
                  child: AnimatedContainer(
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: done ? AtemColors.textSecondary : tone,
                      borderRadius: BorderRadius.circular(
                          AtemSectionBar.markHeight),
                      boxShadow: done
                          ? const []
                          : [
                              BoxShadow(
                                color: tone.withValues(alpha: 0.6),
                                blurRadius: 6,
                              )
                            ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Die Sprungliste — **alle Wörter vollständig, eines je 48-dp-Zeile**.
///
/// Kein Bottom-Sheet: Ein Sheet käme von unten und verdeckte genau den
/// Inhalt, auf den man zielt. Die Liste klappt an derselben Kante auf, an der
/// die Navigation lebt (Board 13, Entscheidung 5).
class AtemSectionJumpList extends StatelessWidget {
  const AtemSectionJumpList({
    super.key,
    required this.labels,
    required this.current,
    required this.onPick,
    required this.semanticLabel,
    required this.jumpSemanticLabel,
    required this.hereLabel,
    this.horizontalPadding = AtemSpacing.screenPadding,
  });

  final List<String> labels;
  final int current;
  final ValueChanged<int> onPick;

  /// „Springen zu" — benennt die Gruppe.
  final String semanticLabel;
  final String Function(String label, int index, int total) jumpSemanticLabel;
  final String hereLabel;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final rowHeight = AtemSectionBar.jumpRowOf(context);

    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AtemColors.surfaceSolid,
          border: Border(bottom: BorderSide(color: AtemColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < labels.length; i++)
              _JumpRow(
                label: labels[i],
                semanticLabel:
                    jumpSemanticLabel(labels[i], i + 1, labels.length),
                hereLabel: hereLabel,
                selected: i == current,
                height: rowHeight,
                horizontalPadding: horizontalPadding,
                onTap: () => onPick(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _JumpRow extends StatelessWidget {
  const _JumpRow({
    required this.label,
    required this.semanticLabel,
    required this.hereLabel,
    required this.selected,
    required this.height,
    required this.horizontalPadding,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final String hereLabel;
  final bool selected;
  final double height;
  final double horizontalPadding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AtemTappable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      pressScale: AtemPressScale.none,
      minTapSize: Size(0, height),
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AtemColors.gridLine)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AtemType.labelSmall.of(context).copyWith(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? AtemColors.textPrimary
                          : AtemColors.textTertiary,
                    ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 12),
              // **Echter Text, nicht nur ein Haken** — Farbe und Glyph
              // allein tragen keinen Zustand.
              //
              // Das Board setzt hier 10 sp. Das unterschreitet die
              // Mindestgrösse für informationstragenden Text (CLAUDE.md,
              // „≥ 12 sp effektiv"), und die Tokenregel steht in der
              // Reihenfolge der Wahrheit über dem Board. Deshalb
              // `labelMicro` statt `labelDeco` — Mono, gesperrt, cyan wie
              // vorgesehen, nur zwei Punkt grösser.
              Text(
                hereLabel,
                style: AtemType.labelMicro
                    .of(context)
                    .copyWith(color: AtemColors.cyan),
              ),
              const SizedBox(width: 8),
              const CustomPaint(
                size: Size(13, 10),
                painter: _CheckPainter(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(1, size.height / 2)
        ..lineTo(size.width * 0.38, size.height - 1)
        ..lineTo(size.width - 1, 1),
      Paint()
        ..color = AtemColors.cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => false;
}

/// Die Zäsur zwischen zwei Themen — **die einzige Stelle der Seite, an der
/// nichts steht** (Board 17, Abschnitt C).
///
/// Hairline über die volle Breite, darüber ein 2-dp-Segment über 72 % im
/// Bereichston, das nach beiden Seiten ausläuft, plus eine unscharfe Kopie
/// als Schein. Beim schnellen Wischen bleibt der helle Kern als Blitz
/// sichtbar; sie selbst bewegt sich nicht.
///
/// ## 65 dp, und zwar asymmetrisch
///
/// Bis zum 21.09.2026 waren es 44 dp, gleichmässig verteilt. Das las sich wie
/// eine weitere Trennlinie in einer Liste — und davon hat die Seite viele.
/// Jetzt liegen **40 dp über und 24 dp unter** der Linie. Durch die
/// Asymmetrie gehört sie sichtbar zum **folgenden** Thema, nach derselben
/// Regel, nach der eine Überschrift mehr Abstand nach oben hat als nach
/// unten. Wären die Abstände gleich, schwebte die Fuge zwischen zwei Themen
/// und gehörte zu keinem.
///
/// 65 dp sind rund 9 % einer Bildschirmhöhe: genug, dass nie zwei Themen
/// ohne Pause gleichzeitig „anfangen" wirken, und zu wenig, um als leerer
/// Bildschirm zu lesen — über oder unter der Zäsur steht immer Inhalt.
///
/// ## Vollbreit
///
/// Die Hairline läuft von Kante zu Kante, während jeder Inhalt 16 dp Rand
/// hat. Sie ist damit das einzige randlose Element der Seite: ein Schnitt,
/// keine Trennlinie.
///
/// Nach dem letzten Thema ([end]) nur die Hairline, ohne Segment, und mit
/// getauschten Abständen — 24 dp darüber, 40 dp darunter. **Ende statt
/// Ankündigung.**
///
/// Rein dekorativ und stumm: Den Themenwechsel sagt die Ortszeile an, nicht
/// die Fuge — sonst wäre dasselbe Ereignis zweimal hörbar (Entscheidung 14).
class AtemSectionSeam extends StatelessWidget {
  const AtemSectionSeam({super.key, this.accent, this.end = false});

  /// `null` nimmt den Ton des Bereichs.
  final Color? accent;

  /// Der Abschluss nach dem letzten Thema.
  final bool end;

  /// Luft über der Linie — sie gehört noch dem Thema darüber.
  static const airTop = 40.0;

  /// Luft unter der Linie, bis zum schwersten Block des neuen Themas.
  static const airBottom = 24.0;

  static const height = airTop + airBottom + 1;
  static const endHeight = height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _SeamPainter(
              end ? null : (accent ?? AtemTabTheme.of(context)),
              end ? airBottom : airTop,
            ),
          ),
        ),
      );
}

class _SeamPainter extends CustomPainter {
  const _SeamPainter(this.accent, this.airTop);

  /// `null` zeichnet nur die Hairline — das Seitenende.
  final Color? accent;

  /// Wo die Linie sitzt, von oben gemessen.
  final double airTop;

  @override
  void paint(Canvas canvas, Size size) {
    final y = airTop + 0.5;

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = AtemColors.border
        ..strokeWidth = 1,
    );

    final tone = accent;
    if (tone == null) return;

    // 72 % der Breite, mittig, nach beiden Seiten auf null auslaufend.
    final segment = Rect.fromLTWH(size.width * 0.14, y - 1,
        size.width * 0.72, 2);
    final shader = ui.Gradient.linear(
      Offset(segment.left, y),
      Offset(segment.right, y),
      [
        tone.withValues(alpha: 0.0),
        tone.withValues(alpha: 0.55),
        tone.withValues(alpha: 0.0),
      ],
      const [0.0, 0.5, 1.0],
    );

    canvas
      ..drawRect(
        segment,
        Paint()
          ..shader = shader
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
      )
      ..drawRect(segment, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_SeamPainter old) =>
      old.accent != accent || old.airTop != airTop;
}

/// Ein One-Pager aus Themen, über denen die [AtemSectionBar] klebt.
///
/// ## Was die Seite leistet
///
/// * Sie stapelt die Themen, getrennt durch [AtemSectionSeam], und schliesst
///   nach dem letzten mit der Endfuge ab.
/// * Sie heftet die Ortszeile an den oberen Rand — **immer**, ohne
///   Ausblenden beim Scrollen.
/// * Sie rechnet aus dem Scrollstand zwei Dinge: in welchem Thema man steht,
///   und wie weit man darin ist. Das Erste wechselt das Wort, das Zweite
///   füllt die Marke.
/// * Ein Tipp öffnet die Sprungliste, eine Auswahl scrollt an den Anfang des
///   Themas — genau unter die Zeile, nicht dahinter.
///
/// ## Woher die Seite weiss, wo ein Thema anfängt
///
/// Nicht aus einer Messung am Bildschirm. Ein Thema weit unter dem Rand wird
/// zwar gebaut und vermessen, bekommt vom Viewport aber **keine brauchbare
/// Lage**: Slivers hinter der Unterkante teilen sich denselben
/// Platzhalterversatz, damit ihre Reihenfolge stimmt. Wer sie mit
/// `localToGlobal` fragt, bekommt eine Zahl nahe null — und ein Sprung auf
/// „Pläne" landete wieder oben.
///
/// Stattdessen meldet jedes Thema beim Layout seinen `precedingScrollExtent`
/// und seine eigene Höhe. Beides ist exakt, unabhängig von der Sichtbarkeit:
/// der erste Wert ist das Sprungziel, der zweite der Nenner des
/// Lesefortschritts.
///
/// ## Der Themenwechsel wird angesagt
///
/// Ein Wechsel, den niemand ausgelöst hat — man hat nur gescrollt —, geht als
/// Ansage an den Screenreader, **gedrosselt** auf eine je Wechsel und
/// frühestens 400 ms nach der letzten. Ohne Drosselung stapelte schnelles
/// Durchwischen vier Ansagen hintereinander (Board 13, Entscheidung 14).
///
/// Bewusst über [SemanticsService] und nicht als `liveRegion` an der Zeile:
/// Das Board verbietet die Live-Region am Knopf selbst, weil sie dann bei
/// jedem Öffnen der Liste mitfeuerte.
class AtemSectionPage extends StatefulWidget {
  const AtemSectionPage({
    super.key,
    required this.sections,
    required this.barSemanticLabel,
    required this.jumpListLabel,
    required this.jumpSemanticLabel,
    required this.arrivedSemanticLabel,
    required this.hereLabel,
    this.selected = 0,
    this.onSelected,
    this.accent,
    this.bottomPadding = 130,
  });

  final List<AtemSection> sections;

  /// „Thema {name}, {n} von {total}. Öffnet die Themenliste."
  final String Function(String label, int index, int total) barSemanticLabel;

  /// „Springen zu".
  final String jumpListLabel;

  /// „Zu {name} springen, {n} von {total}".
  final String Function(String label, int index, int total) jumpSemanticLabel;

  /// „{name}, {n} von {total}" — die Ansage nach einem erscrollten Wechsel.
  final String Function(String label, int index, int total)
      arrivedSemanticLabel;

  final String hereLabel;

  /// Das Thema, das die Seite zeigen soll. Änderungen von aussen scrollen
  /// dorthin.
  final int selected;

  final ValueChanged<int>? onSelected;

  /// `null` nimmt den Ton des Bereichs.
  final Color? accent;

  /// Platz unter dem letzten Thema — die schwebende Leiste verdeckt sonst
  /// seine letzte Zeile.
  final double bottomPadding;

  /// Dauer eines Sprungs aus der Liste.
  static const jumpDuration = Duration(milliseconds: 420);

  /// Frühestens so lange nach der letzten Ansage kommt die nächste.
  static const announceGap = Duration(milliseconds: 400);

  /// Auf und wieder ab — die Quittung des Themenwechsels in der Ortszeile.
  static const pulseDuration = Duration(milliseconds: 480);

  @override
  State<AtemSectionPage> createState() => _AtemSectionPageState();
}

class _AtemSectionPageState extends State<AtemSectionPage>
    with TickerProviderStateMixin {
  final _scroll = ScrollController();

  /// Der Scrollstand, bei dem ein Thema oben steht — je Thema einer.
  late List<double> _offsets;

  /// Die Höhe je Thema — der Nenner des Lesefortschritts.
  late List<double> _heights;

  late int _active;

  /// Wie weit das laufende Thema gelesen ist, 0 bis 1.
  double _progress = 0;

  /// Das Ziel eines laufenden Sprungs. Solange es steht, zählt das Scrollen
  /// nicht mit.
  int? _target;

  double _barExtent = 0;
  bool _open = false;
  DateTime _lastAnnounced = DateTime.fromMillisecondsSinceEpoch(0);

  late final AnimationController _list = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    reverseDuration: const Duration(milliseconds: 160),
  );

  /// Die Quittung des Wechsels: 80 ms auf, 400 ms ab.
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: AtemSectionPage.pulseDuration,
  );

  late final Animation<double> _pulse = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 80,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeIn)),
      weight: 400,
    ),
  ]).animate(_beat);

  @override
  void initState() {
    super.initState();
    _sizeLists();
    _active = widget.selected.clamp(0, widget.sections.length - 1);
    _scroll.addListener(_spy);
    if (_active != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goTo(_active, animate: false);
      });
    }
  }

  void _sizeLists() {
    _offsets = List<double>.filled(widget.sections.length, 0);
    _heights = List<double>.filled(widget.sections.length, 1);
  }

  @override
  void didUpdateWidget(AtemSectionPage old) {
    super.didUpdateWidget(old);
    if (old.sections.length != widget.sections.length) _sizeLists();
    // Ein Sprung von aussen — aber nicht gegen den Finger.
    if (widget.selected != old.selected && widget.selected != _active) {
      final position = _scroll.hasClients ? _scroll.position : null;
      if (position != null && position.isScrollingNotifier.value) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goTo(widget.selected);
      });
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_spy);
    _scroll.dispose();
    _list.dispose();
    _beat.dispose();
    super.dispose();
  }

  /// Wo die Seite steht: Thema und Lesefortschritt darin.
  (int, double) _where() {
    if (!_scroll.hasClients) return (_active, _progress);
    final position = _scroll.position;
    if (!position.hasContentDimensions) return (_active, _progress);

    final atEnd = position.pixels >= position.maxScrollExtent - 1;
    // Am unteren Anschlag gewinnt das letzte Thema. Es ist womöglich zu kurz,
    // um je bis unter die Zeile zu steigen — ohne diese Regel bliebe seine
    // Marke für immer leer.
    if (atEnd) return (widget.sections.length - 1, 1.0);

    final line = position.pixels + _barExtent;
    var found = 0;
    for (var i = 0; i < _offsets.length; i++) {
      if (_offsets[i] <= line + 1) found = i;
    }
    // Die Zäsur zählt nicht als gelesen: Sonst stünde die Marke direkt nach
    // einem Sprung schon bei 6 %, obwohl noch keine Zeile gelesen ist.
    final lead = _leadOf(found);
    final height = _heights[found] - lead;
    final read =
        height <= 0 ? 1.0 : (line - _offsets[found] - lead) / height;
    return (found, read.clamp(0.0, 1.0));
  }

  /// Die Zäsur am Kopf eines Themas — das erste hat keine.
  double _leadOf(int index) => index == 0 ? 0 : AtemSectionSeam.height;

  void _spy() {
    if (_open) _closeList();
    if (_target != null) return;
    final (index, read) = _where();
    if (index == _active && (read - _progress).abs() < 0.005) return;

    final changed = index != _active;
    setState(() {
      _active = index;
      _progress = read;
    });
    if (changed) {
      widget.onSelected?.call(index);
      _announce(index);
      // **Nur beim Scrollen.** Ein Sprung aus der Liste hat seine eigene
      // Bewegung und sein eigenes Ziel; dort wäre der Puls die zweite
      // Antwort auf dieselbe Handlung. Bei reduzierter Bewegung entfällt er
      // ersatzlos — Wort, Zähler und Marke tragen den Wechsel dann allein.
      if (!AtemMotion.reduced(context)) _beat.forward(from: 0);
    }
  }

  /// Eine Ansage je Wechsel, frühestens 400 ms nach der letzten.
  void _announce(int index) {
    final now = DateTime.now();
    if (now.difference(_lastAnnounced) < AtemSectionPage.announceGap) return;
    _lastAnnounced = now;
    // `Assertiveness.polite` ist die Vorgabe — höflich, nicht unterbrechend,
    // wie das Board es verlangt.
    SemanticsService.sendAnnouncement(
      View.of(context),
      widget.arrivedSemanticLabel(
          widget.sections[index].label, index + 1, widget.sections.length),
      Directionality.of(context),
    );
  }

  void _toggleList() {
    setState(() => _open = !_open);
    if (_open) {
      _list.forward();
    } else {
      _list.reverse();
    }
  }

  void _closeList() {
    if (!_open) return;
    setState(() => _open = false);
    _list.reverse();
  }

  /// Scrollt an den Anfang eines Themas — unter die Zeile, nicht dahinter.
  Future<void> _goTo(int index, {bool animate = true}) async {
    _closeList();
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (!position.hasContentDimensions) return;

    // **Nicht bis zum ersten Block, sondern bis an die Linie.** Die
    // Hairline steht danach genau an der Unterkante der Ortszeile, darunter
    // 24 dp Luft, dann der schwerste Block des Themas — der Schnitt ist
    // Teil dessen, wo man gelandet ist (Board 17, Bewegungstabelle).
    final lead = _leadOf(index);
    final goal = (_offsets[index] +
            (lead == 0 ? 0 : AtemSectionSeam.airTop + 1) -
            _barExtent)
        .clamp(position.minScrollExtent, position.maxScrollExtent);

    setState(() {
      _active = index;
      _progress = 0;
      _target = index;
    });
    widget.onSelected?.call(index);

    if (!animate || AtemMotion.reduced(context)) {
      _scroll.jumpTo(goal);
    } else {
      await _scroll.animateTo(
        goal,
        duration: AtemSectionPage.jumpDuration,
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    setState(() => _target = null);
    final (i, read) = _where();
    setState(() {
      _active = i;
      _progress = read;
    });
  }

  @override
  Widget build(BuildContext context) {
    _barExtent = AtemSectionBar.extentOf(context);
    final accent = widget.accent ?? AtemTabTheme.of(context);
    final labels = [for (final s in widget.sections) s.label];

    return PopScope(
      // Die Zurück-Geste schliesst die Liste, ohne zu springen.
      canPop: !_open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeList();
      },
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _BarHeader(
                  extent: _barExtent,
                  builder: (context) => AtemSectionBar(
                    labels: labels,
                    current: _active,
                    progress: _progress,
                    open: _open,
                    onToggle: _toggleList,
                    onPick: _goTo,
                    barSemanticLabel: widget.barSemanticLabel(
                        labels[_active], _active + 1, labels.length),
                    jumpSemanticLabel: widget.jumpSemanticLabel,
                    hereLabel: widget.hereLabel,
                    accent: accent,
                    pulse: _pulse,
                  ),
                ),
              ),
              for (var i = 0; i < widget.sections.length; i++)
                _SectionSliver(
                  // Nur schreiben, nie `setState`: Die Meldung kommt mitten
                  // aus dem Layout.
                  onMeasured: (preceding, extent) {
                    _offsets[i] = preceding;
                    _heights[i] = extent;
                  },
                  // **Die Zäsur liegt im Thema, nicht dazwischen.** Sie
                  // gehört durch ihre Asymmetrie zum folgenden Thema (Board
                  // 17, Entscheidung 11) — also muss sie auch zu dessen
                  // Sliver gehören, sonst zeigte ein Sprung auf das Thema an
                  // der Zäsur vorbei und der Schnitt bliebe ungesehen.
                  child: i == 0
                      ? widget.sections[i].child
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AtemSectionSeam(accent: accent),
                            widget.sections[i].child,
                          ],
                        ),
                ),
              // Ende statt Ankündigung.
              SliverToBoxAdapter(
                child: AtemSectionSeam(accent: accent, end: true),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: widget.bottomPadding),
              ),
            ],
          ),
          // Die Liste liegt **über** dem Inhalt statt ihn zu schieben: Ein
          // Schieben unter einer gehefteten Zeile verrückte den Scrollstand,
          // auf den die Zeile selbst zeigt.
          if (_open || _list.value > 0)
            Positioned(
              top: _barExtent,
              left: 0,
              right: 0,
              bottom: 0,
              child: _ListOverlay(
                animation: _list,
                onDismiss: _closeList,
                child: AtemSectionJumpList(
                  labels: labels,
                  current: _active,
                  onPick: _goTo,
                  semanticLabel: widget.jumpListLabel,
                  jumpSemanticLabel: widget.jumpSemanticLabel,
                  hereLabel: widget.hereLabel,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Die aufklappende Liste samt der Fläche darunter, die sie wieder schliesst.
class _ListOverlay extends StatelessWidget {
  const _ListOverlay({
    required this.animation,
    required this.onDismiss,
    required this.child,
  });

  final Animation<double> animation;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final t = animation.value;
          if (t == 0) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: Curves.easeOutCubic.transform(t),
                  child: Opacity(opacity: t, child: child),
                ),
              ),
              Expanded(
                // Tipp **und** Wisch schliessen: Solange die Liste offen
                // ist, liegt sie über dem Inhalt, und eine Wischgeste
                // darunter meint „weg damit", nicht „scroll dahinter".
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDismiss,
                  onVerticalDragStart: (_) => onDismiss(),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          );
        },
      );
}

/// Die geheftete Ortszeile. Ihre Höhe steht fest — sie schrumpft nicht und
/// blendet nicht aus.
class _BarHeader extends SliverPersistentHeaderDelegate {
  const _BarHeader({required this.extent, required this.builder});

  final double extent;
  final WidgetBuilder builder;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset,
          bool overlapsContent) =>
      builder(context);

  @override
  bool shouldRebuild(_BarHeader old) => true;
}

/// Ein Thema, das beim Layout seinen Scrollanfang und seine Höhe meldet.
class _SectionSliver extends SingleChildRenderObjectWidget {
  const _SectionSliver({required this.onMeasured, required Widget super.child});

  final void Function(double preceding, double extent) onMeasured;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSectionSliver()..onMeasured = onMeasured;

  @override
  void updateRenderObject(
          BuildContext context, _RenderSectionSliver renderObject) =>
      renderObject.onMeasured = onMeasured;
}

class _RenderSectionSliver extends RenderSliverToBoxAdapter {
  void Function(double preceding, double extent)? onMeasured;

  @override
  void performLayout() {
    super.performLayout();
    onMeasured?.call(
      constraints.precedingScrollExtent,
      geometry?.scrollExtent ?? 0,
    );
  }
}
