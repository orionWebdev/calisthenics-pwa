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

  /// Ab wann gelesen wird — **immer dreissig Tage zurück**.
  ///
  /// ## Warum die Lesemarke das Fenster nicht mehr verengt
  ///
  /// Bis zum 21.09.2026 begann das Fenster an der letzten Lesemarke. Das
  /// sparte nichts und kostete alles: Die Marke rückt vor, sobald ein Lauf
  /// durchläuft — auch wenn er nichts gefunden hat, weil eine Berechtigung
  /// fehlte und die Quelle still null Einheiten lieferte. Danach begann
  /// jeder weitere Lauf hinter den Einheiten, die er nie gesehen hatte. Auf
  /// dem Honor war das Fenster zuletzt **zwei Minuten** breit, und die
  /// Einheiten vom 16. und 18.09. lagen für immer davor.
  ///
  /// Ein Fenster, das sich an einem gespeicherten Zeitpunkt festmacht, macht
  /// jeden vorübergehenden Fehler dauerhaft. Dreissig Tage jedes Mal zu
  /// lesen ist nicht teuer — und doppelt kommt nichts herein: Dafür sorgen
  /// die Kennungen in [pending], nicht das Fenster.
  ///
  /// Die Marke bleibt, aber nur als Auskunft („zuletzt gelesen").
  static DateTime readFrom(DateTime reference) =>
      reference.subtract(const Duration(days: windowDays));

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
