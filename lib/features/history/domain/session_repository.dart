import 'session_draft.dart';
import 'session_patch.dart';
import 'training_session.dart';

/// Zugriff auf absolvierte Trainingseinheiten.
///
/// Reiner Vertrag, keine Implementierung — Vertrag 3, Schichtregeln. Die
/// Firestore-Fassung liegt in `data/firestore_session_repository.dart`.
abstract interface class SessionRepository {
  /// Alle Einheiten eines Nutzers, neueste zuerst.
  ///
  /// ## Warum alles und nicht ein Zeitfenster
  ///
  /// Das Scoring der PWA rechnet über 56 Tage, der Form-Trend über eine
  /// langsamere Kurve, und die Fortschrittsansichten wollen die ganze
  /// Geschichte. Ein Zeitfenster in der Abfrage müsste die weiteste dieser
  /// Anforderungen bedienen und wäre damit ohnehin fast alles.
  ///
  /// Dazu kommt: Ein Datumsbereich zusätzlich zum `userId`-Filter verlangt
  /// einen zusammengesetzten Index. Ein reiner Gleichheitsfilter kommt ohne
  /// aus. Die PWA macht es seit jeher so und sortiert in JavaScript.
  ///
  /// **Revisionsauslöser:** Der Bestand liegt bei 136 Dokumenten und wächst um
  /// etwa 250 im Jahr. Ab rund 2.000 Dokumenten neu bewerten — dann lohnt der
  /// Index, und das Fenster gehört in die Abfrage.
  Stream<List<TrainingSession>> watchSessions(String userId);

  /// Momentaufnahme statt Strom — für Berechnungen, die keinen Abgleich
  /// brauchen.
  Future<List<TrainingSession>> fetchSessions(String userId);

  /// Ob der Stand gerade aus dem lokalen Zwischenspeicher kommt.
  ///
  /// Die Oberfläche zeigt daraufhin „Offline — Änderungen werden lokal
  /// gespeichert". Bewusst kein eigener Netzwerkzustand: Was zählt, ist nicht
  /// ob ein Netz da ist, sondern ob Geschriebenes ankommt.
  ///
  /// **Ein Strom, kein Feld.** Als Feld stand der Wert auf dem Stand der
  /// letzten Datenänderung fest — und weil Firestore eine reine
  /// Metadaten-Änderung nicht als Ereignis meldet, blieb „offline" für immer
  /// stehen, sobald der erste Stand aus dem Zwischenspeicher kam. Der Strom
  /// hört ausdrücklich auf Metadaten-Änderungen.
  Stream<bool> watchFromCache(String userId);

  /// Schreibt eine abgeschlossene Einheit und liefert ihre Dokument-ID.
  ///
  /// Trägt der Entwurf eine [SessionDraft.scheduleId], wird der zugehörige
  /// Termin im selben Zug als erledigt markiert. **Nicht in einer Transaktion:**
  /// Die PWA macht es ebenso in zwei Schritten, und ein fehlgeschlagener
  /// zweiter Schritt darf die gespeicherte Einheit nicht mitreißen. Ein Termin,
  /// der offen aussieht, obwohl er absolviert ist, ist der weit harmlosere
  /// Fehler als eine verlorene Trainingseinheit.
  Future<String> saveSession(SessionDraft draft);

  /// Ändert eine gespeicherte Einheit.
  ///
  /// Was änderbar ist und wie `null` je Feld zu lesen ist, steht am
  /// [SessionPatch]. `userId` und `type` sind nicht dabei — beide würden die
  /// Einheit zu etwas anderem machen, nicht zu einer korrigierten Fassung.
  Future<void> updateSession(String id, SessionPatch patch);

  /// Trägt Sätze zu einer bestehenden Einheit nach.
  ///
  /// **Bewusst eng.** Der naheliegende Weg wäre [updateSession] gewesen — der
  /// verlangt aber ein Datum, und der Runner kennt nur das von heute. Eine
  /// nachgetragene Einheit wäre damit auf den Tag des Nachtragens gerutscht,
  /// und mit ihr jede Lücke und jede Kurve.
  ///
  /// Diese Methode rührt ausschliesslich `exercises` an. Datum, Dauer und
  /// Notiz bleiben, wie sie waren.
  Future<void> updateSessionExercises(String id, List<LoggedExercise> exercises);

  /// Verknüpft eine Einheit mit einer Uhr-Einheit — oder löst die
  /// Verknüpfung wieder ([healthSessionId] `null`).
  ///
  /// **Bewusst eng**, aus demselben Grund wie [updateSessionExercises]:
  /// [updateSession] verlangt ein Datum, und eine Zusammenführung darf das
  /// Datum der Einheit nicht anfassen.
  ///
  /// Geschrieben wird **nur der Verweis**. Puls und Kalorien bleiben am
  /// Uhr-Datensatz liegen, wo sie herkommen (Board 15, Entscheidung 1) —
  /// deshalb ist Lösen verlustfrei und braucht keine Gegenbuchung.
  Future<void> linkHealthSession(String id, String? healthSessionId);

  /// Löscht eine Einheit.
  ///
  /// Stammte sie aus einem Kalendertermin, wird der Termin wieder geöffnet:
  /// Ein Termin, der als absolviert gilt, obwohl die Einheit gelöscht wurde,
  /// wäre ein Verweis ins Leere.
  ///
  /// **Das Zeitfenster liegt nicht hier.** Diese Methode löscht sofort und
  /// endgültig; die dreißig Sekunden Widerruf sind eine Sache der Anwendung
  /// (`application/pending_deletion.dart`). Ein Repository, das wartet, wäre
  /// eines, dessen Rückgabe nichts über den Zustand der Datenbank aussagt.
  Future<void> deleteSession(String id);
}

/// Was beim Lesen übersprungen wurde.
///
/// Der Mapper lässt Dokumente aus, denen die Pflichtfelder fehlen. Stillschweigend
/// wäre das gefährlich: Eine Einheit, die niemand vermisst, fehlt auch in jeder
/// Auswertung. Die Zahl gehört deshalb an die Oberfläche des Repositories.
class SessionReadReport {
  const SessionReadReport({required this.read, required this.skipped});

  final int read;
  final int skipped;

  bool get hasSkipped => skipped > 0;

  @override
  String toString() => 'gelesen: $read, übersprungen: $skipped';
}
