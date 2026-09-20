# Gemini-Produktstrategie vom 18.09.2026 — Bewertung und Übernahmeplan

**Quelle:** `ATEM Hybrid – Produktstrategie & UX/UI Spezifikation.pdf`, von Christian mit Gemini erstellt.
**Zweck dieses Dokuments:** Festhalten, was daraus übernommen wird, wie, und was schon steht. Jede
Zeile ist gegen den tatsächlichen Code geprüft — Gemini kannte den Bestand nicht im Detail, deshalb
stimmen einige Tech-Annahmen nicht mit diesem Projekt überein (siehe Abschnitt 5).

---

## 1 · Bereits umgesetzt — nichts zu tun

| Vorschlag aus dem PDF | Fundstelle im Code |
|---|---|
| Nenner-Pflicht bei jeder Zahl | `CLAUDE.md` „Umgang mit Zahlen", seit Projektbeginn Regel |
| Keine Ampelfarben, neutrale Deltas mit Glyphe | `CLAUDE.md`, dieselbe Regel — das PDF nennt das „Design-Regel 2" |
| Schwellenwert-Zustand statt leerer Diagramme | `AtemThresholdBlock` (`lib/core/widgets/atem_threshold_block.dart`), seit 16.09. Pflicht auf Auswertungsbildschirmen |
| PR-Chip entfällt ohne Bestwert | `ExerciseHistory.measuresWeight` (`lib/features/history/domain/exercise_history.dart:174`) — kein „PR —" |
| Haltezeit (Isometrie) auf Satz-Ebene | `LoggedSet.holdSeconds` (`training_session.dart:523`), im Runner erfassbar |
| Geschätztes 1RM nach Epley | `StrengthProgress.epley` (`strength_progress.dart:95`), **bereits mit Sperre über 10 Wdh.** — wir sperren ab 12, das PDF schlägt „>10" vor, praktisch dieselbe Grenze |
| Rest-Timer im Workout-Flow | `rest_bar.dart`, automatischer Start nach dem Abhaken eines Satzes, seit dem Umbau am 18.09. mit Regler statt reinem Tippen |
| Offline-First | Firestore mit `Settings.CACHE_SIZE_UNLIMITED` (`main.dart:30`) — **nicht** SQLite/Isar, siehe Abschnitt 5 |

---

## 2 · Übernehmen — mit Begründung und Umsetzung

### 2.1 Weighted Calisthenics: Zusatzgewicht zur Last addieren — ✅ erledigt (18.09.2026)

**Das ist der einzige echte Fehler, den das PDF gefunden hat**, aber die Umsetzung war nicht so klein
wie zuerst gedacht: `training_load.dart` ist Zeile für Zeile aus `js/views/sessions/scoring.js`
portiert, und ein Testorakel (`tool/scoring_oracle.mjs`) führt das **echte** Original als JavaScript
aus, um zu beweisen, dass die Portierung keine historischen Zahlen verändert. Das
`usesBodyweight ? bodyWeight : (set.weight ?? 0)`-Verhalten war also kein Portierungsfehler, sondern
das **tatsächliche Verhalten der PWA über den ganzen Bestand** — eine einfache Änderung hätte den
Beweis der Gleichheit gebrochen, nicht nur den Fehler behoben.

**Umsetzung:**
- `training_load.dart`: `weight = usesBodyweight ? context.bodyWeightKg + (set.weight ?? 0) : (set.weight ?? 0)`.
- `tool/scoring_oracle.mjs` führt jetzt **drei** Fassungen der PWA aus: die rohe (`api`, bleibt
  unangetastet — Beweis der Historie), eine mit Kalender- **und** Gewichts-Patch (`corrected`, der
  Massstab für Dart) und eine nur mit dem Gewichts-Patch (`weightOnly`, der Massstab für den
  bestehenden Kalender-Selbsttest, der sonst am neuen Gewichts-Unterschied gescheitert wäre).
- `test/history/scoring_oracle_test.dart`: die Rohlast-Gleichheit prüft jetzt gegen `correctedLoads`
  statt gegen die rohe PWA; ein neuer, von den Zufallsdaten unabhängiger Test
  (`training_load_weighted_calisthenics_test.dart`) sagt in Worten, was der Fix tut: ein Klimmzug mit
  80 kg Körpergewicht und 20 kg Zusatzlast liefert dieselbe Last wie ein Hantelsatz mit 100 kg.
- **Wirkung auf den echten Bestand, geprüft gegen die Sicherung vom 16.09.2026:** 3 von 292
  aufgezeichneten Übungseinträgen tragen sowohl die Körpergewichts-Kennzeichnung als auch ein
  Satzgewicht — ihre historische Last ändert sich rückwirkend. Alle drei gehören zum zweiten Konto
  (`e5pxNXB7…`), keiner zum aktuell aktiven. Das ist eine bewusste, dokumentierte Entscheidung.
- 800 Tests grün, Analyse ohne Befund.

### 2.2 Hard Sets (RPE ≥ 7) als Muskelgruppen-Metrik — ✅ erledigt (18.09.2026)

Sinnvolle Ergänzung zur Muskelbalance, **aber sie setzt eine Datenmodell-Änderung voraus**, die das
PDF nicht benennt: `rpe` ist heute ein Feld der **Einheit**, nicht des **Satzes**
(`training_session.dart:223`, `TrainingSession.rpe`). Eine Einheit hat eine RPE-Zahl für alle Sätze
zusammen. „14 Hard Sets für Brust diese Woche" verlangt aber eine RPE- oder RIR-Angabe **je Satz**,
sonst zählt entweder die ganze Einheit oder keiner ihrer Sätze.

**Umsetzung, in dieser Reihenfolge:**
1. `LoggedSet` um ein optionales Feld erweitern, z. B. `final int? rpe` (1–10) — additiv, keine
   bestehenden Leser brechen daran.
2. Runner-UI: RPE-Eingabe je Satz, freiwillig, ohne Vorbelegung (wie alle Selbstauskünfte in
   `wellness_fields.dart`).
3. Domäne `HardSets` (analog zu `FocusDistribution`): zählt Sätze mit `rpe >= 7` je Muskelgruppe über
   ein Fenster, mit Vergleich zur Vorperiode — **als Verschiebung in Sätzen, kein Sollwert** (CLAUDE.md).
4. Auswertungsblock nach dem `AtemThresholdBlock`-Muster, erscheint erst mit genug Sätzen mit RPE.
5. **Nicht** „Hard Sets ersetzt Tonnage" wie im PDF — Tonnage bleibt für Kraftsportler die richtige
   Grundlage, Hard Sets ist die zusätzliche Sicht für alle. Ersetzen wäre ein Rückschritt für reine
   Kraftsportler mit vollständigen Gewichtsangaben.
- **Aufwand:** mittel — ein neues Feld im Bestand (additiv), eine Domänenrechnung, ein Auswertungsblock,
  eine Runner-Eingabe. Guter Kandidat für einen eigenen Durchgang mit mehreren Agenten.

### 2.3 RIR statt/neben RPE, umschaltbar — ✅ erledigt (20.09.2026)

**Umgesetzt:** `EffortScale` in `user_settings.dart` (`rpe` | `rir`, Feld `effortScale` im
Profil), Segment-Schalter „Anstrengung je Satz" in den Einstellungen, `effortScaleProvider`.
Streifen und Kapsel im Runner zeigen in RIR 4–3–2–1–0 statt 6–7–8–9–10; die Karte „Harte Sätze"
nennt die Schwelle als „3 RIR oder weniger" statt „Anstrengung 7 oder mehr".

**Die Wahrheit bleibt RPE.** Gespeichert wird ausnahmslos `LoggedSet.rpe` 1–10 — RIR ist dieselbe
Zahl von der anderen Seite gezählt (`10 − RPE`, verlustfrei). Ein Wechsel wirkt sofort auch auf alle
früheren Sätze und geht jederzeit zurück; niemand muss sich entscheiden, bevor er beide gesehen hat.
Die Alternative — RIR speichern — hätte die Bedeutung jeder Zahl im Bestand an eine
Kontoeinstellung gehängt. Ursprüngliche Einschätzung:

Nachvollziehbar für Hypertrophie-Training, aber **kein Free-Lunch**: Der Bestand trägt heute RPE
(1–10 auf Einheitsebene). Ein Umschalter „intern als RIR speichern, UI umschaltbar" verlangt eine
Umrechnung (`RIR ≈ 10 − RPE`, grob) und eine Entscheidung, welche Skala die Wahrheit ist.

**Empfehlung:** zurückstellen, bis 2.2 (RPE je Satz) steht. Danach ist ein Umschalter in den
Einstellungen ein kleiner Aufsatz auf demselben Feld, keine zweite Datenquelle. Kein eigenes Ticket
jetzt.

### 2.4 Plate Calculator — ✅ erledigt (18.09.2026)

**Umgesetzt:** `lib/core/domain/plate_calculator.dart` (`PlateCalculator.solve`, rechnet in Gramm,
Stangen 20/15/10 kg), `AtemPlateStack` und ein aufklappbares „Scheiben"-Feld im `AtemStepPad` — nur
bei Übungen ohne Körpergewicht. Nicht steckbarer Rest wird mit dem nächsten ladbaren Wert benannt,
nicht stillschweigend gerundet. Scheiben unterscheiden sich über Grösse und Beschriftung, keine
Kennfarben. Ursprünglicher Plan:

Eigenständiges, kleines Feature ohne Datenmodell-Abhängigkeit. Rechnet aus einem Zielgewicht und der
Stangenmasse (Standard 20 kg) die Bestückung.

**Umsetzung:**
- Reine Domänenfunktion: `PlateCalculator.solve(targetKg, barKg, plates: [25, 20, 15, 10, 5, 2.5, 1.25])`
  → Liste `(plateKg, count)` je Seite, greedy von der schwersten Scheibe.
- Darstellung als Scheibenstapel (Farbe nach Standard-Kennfarben — **das wäre eine neue Farbebene**,
  gegen `CLAUDE.md` „keine vierte Farbebene". Lösung: Grössen statt Farben unterscheiden die Scheiben,
  Zahl auf jeder Scheibe als Beschriftung; kein Verstoss gegen die Nur-Tokens-Regel.
- Zugriff aus dem Eingabeblatt (`AtemStepPad`) heraus, als zusätzlicher Reiter oder Link neben dem
  Gewicht-Regler — nicht als eigener Screen, sonst App-Wechsel-artige Unterbrechung im Training.
- **Aufwand:** klein bis mittel, gut als Einzel-Agent nach 2.1 machbar.

### 2.5 Skill-Progression-Tree (Hebel-Ketten für Calisthenics)

Der bestandsseitig grösste Vorschlag. Heute hat `Exercise` nur `difficulty` (1–5, siehe
`exercise.dart:76`) als grobes Fortschrittssignal, **keine Verknüpfung** zwischen verwandten Übungen
(Tuck Planche → Advanced Tuck → Straddle → Full).

**Umsetzung, grob skizziert (kein sofortiger Bau):**
1. Datenmodell: `Exercise.progressionChain` (Liste von Übungs-IDs in Reihenfolge) oder ein separates
   `SkillTrack`-Dokument, das mehrere `Exercise`-IDs ordnet. Nur für kuratierte Übungen sinnvoll
   befüllbar — eigene Übungen hätten keine Kette, es sei denn der Nutzer verknüpft sie selbst.
2. Übergangsschwelle: „Ziel-Wdh/Haltezeit" je Stufe — das ist wieder ein Sollwert-Feld, das mit
   „kein Sollwert, kein Urteil" abgewogen werden muss. Vorschlag: die Schwelle ist eine **Selbstauskunft
   des Nutzers**, keine App-Vorgabe, damit sie nicht wie eine Trainingsempfehlung wirkt (CLAUDE.md,
   „keine Trainingsempfehlung, die wie eine Verordnung klingt").
3. UI: eine Kette als vertikale Stufenanzeige im Übungsverlauf, aktuelle Stufe hervorgehoben.
- **Aufwand:** grösser — verlangt Pflege der Ketten für die 84 kuratierten Übungen, ein eigenes
  Redaktionsprojekt, nicht nur Code. **Empfehlung: zurückstellen bis nach dem Onboarding-Vorhaben**
  (siehe Abschnitt 4), weil die Dateneingabe (welche Übung folgt auf welche) der eigentliche Aufwand ist.

### 2.6 Tempo / Time Under Tension (3-0-1-0)

Zusätzliches optionales Feld je Satz, additiv wie 2.2. **Aufwand:** klein, aber **niedriger Nutzen für
diesen einzelnen Nutzer** (Calisthenics-fokussiert, kein Bodybuilding-Tempo-Training erwähnt).
Empfehlung: nicht bauen, ausser der Bedarf wird konkret genannt.

---

## 3 · Verworfen — mit Begründung

| Vorschlag | Warum nicht |
|---|---|
| Tonnage = 0 bei BW „für Dashboard-Vergleiche ungeeignet" | Teilweise falsch: Nach 2.1 ist Tonnage bei Weighted Calisthenics **nicht** mehr 0. Bei reinem Körpergewicht ohne Zusatzlast bleibt Tonnage bewusst niedrig — das ist korrekt, nicht falsch, weil `TrainingLoad` dafür schon auf Dauer ausweicht (`training_load.dart:120`, „Ersatzrechnung nach Dauer"). Hard Sets (2.2) ergänzt, ersetzt aber nicht. |
| SQLite/Isar als lokale Datenbank | Das Projekt nutzt Firestore mit unbegrenztem lokalen Cache, bereits offline-first. Eine zweite lokale Datenbank wäre eine parallele Wahrheit — nicht bauen. |
| Android Live Activity / System-Overlay für den Rest-Timer | **Deckt sich mit einem bereits gemerkten Zukunftsziel** (Lockscreen-Widget mit Pausentimer, siehe [[atem-geplante-features]]) — dort schon vermerkt, hier keine doppelte Aufgabe. |

**Korrektur vom 18.09., später am selben Tag:** Google Play Billing und ASO/Store-Listing standen hier
zunächst als „gegenstandslos, keine Store-Veröffentlichung geplant". Das war falsch — der Nutzer hat
das ausdrücklich richtiggestellt: Store-Themen und Monetarisierung sind definitiv ein Thema, die App
soll **schnellstmöglich** in den Play Store. Siehe Abschnitt 7 für den Stand und die offenen
Entscheidungen dazu. Die Notiz „ATEM ist privat" bezieht sich ausschliesslich auf die Abwesenheit von
Keyperformance-Branding (Paketname, Impressum, Store-Texte) — nicht auf eine Store-Absicht; das gilt
für eine öffentliche Veröffentlichung unverändert weiter.

---

## 4 · Abgleich mit den festgehaltenen Zukunftszielen

Aus dem Projektgedächtnis (`atem-geplante-features.md`, drei vom Nutzer angemeldete Vorhaben):

1. **Lockscreen-Widget mit Pausentimer** — deckt sich mit dem PDF-Vorschlag „Integrated Rest Timer &
   Live Tracking" (Abschnitt 4.4 des PDFs). Bestätigt als sinnvoll, technische Einschätzung unverändert:
   Android App Widget/Glance plus Vordergrunddienst, kein reines Flutter-Feature.
2. **Seitengetrennte Sätze** (z. B. Bizeps-Curl nur rechts/links) — **im PDF nicht erwähnt**, bleibt
   ein eigenständiges Vorhaben. Bietet sich an, mit 2.2 (`LoggedSet`-Erweiterung um `rpe`) in **einem**
   Durchgang zu erledigen, weil beides additive Felder am selben Modell sind — eine Migration statt zwei.
3. **Muskel- und Ablaufvisualisierung** — verwandt mit dem Skill-Progression-Tree (2.5), aber breiter
   (alle Muskelgruppen, nicht nur Calisthenics-Hebelketten). Getrennt zu behandeln: die Körperkarte ist
   ein reines Anzeige-Feature ohne neue Daten, der Skill-Tree braucht neue Verknüpfungsdaten.
4. Onboarding und generiert auf den Nutzer abgestimmte Pläne.

**Empfehlung:** Wenn als Nächstes an Runner-Feldern gearbeitet wird, `rpe` (2.2) und die
Seiten-Kennzeichnung (Zukunftsziel 2) zusammen an `LoggedSet` anlegen — eine Erweiterung des Modells
statt zwei.

---

## 5 · Wo das PDF am tatsächlichen Stack vorbeigeht

Gemini kannte den Code nicht, nur die Beschreibung. Zwei Annahmen stimmen nicht:

- **Persistenz:** Das PDF nimmt „SQLite/Isar" an (Abschnitt 5, 8). Tatsächlich läuft die App auf
  Firestore mit lokalem Cache — bereits offline-first, ohne zweite Datenbank.
- **Store-Reife:** Die Roadmap in Abschnitt 8 nennt Play-Billing- und ASO-Aufgaben erst in Phase 3,
  nach vollem Feature-Umbau. Das passt nicht zu „schnellstmöglich in den Store" — der schnellste Weg
  ist ein freier Start ohne Bezahlfunktion (Abschnitt 7), Monetarisierung danach.

Das schmälert die UX/Metrik-Vorschläge in Abschnitt 2–4 nicht — die sind unabhängig vom Backend gültig
und wurden entsprechend übernommen oder begründet zurückgestellt.

---

## 6 · Empfohlene Reihenfolge für die Metriken

1. ✅ **2.1 Weighted-Calisthenics-Fix** — echter Fehler, klein, sofort machbar.
2. ✅ **2.2 + Zukunftsziel 2 zusammen** — `LoggedSet` um `rpe` und Seiten-Kennzeichnung in einem Zug
   erweitern, dann Hard-Sets-Auswertung und die Auswahl links/rechts im Runner.
3. ✅ **2.4 Plate Calculator** — kleiner, unabhängiger Gewinn für Kraftsportler.
4. **2.5 Skill-Tree** — zurückgestellt, eigenes Redaktionsprojekt für die Übungsketten nötig.
5. ✅ **2.3 RIR-Umschalter** — erst nach 2, kein eigener Aufwand mehr.
6. **2.6 Tempo/TUT** — nicht bauen ohne konkreten Bedarf.

Diese Reihenfolge ist unabhängig vom Store-Termin — keiner dieser Punkte blockiert Abschnitt 7 und
keiner wird durch ihn blockiert.

---

## 7 · Play-Store-Freigabe — Stand und Blocker (18.09.2026)

**Korrektur, noch am selben Tag:** Store und Monetarisierung sind ein reales Ziel, aber der Deploy
selbst kommt **ganz zum Schluss** — erst nachdem die Metrik- und Feature-Arbeit aus Abschnitt 2 steht.
Dieser Abschnitt bleibt als Bestandsaufnahme stehen, und der Signierschlüssel (7.5) ist bereits
erledigt und bleibt so. An den übrigen offenen Punkten (Rechtstext-Platzhalter, Paywall-Schnitt,
Registrierung öffnen) wird aber **nicht weitergearbeitet**, solange Abschnitt 2 offen ist. Die Arbeit
geht dort weiter.

### 7.1 Was schon passt

| Punkt | Stand |
|---|---|
| Paketname | `com.atemhybrid.app` — kein Keyperformance-Bezug, unveränderlich nach Veröffentlichung, bereits sauber gesetzt |
| App-Icon | Eigenes Icon in allen fünf Dichtestufen vorhanden (`android/app/src/main/res/mipmap-*/ic_launcher.png`), kein Flutter-Standardicon |
| Anmeldung | Google Sign-In über Firebase Auth eingerichtet — Play Store verlangt kein zusätzliches Verfahren |
| Rechtsgrundlage inhaltlich | Datenexport und Kontolöschung sind bereits gebaut und erreichbar (Modul 7/8) — die Data-Safety-Angaben „Nutzer kann Daten löschen/exportieren" sind ehrlich mit „Ja" zu beantworten |
| Datensparsamkeit | Kein GPS, kein Standortzugriff im Manifest, keine dritten Analyse-/Werbe-SDKs im `pubspec.yaml` — vereinfacht die Inhalts- und Datensicherheits-Fragebögen deutlich |
| Firestore-Regeln | Jedes Dokument ist strikt auf `request.auth.uid == userId` begrenzt (`firestore.rules`) — mehrnutzerfähig, kein Datenleck zwischen Konten zu erwarten |

### 7.2 Echte Blocker — ohne diese kein Upload möglich

1. ~~**Signierung.**~~ **Erledigt am 18.09.2026.** `android/app/build.gradle.kts` liest jetzt
   `android/key.properties` (nicht im Repo, siehe `.gitignore`) und signiert Release-Builds mit einem
   eigenen Upload-Zertifikat (`android/app/atem-upload-key.jks`, Alias `atem-upload`, gültig 30 Jahre).
   Geprüft mit `apksigner verify`: Zertifikat trägt „CN=ATEM Hybrid" statt des Android-Debug-Zertifikats.
   Fehlt `key.properties` (jeder andere Rechner), fällt der Build automatisch auf den Debug-Schlüssel
   zurück, statt zu brechen. **Christian muss `android/key.properties` und die `.jks`-Datei sichern**
   (Passwort-Manager oder verschlüsseltes Backup) — beide liegen nur lokal, ein Verlust ist über Google
   Play App Signing zwar ersetzbar, aber ein unnötiger Umweg.
   ⚠️ **Achtung beim nächsten Testgerät-Update:** Ein Release-Build mit dem neuen Zertifikat hat eine
   andere Signatur als der bisher auf dem Honor installierte. Android verweigert die Installation über
   die alte Version („Signaturen stimmen nicht überein") — vor dem nächsten Aufspielen einmal
   `adb uninstall com.atemhybrid.app` nötig, danach normal weiter.
2. **Datenschutzerklärung nicht live.** `lib/features/settings/domain/legal_links.dart` verweist auf
   `https://calisthenics-pro-57d6d.web.app/legal/…`; die Seite liefert aktuell **404** (nicht deployt).
   Play Console verlangt eine erreichbare, öffentliche Datenschutz-URL **vor** der Einreichung — ohne
   sie lässt sich der Store-Eintrag nicht abschicken.
3. **Fünf Platzhalter in den Rechtstexten.** `web/legal/datenschutz.html` und `index.html` (Impressum)
   tragen wörtlich `[VOLLSTÄNDIGER NAME]`, `[STRASSE UND HAUSNUMMER]`, `[PLZ UND ORT]`, `[LAND]`,
   `[KONTAKT-E-MAIL]`. **Das kann nur der Nutzer füllen** — echte Identität, keine erfundenen Daten.
4. **Der Zugangs-Schalter.** `firestore.rules:22` lässt nur angemeldete Nutzer durch, die in der
   Collection `allowedUsers` mit `enabled == true` eingetragen sind (`WaitingRoomScreen` für alle
   anderen). Für eine öffentliche Store-Veröffentlichung ist das eine bewusste Entscheidung, keine
   automatische Anpassung — siehe Frage 1 unten.

### 7.3 Für die Einreichung zusätzlich nötig (kein Blocker, aber Pflichtfelder in der Play Console)

- Store-Texte: Kurzbeschreibung (≤ 80 Zeichen), vollständige Beschreibung, Titel.
- Grafiken: Icon 512×512, Feature-Grafik 1024×500, mindestens zwei Bildschirmfotos vom Telefon.
- Kategorie, Zielgruppe/Altersfreigabe-Fragebogen, Datensicherheits-Fragebogen (Formular, keine Datei).
- Kontakt-E-Mail für den Store-Eintrag (kann von der Impressum-Adresse abweichen).
- Preismodell in der Console setzen (auch „kostenlos" ist eine explizite Angabe).

### 7.4 Entscheidungen — vom Nutzer am 18.09.2026 getroffen

1. **Zugang beim Start: Registrierung öffnen.** `allowedUsers` wird kein Einladungs-Gate mehr — jeder
   angemeldete Nutzer soll sofort hineinkommen. **Umsetzung:** Beim ersten Anmelden automatisch ein
   `allowedUsers/{uid}`-Dokument mit `enabled: true` anlegen (Cloud Function `onCreate` beim
   Firebase-Nutzer, oder ein Schreibvorgang direkt nach dem ersten erfolgreichen Sign-In, bevor
   `AuthGate` den Zustand prüft). Das Feld `enabled` bleibt erhalten — es ist damit weiterhin möglich,
   ein einzelnes Konto zu sperren (Missbrauch, Support), ohne die Regeln erneut zu ändern. Die
   Firestore-Regel selbst (`request.auth.uid == userId` je Dokument) ändert sich nicht — sie war nie
   das Zugangs-Gate, nur der Eigentumsschutz. `WaitingRoomScreen` bleibt für den kurzen Moment
   zwischen Anmeldung und dem automatischen Freischalten, nicht mehr für eine manuelle Prüfung.
2. **Veröffentlichungs-Gleis: geschlossener/interner Test zuerst.** Keine Store-Texte, keine Grafiken,
   keine Alterseinstufung nötig, um den ersten Build in der Play Console laufen zu haben — nur
   Signierung (erledigt) und eine erreichbare Datenschutzseite (Blocker 2) sind Pflicht dafür.
3. **Zeitpunkt der Monetarisierung: Paywall vor dem ersten Upload.** Damit verzögert sich die
   Veröffentlichung bewusst um die volle Play-Billing-Integration — das ist die getroffene Entscheidung,
   nicht mehr die schnellste Variante, aber die gewollte. Siehe 7.6 für den Umfang und die offene
   Frage, welche Funktionen frei bleiben.

### 7.5 Erledigt

- ✅ Upload-Keystore erzeugt, Signierung umgestellt (7.2 Punkt 1) — bestätigt mit `apksigner verify`.

### 7.6 Als Nächstes — teils blockiert auf Angaben, die nur der Nutzer hat

- **Sofort machbar, unabhängig:** Registrierungs-Öffnung (7.4.1) umsetzen; Store-Texte (Kurz- und
  Vollbeschreibung) entwerfen.
- **Blockiert auf echte Angaben vom Nutzer:** Die fünf Platzhalter in `web/legal/datenschutz.html` und
  `index.html` (Name, Strasse, PLZ/Ort, Land, Kontakt-E-Mail) — danach lassen sich die Rechtstexte
  deployen und Blocker 2 und 3 aus 7.2 sind erledigt.
- **Braucht eine Produktentscheidung, bevor gebaut wird:** Die Paywall verlangt einen Free/Pro-Schnitt.
  Zwei bereits vorliegende Vorschläge widersprechen sich:
  - Das frühere Masterplan-Dokument (1.09.2026): Pro schaltet Health-Connect-Import, den
    „Gemini Hybrid Audit" und Cloud-Sync/Backup frei; **Preis ~4,99 €/Monat, Lifetime ~79,99 €.**
  - Das heutige PDF (Abschnitt 7 dort): Pro schaltet Routine-Generierung, unbegrenzte Historie plus
    CSV-Export, ACWR/Muskelbalance/e1RM-Trends und Skill-Tree/Plate-Calculator/Live-Activity frei —
    ohne Preis.

  **Diese Entscheidung braucht der Nutzer noch, bevor die Play-Billing-Integration beginnt** — welcher
  Schnitt gilt (einer der beiden, eine Mischung, oder neu), und der Preis. Siehe die Frage unten.

## 8 · Neue Vorhaben vom 20.09.2026

Drei Punkte, die der Nutzer an diesem Tag angemeldet hat. Keiner davon ist begonnen.

### 8.1 Gewichtstracking als Widget im Hybrid-Tab — ✅ erledigt (20.09.2026)

**Gebaut gegen Board 14** („Gewichtsverlauf — eine Reihe, kein Urteil"), Abschnitte A–K.
Neu: `lib/features/weight/` (Reihe, Repository, Block, Verlaufsansicht, Eingabeblatt),
die Unter-Sammlung `userProfiles/{uid}/bodyWeights` samt Regeln, Löschung und Export
(siehe Vertrag 4) und der zeitgenaue Maßstab der Trainingslast (`LoadContext.bodyWeightOn`).
Die Einstellung „Körpergewicht" schreibt nicht mehr selbst; sie zeigt den jüngsten
Verlaufseintrag und öffnet denselben Verlauf.

**Vier bewusste Abweichungen vom Board**, jeweils weil CLAUDE.md vorgeht:

1. **Widerruf 6 s statt 30 s.** Das Board zitiert Modul 7; seit dem 16.09.2026 stehen alle
   Meldungen 6 s. Zwei Fristen im selben Produkt wären ein Versprechen, das ein Bildschirm
   nicht hält.
2. **Die Lückennotiz steht unter der Kurve, nicht in ihr.** 7 sp in `#4b5563` verbietet
   CLAUDE.md für informationstragenden Text; in zulässiger Grösse passt der Satz in eine
   56 dp hohe Kurve fast nie hinein (am Render geprüft).
3. **Listenzeilen im Verlauf sind 48 dp hoch, nicht 44.** Jedes Tap-Ziel ≥ 48 dp.
4. **Das ⓘ klappt im Block auf, es öffnet kein Blatt.** So steht es in CLAUDE.md und so
   arbeitet `AtemExplainHeader` seit dem 17.09.2026.

**Eine Entscheidung, die das Board offenliess:** Der Profilwert eines Kontos von vor dem
20.09.2026 wird **nicht** als Verlaufseintrag nachgeschrieben. Er erscheint als der eine
Wert des A2-Zustands mit dem Hinweis „Aus den Einstellungen übernommen"; der erste echte
Eintrag entsteht, wenn jemand ihn macht. Ein Schreibvorgang, den ein Lesen auslöst, liefe
auf jedem Gerät erneut, bräuchte ein Merkfeld im Profil gegen Wiederauferstehung nach dem
Löschen — und sähe am Ende genauso aus.

---

### 8.1 (Ursprüngliche Beschreibung)

Ein eigener Block im Hybrid-Tab, der das Körpergewicht über die Zeit zeigt.

**Das Design kommt zuerst.** Der Nutzer lässt den Block in Claude Design entwerfen; gebaut wird erst
danach, gegen das Board (`DesignSync get_file`, Projekt `14523979-ed88-4a5a-ac09-cacf10614050`).
Nicht vorher aus der Beschreibung bauen — siehe die Rückmeldung vom 18.09.2026.

**Die Datenfrage, die das Board nicht beantwortet:** Der Bestand führt in `userProfiles/{uid}` genau
**einen** Wert `bodyWeight`. Eine Kurve braucht eine Reihe. Das ist eine neue Sammlung (Vorschlag:
`userProfiles/{uid}/bodyWeights/{datum}` mit `kg`, `date`, `source`) — und `source` zählt, sobald
8.2 dazukommt: Ein Wert aus Health Connect ist etwas anderes als ein getippter. Die bestehende
Einstellung „Körpergewicht" bleibt, was sie ist: der Wert, mit dem die Last gerechnet wird; sie zeigt
künftig den jüngsten Eintrag der Reihe.

Beachten: jede Zahl mit Grundlage, kein Urteil („Sollgewicht" gibt es nicht), Deltas ohne
Ampelfarben — die Regeln aus `CLAUDE.md` gelten hier genauso wie in der Auswertung.

### 8.2 Google Health (Health Connect)

**Google Fit ist kein Weg mehr** — die Fit-APIs sind abgekündigt und abgeschaltet. Auf Android läuft
alles über **Health Connect**, eine Systemkomponente, mit der Apps Gesundheitsdaten teilen.

**Ergänzung vom 20.09.2026:** Gewicht soll in **beide** Richtungen gehen — lesen *und*
schreiben. Der Datenweg dafür steht seit 8.1: `WeightEntry.source` unterscheidet getippt von
gemessen, `externalId` trägt die Kennung des Datensatzes in der Quelle, und die Herkunft
wechselt nur bei einer echten Änderung der Zahl. Ein selbst eingetragener Wert kann damit
zurückgeschrieben werden, ohne beim nächsten Lesen als fremder Wert wieder hereinzukommen.

Vorgehen in dieser Reihenfolge:
1. Nur **lesen**, nur **Gewicht** (`WeightRecord`). Das speist 8.1 und ist der kleinste sinnvolle
   Schnitt. Flutter-Seite: das Paket `health`, Berechtigungen einzeln je Datentyp.
   Abgleich über `externalId`; ein Tag trägt weiterhin genau einen Wert.
2. Gewicht **schreiben**: jeder Eintrag mit `source == manual` geht als `WeightRecord` zurück.
3. Danach Einheiten **schreiben**: abgeschlossene Trainings als Trainingseinheit zurückgeben,
   damit ATEM kein Datensilo ist.
4. Erst wenn das steht: Einheiten, Puls und Schlaf **lesen** — siehe 8.4.

**Der Haken liegt nicht im Code, sondern in der Freigabe.** Wer Health-Connect-Daten in einer
veröffentlichten App liest, braucht von Google eine Freigabe je Datentyp — mit Datenschutzerklärung,
Begründung je Typ und einem Demo-Video. Das ist ein weiterer Punkt für Abschnitt 7 und ein Grund,
den Datenschutztext endlich zu veröffentlichen, statt ihn als Platzhalter liegen zu lassen.

### 8.3 Garmin

**Direkt geht es nicht ohne Vertrag.** Die Garmin Health API ist server-zu-server (OAuth, Webhooks)
und setzt eine Aufnahme ins Garmin-Entwicklerprogramm voraus — ein Antrag mit Vertrag, kein
Schlüssel zum Selbstholen. Dazu bräuchte ATEM einen serverseitigen Teil, den es heute nicht gibt.

**Der pragmatische Weg führt über 8.2:** Die Garmin-Connect-App schreibt auf Android nach Health
Connect. Wer eine Garmin trägt, bringt seine Daten also schon mit — ATEM muss nur Health Connect
lesen und kennt keinen Hersteller. Damit sind Garmin, Fitbit, Withings und Samsung in einem Zug
erledigt, mit einer Anbindung statt vier.

Eine eigene Garmin-Anbindung erst, wenn jemand sie vermisst **und** etwas kommt, das über Health
Connect nicht zu haben ist. Dann ist es ein Backend-Vorhaben, kein App-Vorhaben.
