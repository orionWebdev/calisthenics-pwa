// Prüft die Verträge aus docs/contracts/ über den Quelltext in lib/.
//
// Bewusst textbasiert und ohne Abhängigkeiten. Ein Analyzer-Plugin über
// analysis_server_plugin wäre genauer (es sieht Aufrufketten, dieses Skript
// nicht) — siehe docs/contracts/03-architecture.md. Bis das steht, ist das hier
// das CI-Tor.
//
// Aufruf:
//   dart run tool/check_conventions.dart            nur aktive Regeln
//   dart run tool/check_conventions.dart --all      auch stillgelegte, als Bericht
//   dart run tool/check_conventions.dart --details  mit Fundstellen
//
// Staffelung: Regeln mit Altlast stehen auf `active: false` und werden je Stufe
// scharf geschaltet. Der git diff dieser Liste ist der Nachweis.

import 'dart:io';

class Rule {
  const Rule({
    required this.id,
    required this.contract,
    required this.description,
    required this.active,
    required this.activateAt,
    required this.match,
    this.skipPath,
    this.wholeFile = false,
  });

  final String id;
  final String contract;
  final String description;

  /// Blockiert die Regel den Build?
  final bool active;

  /// Ab welcher Stufe soll sie scharf sein?
  final String activateAt;

  final RegExp match;

  /// Pfade, für die die Regel nicht gilt.
  final bool Function(String path)? skipPath;

  /// Über die ganze Datei prüfen statt zeilenweise.
  final bool wholeFile;
}

final rules = <Rule>[
  Rule(
    id: 'no_small_font_size',
    contract: '01-accessibility R1',
    description:
        'fontSize unter 12 — informationstragender Text muss lesbar sein',
    active: false,
    // Die Typenskala wird im Design-Gespräch 01 festgelegt; scharf,
    // sobald sie in den Primitiven umgesetzt ist.
    activateAt: 'Stufe 4',
    // Keine Ausnahme für core/theme: Die Token-Definitionen SIND die Schuld,
    // die in Stufe 3 auf die Dreier-Skala kollabiert.
    match: RegExp(r'fontSize:\s*(?:[0-9]|1[01])(?:\.[0-9]+)?\b'),
  ),
  Rule(
    id: 'no_raw_gesture_detector',
    contract: '01-accessibility R3',
    description:
        'Rohes GestureDetector/InkWell — nur AtemTappable macht antippbar',
    active: false,
    // AtemTappable existiert seit Stufe 4, aber die Screens nutzen ihn
    // erst nach ihrem Neuaufbau.
    activateAt: 'Stufe 5',
    match: RegExp(r'\b(GestureDetector|InkWell)\s*\('),
    skipPath: (p) => p.contains('/core/widgets/'),
  ),
  Rule(
    id: 'no_fitted_box_around_text',
    contract: '01-accessibility R5',
    description: 'FittedBox macht die Schriftskalierung des Nutzers zunichte',
    active: false,
    activateAt: 'Stufe 5',
    match: RegExp(r'\bFittedBox\s*\('),
  ),
  Rule(
    id: 'no_text_literal',
    contract: '02-i18n',
    description:
        'Textliteral im Widget — jeder sichtbare Text kommt aus dem ARB',
    active: false,
    // Nicht Stufe 3: Die Literale sitzen in den zwei Screens, die in
    // Stufe 5 ohnehin neu gebaut werden. Sie jetzt zu migrieren wäre
    // Arbeit für den Papierkorb.
    activateAt: 'Stufe 5',
    match: RegExp(
        r"""(?:Text\(\s*|TextSpan\(\s*text:\s*|semanticLabel:\s*)'[^']"""),
  ),
  Rule(
    id: 'no_flutter_in_domain',
    contract: '03-architecture',
    description:
        'package:flutter in domain/ — Präsentation gehört nicht in die Domäne',
    active: true,
    activateAt: 'Stufe 3 — erledigt',
    match: RegExp(r"import 'package:flutter/"),
    skipPath: (p) => !p.contains('/domain/'),
    wholeFile: true,
  ),
];

class Finding {
  Finding(this.rule, this.path, this.line, this.text);
  final Rule rule;
  final String path;
  final int line;
  final String text;
}

void main(List<String> args) {
  final showAll = args.contains('--all');
  final details = args.contains('--details');

  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final findings = <Finding>[];

  for (final file in files) {
    final path = file.path;
    final src = file.readAsStringSync();
    final lines = src.split('\n');

    for (final rule in rules) {
      if (rule.skipPath?.call(path) ?? false) continue;

      if (rule.wholeFile) {
        if (rule.match.hasMatch(src)) {
          findings.add(Finding(rule, path, 0, ''));
        }
        continue;
      }

      for (var i = 0; i < lines.length; i++) {
        if (rule.match.hasMatch(lines[i])) {
          findings.add(Finding(rule, path, i + 1, lines[i].trim()));
        }
      }
    }
  }

  var blocking = 0;
  stdout.writeln('Konventionsprüfung über ${files.length} Dateien\n');

  for (final rule in rules) {
    final hits = findings.where((f) => f.rule.id == rule.id).toList();
    if (!rule.active && !showAll && hits.isEmpty) continue;

    final mark = rule.active ? (hits.isEmpty ? 'OK   ' : 'FEHLER') : 'still ';
    stdout.writeln('$mark ${rule.id.padRight(30)} '
        '${hits.length.toString().padLeft(4)}  '
        '${rule.active ? rule.contract : 'scharf ab ${rule.activateAt}'}');

    if (details && hits.isNotEmpty) {
      for (final f in hits.take(12)) {
        final where = f.line == 0 ? f.path : '${f.path}:${f.line}';
        stdout.writeln('        $where  ${f.text}');
      }
      if (hits.length > 12) {
        stdout.writeln('        … und ${hits.length - 12} weitere');
      }
    }

    if (rule.active) blocking += hits.length;
  }

  stdout.writeln();
  if (blocking > 0) {
    stdout.writeln('$blocking Verstoß(e) gegen aktive Regeln.');
    exit(1);
  }
  stdout.writeln('Keine Verstöße gegen aktive Regeln.');
}
