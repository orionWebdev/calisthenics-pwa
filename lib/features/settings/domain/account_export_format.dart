import 'dart:convert';

import 'settings_repository.dart';

/// Der Bestand als Datei — **JSON vollständig, CSV auswertbar**.
///
/// ## Warum zwei Formate und nicht eins
///
/// Sie beantworten verschiedene Fragen. JSON ist die **vollständige** Ausgabe:
/// jedes Feld jeder Sammlung, auch die, die diese App gar nicht kennt. Es ist
/// die ehrliche Antwort auf „gib mir meine Daten".
///
/// CSV ist die **benutzbare**: eine Tabelle, die sich öffnen und sortieren
/// lässt. Sie kann nicht alles abbilden — verschachtelte Planeinträge werden
/// in einer Tabelle zur Lüge —, und deshalb versucht sie es gar nicht erst.
///
/// ## Der Umfang der Tabelle
///
/// **Eine Zeile je Satz**, nicht je Einheit. Wer die Daten in eine
/// Tabellenkalkulation zieht, will Sätze vergleichen; eine Zeile je Einheit
/// mit einer Textspalte voller Sätze wäre wieder nur JSON in schlecht.
///
/// Einheiten **ohne** Sätze — im Bestand 16 von 63 Krafteinheiten, dazu jede
/// Cardio- und Regenerationseinheit — bekommen trotzdem ihre Zeile, mit leeren
/// Satzspalten. Sonst verschwänden sie aus der Ausgabe, und eine Datenausgabe,
/// die Daten weglässt, ist keine.
abstract final class AccountExportFormat {
  /// Vollständig, unverändert, eingerückt.
  static String toJson(AccountExport export) =>
      const JsonEncoder.withIndent('  ').convert(export.collections);

  static const csvColumns = [
    'sessionId',
    'date',
    'type',
    'durationMin',
    'rpe',
    'planName',
    'notes',
    'exerciseId',
    'setIndex',
    'reps',
    'weightKg',
    'holdSec',
    'setType',
  ];

  /// Die Einheiten als Tabelle, eine Zeile je Satz.
  static String sessionsToCsv(AccountExport export) {
    final rows = <List<Object?>>[csvColumns];

    for (final session in export.collections['sessions'] ?? const []) {
      final base = <Object?>[
        session['id'],
        session['date'],
        session['type'],
        session['duration'],
        session['rpe'],
        session['planName'],
        session['notes'],
      ];

      final exercises = session['exercises'];
      if (exercises is! List || exercises.isEmpty) {
        rows.add([...base, null, null, null, null, null, null]);
        continue;
      }

      for (final exercise in exercises) {
        if (exercise is! Map) continue;
        final sets = exercise['sets'];
        if (sets is! List || sets.isEmpty) {
          rows.add(
              [...base, exercise['exerciseId'], null, null, null, null, null]);
          continue;
        }
        for (var i = 0; i < sets.length; i++) {
          final set = sets[i];
          final fields = set is Map ? set : const {};
          rows.add([
            ...base,
            exercise['exerciseId'],
            i + 1,
            fields['reps'],
            fields['weight'],
            fields['holdSec'],
            fields['type'],
          ]);
        }
      }
    }

    return rows.map(_line).join('\r\n');
  }

  /// **CRLF und Anführungszeichen nach RFC 4180.** Eine Notiz mit Komma oder
  /// Zeilenumbruch darin zerlegte sonst die Tabelle — und Notizen sind das
  /// Feld, in dem beides vorkommt.
  static String _line(List<Object?> cells) => cells.map(_cell).join(',');

  static String _cell(Object? value) {
    if (value == null) return '';
    final text = value.toString();
    if (!text.contains(RegExp('[",\r\n]'))) return text;
    return '"${text.replaceAll('"', '""')}"';
  }
}
