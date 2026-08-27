import 'session_draft.dart';
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

  /// Schreibt eine abgeschlossene Einheit und liefert ihre Dokument-ID.
  ///
  /// Trägt der Entwurf eine [SessionDraft.scheduleId], wird der zugehörige
  /// Termin im selben Zug als erledigt markiert. **Nicht in einer Transaktion:**
  /// Die PWA macht es ebenso in zwei Schritten, und ein fehlgeschlagener
  /// zweiter Schritt darf die gespeicherte Einheit nicht mitreißen. Ein Termin,
  /// der offen aussieht, obwohl er absolviert ist, ist der weit harmlosere
  /// Fehler als eine verlorene Trainingseinheit.
  Future<String> saveSession(SessionDraft draft);
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
