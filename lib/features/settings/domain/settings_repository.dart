import 'user_settings.dart';

/// Liest und schreibt die Einstellungen eines Kontos.
///
/// Sie liegen im selben Dokument wie das Profil (`userProfiles/{uid}`) — die
/// Vorgänger-App hält es genauso, und ein zweites Dokument daneben wäre eine
/// zweite Wahrheit über dieselbe Person.
abstract interface class SettingsRepository {
  Stream<UserSettings> watch(String userId);

  Future<UserSettings> fetch(String userId);

  /// Schreibt **nur die Felder, die diese App kennt**, per `merge`.
  ///
  /// Das Profil trägt zwanzig weitere aus der PWA. Ein vollständiges
  /// Überschreiben löschte sie, und die PWA bliebe mit Standardwerten zurück.
  Future<void> save(String userId, UserSettings settings);
}

/// Löscht ein Konto samt aller Daten.
///
/// ## Warum das ein eigener Vertrag ist
///
/// Es greift über **sechs** Sammlungen und danach über die Anmeldung selbst.
/// Kein bestehendes Repository ist dafür zuständig, und es in eines davon zu
/// legen hiesse, ihm eine Verantwortung zu geben, die weit über seinen
/// Gegenstand hinausreicht.
///
/// ## Was **nicht** gelöscht wird
///
/// Der Eintrag in `allowedUsers`. Die Regeln lassen niemanden ihn anfassen —
/// er gehört der geschlossenen Beta, nicht dem Konto. Wer sich nach dem
/// Löschen erneut anmeldet, ist also wieder drin: mit leerem Bestand, im
/// Onboarding. Das ist technisch richtig und muss erklärt werden, statt zu
/// überraschen.
abstract interface class AccountRepository {
  /// Löscht alle Dokumente des Kontos in Firestore.
  ///
  /// **Vor** der Abmeldung auszuführen: Ohne Anmeldung verweigern die Regeln
  /// jeden Zugriff, und die Daten blieben unerreichbar liegen.
  ///
  /// [onProgress] meldet nach jeder Sammlung, wie viele fertig sind. Das
  /// Löschen dauert bei 245 Tagen Bestand mehrere Sekunden; ein Ring ohne
  /// Angabe liesse offen, ob überhaupt etwas passiert — und die Aktion ist
  /// nicht abbrechbar, also muss sie erklären, wo sie steht.
  Future<void> deleteData(
    String userId, {
    void Function(int done, int total, String collection)? onProgress,
  });

  /// Löscht das Anmeldekonto selbst.
  Future<void> deleteAccount();

  /// Sammelt den gesamten Bestand des Kontos für die Ausgabe.
  Future<AccountExport> export(String userId);
}

/// Der ausgegebene Bestand, roh.
///
/// Bewusst `Map` und nicht getippte Modelle: Ausgegeben wird, **was in der
/// Datenbank steht**, nicht was diese App davon versteht. Ein Feld, das die
/// App nicht kennt, fehlte sonst in der Ausgabe — und genau das wäre bei einer
/// Datenausgabe der schwerste Fehler.
class AccountExport {
  const AccountExport({required this.collections});

  /// Sammlungsname → Dokumente, jedes mit seiner Kennung unter `id`.
  final Map<String, List<Map<String, Object?>>> collections;

  int get documentCount =>
      collections.values.fold(0, (total, docs) => total + docs.length);
}
