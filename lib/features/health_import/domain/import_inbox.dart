import '../../../core/domain/health_gateway.dart';

/// Was aus Health Connect im **Eingang** wartet — und ab wann gelesen wird.
///
/// ## Warten ist ein Zustand, kein Hinweis
///
/// Eine ungeprüfte Einheit ist bereits lokal angelegt und steht an ihrem
/// echten Datum in der Einheitenliste: sichtbar, aber **ohne Wirkung auf eine
/// einzige Zahl**. Diese Klasse entscheidet nur, was überhaupt hereinkommt —
/// nicht, wie es aussieht und nicht, was daraus wird.
///
/// ## Drei Filter, jeder mit einem Gedächtnis dahinter
///
/// 1. **Schon übernommen.** Die Health-Connect-Kennung steht an der
///    übernommenen Einheit. Ohne diesen Abgleich stünde dieselbe Einheit beim
///    nächsten Lesen ein zweites Mal im Eingang.
/// 2. **Abgelehnt.** „Nein" heisst abgelehnt **und gemerkt** (Board 15,
///    Entscheidung 11): ATEM speichert die Kennung mit dem Ablehndatum.
///    Löschen wäre ohnehin unmöglich — der Datensatz gehört Health Connect.
/// 3. **Selbst geschrieben.** Dieses Modul liest nur; sollte ATEM je eigene
///    Einheiten zurückschreiben, dürfen sie nicht als fremde Messung wieder
///    hereinkommen. Derselbe Schutz gegen die Schleife wie in `WeightSync`.
abstract final class ImportInbox {
  /// Wie weit beim ersten Lesen zurückgegriffen wird.
  ///
  /// Dreissig Tage, und das ist keine Vorsicht, sondern Googles Grenze: Ohne
  /// die zusätzliche Berechtigung `READ_HEALTH_DATA_HISTORY` liefert Health
  /// Connect nichts, was länger als dreissig Tage vor der Freigabe liegt.
  ///
  /// Zugleich die Antwort auf die offene Frage aus dem Board: Ein voller
  /// Bestandsimport könnte zweihundert wartende Einheiten erzeugen — einen
  /// Eingang, den niemand durcharbeitet.
  static const windowDays = 30;

  /// Ab wann gelesen wird.
  ///
  /// Beim ersten Mal dreissig Tage zurück, danach ab der letzten Lesemarke —
  /// nie der ganze Bestand. Eine Marke, die älter ist als das Fenster, wird
  /// auf das Fenster angehoben: Was davor liegt, gibt die Quelle ohnehin
  /// nicht heraus.
  static DateTime readFrom(DateTime reference, {DateTime? lastRead}) {
    final floor = reference.subtract(const Duration(days: windowDays));
    if (lastRead == null || lastRead.isBefore(floor)) return floor;
    return lastRead;
  }

  /// Die Einheiten, die zur Prüfung anstehen — **jüngste zuerst**.
  ///
  /// Der Stapel im Prüfblatt arbeitet sie in dieser Reihenfolge ab: Wer
  /// gestern trainiert hat, erinnert sich daran besser als an vorletzte
  /// Woche, und die Anstrengung ist genau die Angabe, die nur aus der
  /// Erinnerung kommt.
  static List<MeasuredSession> pending({
    required List<MeasuredSession> measured,
    required Set<String> importedIds,
    required Set<String> rejectedIds,
    required String ownSourceId,
  }) {
    final result = [
      for (final session in measured)
        if (session.sourceId != ownSourceId &&
            !importedIds.contains(session.id) &&
            !rejectedIds.contains(session.id))
          session,
    ];
    result.sort((a, b) => b.start.compareTo(a.start));
    return result;
  }
}
