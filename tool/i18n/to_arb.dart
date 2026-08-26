// Wandelt den extrahierten PWA-Baum in ARB-Dateien.
//
//   dart run tool/i18n/to_arb.dart --ns common,nav,format,errors
//   dart run tool/i18n/to_arb.dart --list        Namespaces mit Anzahl
//
// Siehe docs/contracts/02-i18n.md. Bewusst NICHT alle 1.260 Schlüssel auf
// einmal: ungenutzte Getter verrotten und überfluten untranslated.json. Jeder
// Namespace kommt mit seinem Screen.

import 'dart:convert';
import 'dart:io';

/// Platzhalternamen, die als Zahl behandelt werden.
const _intPlaceholders = {
  'count',
  'n',
  'num',
  'total',
  'current',
  'sets',
  'reps',
  'days',
  'weeks',
  'minutes',
  'hours',
  'seconds',
  'interval',
  'active',
  'avg',
  'load',
  'step',
  'number',
  'rounds',
  'index',
  'week',
  'month',
  'year',
  'sec',
  'min',
};

/// Platzhalter mit Nachkommastellen.
const _numPlaceholders = {'distance', 'value', 'weight', 'pace', 'score'};

String camelFromPath(String dotted) {
  final parts = dotted.split('.');
  return parts.first +
      parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}

Map<String, Object> placeholdersFor(String message) {
  final names =
      RegExp(r'\{(\w+)\}').allMatches(message).map((m) => m.group(1)!).toSet();
  if (names.isEmpty) return {};

  final result = <String, Object>{};
  for (final name in names) {
    if (_intPlaceholders.contains(name)) {
      result[name] = {'type': 'int'};
    } else if (_numPlaceholders.contains(name)) {
      result[name] = {'type': 'num', 'format': 'decimalPattern'};
    } else {
      result[name] = {'type': 'String'};
    }
  }
  return result;
}

void main(List<String> args) {
  final de = jsonDecode(File('tool/i18n/legacy_de.json').readAsStringSync())
      as Map<String, dynamic>;
  final en = jsonDecode(File('tool/i18n/legacy_en.json').readAsStringSync())
      as Map<String, dynamic>;

  if (args.contains('--list')) {
    final counts = <String, int>{};
    for (final key in de.keys) {
      final ns = key.split('.').first;
      counts[ns] = (counts[ns] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      stdout.writeln('${e.key.padRight(20)} ${e.value}');
    }
    stdout.writeln('\nGesamt: ${de.length}');
    return;
  }

  final nsArg = args.firstWhere((a) => a.startsWith('--ns'),
      orElse: () => throw ArgumentError('--ns fehlt'));
  final namespaces = (nsArg.contains('=')
          ? nsArg.split('=')[1]
          : args[args.indexOf(nsArg) + 1])
      .split(',')
      .map((s) => s.trim())
      .toSet();

  final selected = de.keys
      .where((k) => namespaces.contains(k.split('.').first))
      .toList()
    ..sort();

  if (selected.isEmpty) {
    stderr.writeln('Keine Schlüssel für: ${namespaces.join(', ')}');
    exit(1);
  }

  // Kollisionsprüfung: Zwei Punktpfade dürfen nicht auf denselben
  // camelCase-Namen fallen. Gilt heute — die Prüfung hält das fest, damit ein
  // späterer Lauf nicht still Schlüssel überschreibt.
  final byCamel = <String, List<String>>{};
  for (final key in selected) {
    byCamel.putIfAbsent(camelFromPath(key), () => []).add(key);
  }
  final collisions = byCamel.entries.where((e) => e.value.length > 1);
  if (collisions.isNotEmpty) {
    stderr.writeln('camelCase-Kollisionen:');
    for (final c in collisions) {
      stderr.writeln('  ${c.key}: ${c.value.join(' / ')}');
    }
    exit(1);
  }

  final pluralCandidates = <String>[];

  Map<String, Object?> buildArb(Map<String, dynamic> source, String locale) {
    final arb = <String, Object?>{'@@locale': locale};
    for (final key in selected) {
      final camel = camelFromPath(key);
      final message = source[key] as String;
      arb[camel] = message;

      final placeholders = placeholdersFor(message);
      final meta = <String, Object>{};
      if (placeholders.isNotEmpty) meta['placeholders'] = placeholders;
      // Der Punktpfad bleibt erhalten — sonst weiß später niemand, woher der
      // Schlüssel stammt.
      meta['description'] = 'aus $key';
      arb['@$camel'] = meta;

      if (locale == 'de' && placeholders.keys.any(_intPlaceholders.contains)) {
        pluralCandidates
            .add('$camel  ($key)\n    DE: $message\n    EN: ${en[key]}');
      }
    }
    return arb;
  }

  const encoder = JsonEncoder.withIndent('  ');
  Directory('lib/l10n/arb').createSync(recursive: true);

  for (final (locale, source) in [('de', de), ('en', en)]) {
    final file = File('lib/l10n/arb/app_$locale.arb');
    final generated = buildArb(source, locale);

    // ZUSAMMENFÜHREN, nicht überschreiben. Nach der Erstmigration stehen in den
    // ARB-Dateien auch handgeschriebene Schlüssel für Oberflächen, die es in
    // der PWA nie gab. Ein erneuter Lauf für weitere Namespaces darf die nicht
    // vernichten.
    final merged = <String, Object?>{};
    if (file.existsSync()) {
      final existing =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      merged.addAll(existing);
    }
    merged.addAll(generated);

    // Sortiert schreiben, damit git diff lesbar bleibt: @@locale zuerst, dann
    // jeder Schlüssel direkt gefolgt von seinen Metadaten.
    final ordered = <String, Object?>{'@@locale': locale};
    final keys = merged.keys.where((k) => !k.startsWith('@')).toList()..sort();
    for (final k in keys) {
      ordered[k] = merged[k];
      if (merged.containsKey('@$k')) ordered['@$k'] = merged['@$k'];
    }

    file.writeAsStringSync('${encoder.convert(ordered)}\n');
  }

  // Das Skript rät NICHT, welcher Schlüssel einen Plural braucht. Es legt eine
  // Arbeitsliste an — ein Durchgang von Hand, eine Sitzung.
  Directory('l10n').createSync(recursive: true);
  File('l10n/plural_candidates.md').writeAsStringSync(
    '# Kandidaten für ICU-Plurale\n\n'
    'Automatisch erkannt an numerischen Platzhaltern. Das Skript wandelt sie\n'
    'NICHT selbst um — welcher Fall wirklich einen Plural braucht, entscheidet\n'
    'die Sprache, nicht der Datentyp.\n\n'
    'Zielform:\n```\n'
    '"{count, plural, =0{Keine Übungen} one{{count} Übung} other{{count} Übungen}}"\n'
    '```\n\n'
    '${pluralCandidates.length} Kandidaten:\n\n'
    '${pluralCandidates.map((c) => '- $c').join('\n\n')}\n',
  );

  stdout.writeln('${selected.length} Schlüssel aus ${namespaces.join(', ')}');
  stdout.writeln('-> lib/l10n/arb/app_de.arb, app_en.arb');
  stdout.writeln('${pluralCandidates.length} Pluralkandidaten '
      '-> l10n/plural_candidates.md');
}
