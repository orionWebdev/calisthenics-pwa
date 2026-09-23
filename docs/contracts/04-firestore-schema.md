# Vertrag 4 — Firestore-Schema

**Erhoben:** 26.08.2026 am vollständigen Produktivbestand von `calisthenics-pro-57d6d`
(447 Dokumente, Sicherung siehe unten).
**Zweck:** Festhalten, wie die Daten **tatsächlich** aussehen — nicht, wie sie aussehen
sollten. Jede Abweichung zwischen diesem Dokument und einer Dart-Klasse ist ein Absturz auf
echten Nutzerdaten.

---

## Die Sicherung

`gcloud firestore export` steht nicht zur Verfügung: Er schreibt in einen
Cloud-Storage-Bucket, und das Projekt liegt auf **Spark** (`billingEnabled: false`, keine
Buckets vorhanden). Ersatz ist `tool/firestore_dump.py` — liest über die REST-Schnittstelle,
schreibt nichts, braucht nur ein Token aus `gcloud auth print-access-token`.

```
gcloud auth print-access-token | python3 tool/firestore_dump.py ~/atem-firestore-sicherung-<datum>
```

Stichtagssicherung vom 26.08.2026: `~/atem-firestore-sicherung-2026-08-26/` — 447 Dokumente.
**Sie gehört nicht ins Repository.** Sie enthält personenbezogene Trainingsdaten.

---

## Bestand

| Collection | Dokumente | Rolle |
|---|---|---|
| `sessions` | 136 | Absolvierte Einheiten — die Collection, die zählt |
| `exercises_curated` | 84 | Kuratierter Übungskatalog, global |
| `schedule` | 77 | Geplante Einheiten |

### `schedule` trägt eine `planId`

Belegt, nicht vermutet: `js/views/calendar.js`, `addPlanToDateById()` schreibt
`planId`, `planName`, `planType`, `planDuration`, `date`, `completed`,
`createdAt`. Beim Starten liest die Vorgänger-App sie wieder
(`startWorkoutFromPlan(scheduleEntry.planId, …)`).

Ausnahme sind **Schnelleinträge**: Sie tragen `isQuickEntry` und keine
`planId`. Ein Termin ohne Plan ist also gültiger Bestand, kein Defekt — er
startet als freies Training, behält aber seinen Termin.

Ich hatte das Gegenteil behauptet und den Kalendertermin deshalb als freies
Training gestartet. Der Eintrag steht hier, damit die Frage nicht ein
zweites Mal geraten wird.
| `exercises` | 70 | Nutzereigene Übungen |
| `progress` | 66 | **Demo-Ausschuss** — siehe unten, wird nicht portiert |
| `plans` | 10 | Trainingspläne |
| `userProfiles` | 2 | Profil und Einstellungen |
| `allowedUsers` | 2 | Zugangsliste für die geschlossene Beta |

`workouts` und `sessionTemplates` werden in `js/core/firebase.js` deklariert, enthalten aber
**kein einziges Dokument**. Sie werden nicht portiert.

Alle nutzereigenen Dokumente tragen die Zugehörigkeit als Feld `userId`, nicht als
Unterpfad. Es gibt **keine Untersammlungen** — auf 447 Dokumente geprüft.

---

## `sessions` — heterogen, und das ist die eigentliche Nachricht

Nur **vier Felder existieren in allen 136 Dokumenten**:

| Feld | Typ | Vorkommen |
|---|---|---|
| `userId` | string | 136/136 |
| `createdAt` | timestamp | 136/136 |
| `date` | timestamp | 136/136 |
| `startedAt` | timestamp | 0/136 — neu seit 21.09.2026 |
| `type` | string | 136/136 |

`type` ist der Diskriminator: `strength` (63) · `cardio` (51) · `recovery` (12) ·
`bodyweight` (10).

### `date` ist ein Tag, `startedAt` ist ein Zeitpunkt

`date` steht in allen 136 Dokumenten auf **lokaler Mitternacht**, und das
Repository schreibt es weiterhin so — gleich, was ein Entwurf mitbringt. Der
Tagesschlüssel im Scoring und jede Monatsgruppierung verlassen sich darauf.

Seit dem 21.09.2026 steht **daneben** `startedAt` mit der echten Uhrzeit, wenn
sie bekannt ist: aus der Uhr des Läufers oder aus einer übernommenen
Health-Connect-Einheit. Kein Dokument der Vorgänger-PWA trägt es.

Das Feld gibt es aus einem Grund: `SessionPairing` vergleicht Startzeiten.
Gegen Mitternacht gerechnet liegt jede Uhr-Einheit Stunden daneben, und bis
zum 21.09.2026 paarte die Regel deshalb **nie** — jede Uhr-Einheit wurde eine
eigene Cardio-Einheit neben der Krafteinheit, zu der sie gehörte. Wer kein
`startedAt` trägt, paart weiterhin nicht; das ist richtig so, denn ein Paar
auf geratener Zeit wäre schlechter als kein Paar.

`date` durfte dafür nicht umgedeutet werden: Dieselbe Zahl bedeutete dann in
alten Dokumenten etwas anderes als in neuen.

Je nach Art trägt das Dokument völlig verschiedene Felder:

**Kraft und Körpergewicht** — `exercises: array`, Einträge `{exerciseId: string, sets: array}`,
dazu `planId`, `planName`, `rpe`, `preWorkoutEnergy`, `postWorkoutFeeling`, seit Phase 1
zusätzlich `workoutFocus`.

**Achtung: `exercises` fehlt auch bei Kraft.** Von 63 `strength`-Sessions tragen nur 47
Übungen, 16 nicht; alle 10 `bodyweight`-Sessions tragen welche. Eine Kraft-Session ohne
Übungen ist also gültiger Bestand — vermutlich nachträglich ohne Details eingetragen. Das
Dart-Modell darf daraus keinen Fehlerfall machen, und die Auswertung muss diese Sessions
mitzählen, aber ohne Satzdaten.

**Cardio** — `activityType` (`run` 37 · `bike` 5 · `hike` 4 · `walk` 2 · `stretching` 5 ·
`yoga` 1 · `sauna` 1 · `other` 5), dazu `distanceKm`, `pace`, `avgHr`, `maxHr`, `durationSec`.

In Dart gehört das in eine **versiegelte Klassenhierarchie** mit `type` als Diskriminator,
nicht in eine Klasse mit zwei Dutzend optionalen Feldern. Eine solche Klasse könnte nicht
ausdrücken, dass `distanceKm` bei `strength` bedeutungslos ist.

### Typkollisionen — hier stürzt naiver Code ab

Dasselbe Feld trägt über die Dokumente hinweg **verschiedene Firestore-Typen**:

| Feld | Verteilung |
|---|---|
| `duration` | integer in 111, **double in 25** |
| `distanceKm` | double in 36, **integer in 8**, null in 7 |
| `pace` | double in 40, **integer in 4**, null in 7 |
| `notes` | string in 61, **null in 59** |
| `name` | string in 29, null in 10 |
| `planId` | string in 52, null in 4 |
| `avgHr` | integer in 3, null in 1 |
| `maxHr` | integer in 2, null in 2 |

Daraus folgen zwei Regeln, die nicht verhandelbar sind:

**R1 — Niemals `as int`.** Firestore liefert `num`. `doc['duration'] as int` wirft auf
25 der 136 Dokumente. Immer `(v as num?)?.toDouble()` beziehungsweise `.round()`.

**R2 — `null` und „Feld fehlt" sind derselbe Fall.** Beide kommen vor, teils im selben Feld
(`notes`: 61 string, 59 explizit null, 16 gar nicht vorhanden). Der Deserialisierer darf sie
nicht unterscheiden.

### `preWorkoutEnergy` heisst in Dart `preWorkoutReadiness`

Die einzige Stelle, an der Draht und Domänenfeld absichtlich verschiedene Namen tragen.

Der Masterplan nennt das Feld `preWorkoutReadiness`; der Bestand trägt es seit der
Vorgänger-PWA als `preWorkoutEnergy`. Ein neuer Feldname hätte zwei Felder für dieselbe Frage
bedeutet, dauerhaft zwei Lesepfade und einen Bestand, der sich in zwei Hälften teilt.

**Der Draht bleibt deshalb `preWorkoutEnergy`.** Gelesen wird er in
`session_mapper.dart`, geschrieben in `firestore_session_repository.dart` — an beiden Stellen
steht der Grund im Kommentar. `test/history/wellness_fields_test.dart` prüft ausdrücklich,
dass **kein** Feld `preWorkoutReadiness` im Dokument entsteht.

Nicht zu verwechseln mit `Readiness` aus `history/domain/readiness.dart`: Das ist die
gerechnete ACWR-Zone, dies hier eine Selbstauskunft von 1 bis 5. Sie dürfen nie ineinander
gerechnet werden.

### `workoutFocus` — neu in Phase 1, von der PWA nicht gekannt

Werte (Draht): `push` · `pull` · `legs` · `upper_body` · `lower_body` · `full_body` · `core` ·
`other`. Unbekannte Zeichenketten werden `null`, **nicht** `other` — `other` ist eine Angabe,
kein Auffangbecken.

Das Feld steht nur auf `strength` und `bodyweight`. Es beschreibt, wogegen eine Einheit ging,
und ist der einzige Weg, den **16 von 63** Krafteinheiten ohne Übungen nachträglich einen
Inhalt zu geben. Es ersetzt keine Sätze: Eine Einheit mit Fokus und ohne Sätze trägt weiterhin
kein Volumen und erscheint in keiner Muskelverteilung.

Die PWA kennt das Feld nicht. Sie scheitert nicht daran und verwirft es auch nicht —
`js/core/firebase.js:81` spreadet `...doc.data()` und reicht jedes Feld unbesehen durch.

**Keine Migration.** Alte Dokumente bleiben ohne das Feld; `null` und „fehlt" sind derselbe
Fall (R2). Die Firestore-Regeln brauchen keine Änderung: `create` prüft nur
`hasAll(['type','userId'])`.

### Satz-RPE und Körperseite — neu am 18.09.2026, von der PWA nicht gekannt

Zwei optionale Felder **am Satz** (`exercises[].sets[]`):

| Feld | Werte (Draht) | Bedeutung |
|---|---|---|
| `rpe` | Ganzzahl **1–10** | Anstrengung dieses einen Satzes. Werte ausserhalb 1–10 werden beim Lesen `null`. Ab 7 gilt der Satz als harter Satz (`LoggedSet.isHard`). |
| `side` | `left` · `right` | Seite bei einseitigen Übungen. Fehlt es, ist der Satz **beidseitig** — kein drittes Wort `both`. Unbekannte Zeichenketten werden `null`. |

**`rpe` am Satz ist nicht `rpe` an der Einheit.** Die Einheit trägt seit der PWA eine RPE auf der
Skala **1–5** (`TrainingLoad._rpeFactors`), die weiter allein die Last bestimmt. Die Satz-RPE ist feiner,
steht auf der üblichen Skala 1–10 und dient nur der Zählung harter Sätze. Die beiden werden nie
ineinander umgerechnet.

Dazu an der **Übung** (`exercises`, eigene Übungen) ein Feld `unilateral: bool` — ob sie je Seite
trainiert wird. Beim Anlegen nur geschrieben, wenn `true`; beim Ändern immer, damit es sich wieder
abschalten lässt.

Beide Satzfelder werden nur geschrieben, wenn jemand sie angegeben hat. **Keine Migration:** Der
Bestand bleibt ohne sie, und `null` heisst dort „nicht angegeben" bzw. „beidseitig" — genau das, was
er ist. Die Firestore-Regeln brauchen keine Änderung.

---

## `progress` — sauber und gleichförmig

Alle 66 Dokumente tragen dieselben fünf Felder: `userId`, `createdAt`, `date`,
`exerciseId`, `sets: array` mit Einträgen `{reps: integer, weight: integer}`.

### Geklärt: `progress` ist Demo-Ausschuss, keine Trainingsdaten

Die Frage war, ob `sessions.exercises[].sets` oder `progress.sets` die führende Quelle ist.
Vier unabhängige Belege sagen dasselbe:

**Null Überschneidung.** 292 Paare aus (Übung, Tag) in `sessions`, 62 in `progress` — die
Schnittmenge ist leer, in beide Richtungen.

**Zwei getrennte ID-Namensräume.** `sessions` referenziert Übungen als Slug (`push_up`,
`pull_up`, `archer_push_up`), `progress` über automatisch vergebene Dokument-IDs
(`CvL4ItSDPRpzErtMme8R`). Die Schnittmenge der 83 beziehungsweise 5 verwendeten IDs ist
ebenfalls leer.

**Sie folgen zeitlich aufeinander, sie laufen nicht parallel.** `progress` reicht vom
28.11.2025 bis 22.01.2026. Die erste Session mit `exercises` datiert auf den 02.02.2026. Im
gesamten `progress`-Zeitraum existiert **keine einzige** Session mit Übungen.

**Und der entscheidende Beleg steht im Code:** Die einzige Stelle in der gesamten PWA, die
nach `progress` schreibt, ist `js/dev/createDemoProgress.js` — ein Demo-Datengenerator, im
Kopfkommentar als „Kann später einfach gelöscht werden" bezeichnet. `js/views/settings.js`
fasst die Collection nur beim Löschen des Kontos an. Kein Produktivpfad schreibt sie, keiner
liest sie aus.

**Folge:** `sessions.exercises[].sets` ist die einzige Wahrheit. `progress` wird **nicht
portiert** und nicht gelesen. Die 66 Dokumente bleiben unangetastet im Bestand liegen — sie
zu löschen ist eine Aufräumentscheidung des Nutzers, keine der Migration.

### `sets` — Feldtypen

Einträge sind `{reps, weight}`. Beide können `null` sein und ganz fehlen, und einzelne
Einträge sind leere Maps ohne jedes Feld. R1 und R2 gelten hier unverändert.

---

## `userProfiles`

20 Felder, darunter für uns unmittelbar relevant: `language`, `unitSystem`, `displayName`,
`photoURL`, `defaultRestTimer`, `trainingLevel`, `trainingStyle`, `onboardingCompleted`,
`bodyWeight`, `bodyHeight`.

`language` und `unitSystem` sind die Brücke zur i18n aus Vertrag 2: Die App darf die Sprache
nicht allein aus dem Systemgebietsschema ableiten, wenn hier eine Wahl hinterlegt ist.

### `userProfiles/{uid}/bodyWeights` — neu am 20.09.2026 (Board 14)

Die Gewichtsreihe. Eine Unter-Sammlung, kein weiteres Feld im Profil: Eine Liste in einem
Dokument wächst unbegrenzt, lässt sich nicht nach Zeitraum abfragen und wird bei jedem
Eintrag ganz neu geschrieben.

| Feld | Typ | Bemerkung |
|---|---|---|
| — (Dokument-ID) | `string` | Das Datum als `yyyy-MM-dd`. **Damit ist „ein Tag, ein Wert" die Form der Daten und keine Regel im Code.** |
| `kg` | `number` | Wie überall im Bestand mal `int`, mal `double` lesen (R1). |
| `date` | `timestamp` | Lokale Mitternacht. Steht **zusätzlich** zur Kennung im Dokument, damit sich ein Fenster serverseitig begrenzen lässt. |
| `source` | `string` | `manual`, `healthConnect` oder `settings`. Unbekannte Werte werden als `manual` gelesen — ein Wert aus einer späteren Quelle darf nicht verschwinden. |
| `externalId` | `string?` | Die Kennung des Datensatzes in der Quelle. Nur bei gemessenen Werten. Ohne sie liesse sich beim zweiten Lesen aus Health Connect nicht unterscheiden, ob ein Wert neu ist oder derselbe noch einmal. |
| `updatedAt` | `timestamp` | |

**`bodyWeight` im Profil bleibt stehen** und trägt weiterhin den jüngsten Wert. Es ist die
Brücke zur Vorgänger-App, die die Unter-Sammlung nicht kennt, und der Rückfall für jede
Rechnung ohne Reihe. Geschrieben wird es nur, wenn der neue Eintrag tatsächlich der jüngste
ist — ein nachgetragener Wert vom letzten Monat darf den aktuellen nicht überschreiben.

Zwei Folgen, die leicht übersehen werden:

1. **Regeln kaskadieren nicht.** `match /userProfiles/{userId}` deckt die Unter-Sammlung
   **nicht** ab; ohne den eigenen `match /bodyWeights/{day}`-Block in `firestore.rules` fiele
   sie auf das abschliessende `allow read, write: if false` zurück.
2. **Löschen kaskadiert nicht.** Wird `userProfiles/{uid}` entfernt, bleiben die Dokumente
   der Unter-Sammlung als verwaiste Datensätze stehen — unsichtbar in der Konsole, aber
   vorhanden. `FirestoreAccountRepository.profileSubcollections` löscht und exportiert sie
   deshalb ausdrücklich; aus den sechs Sammlungen der Kontolöschung sind sieben geworden.

### `userProfiles/{uid}/healthSessions` — neu am 20.09.2026 (Board 15)

Die aus Health Connect gelesenen Uhr-Einheiten. Eine eigene Sammlung, **nicht `sessions`**
— und das ist die tragende Entscheidung des Moduls, nicht eine Ablagefrage.

`sessions` ist die Sammlung, die zählt: Last, ACWR, Muskelbalance, Sätze je Woche, harte
Sätze, Verteilung, Verhältnis, Bereitschaft. Ein wartender, ungeprüfter Datensatz darf auf
keine einzige dieser Zahlen wirken. Über ein Feld in `sessions` wäre das nur durchzuhalten,
solange **jede** dieser Rechnungen den Filter mitschreibt; vergisst eine von zwölf ihn,
zählt Ungeprüftes mit, und niemand sieht es. Getrennt liegt die Grenze in der Form der
Daten statt in der Disziplin jeder einzelnen Rechnung.

| Feld | Typ | Bemerkung |
|---|---|---|
| — (Dokument-ID) | `string` | Die Health-Connect-Kennung, `/` durch `_` ersetzt (Firestore verbietet den Schrägstrich). **Damit ist „ein Datensatz aus der Quelle, ein Dokument" die Form der Daten.** Zweimal Lesen legt nie ein zweites Dokument an. |
| `externalId` | `string` | Die **rohe** Kennung. Die Dokument-ID ist gesäubert, der Abgleich mit Health Connect läuft über diesen Wert. |
| `state` | `string` | `pending`, `accepted` oder `rejected`. Unbekannte Werte werden als `pending` gelesen — ein Zustand aus einer späteren Fassung darf einen Datensatz nicht verschwinden lassen. |
| `start`, `end` | `timestamp` | Ohne Zeitraum ist der Datensatz wertlos: Er liesse sich weder prüfen noch paaren. Ein Dokument ohne beide wird übergangen. |
| `sourceId` | `string` | Das schreibende Paket. Der Schutz gegen die Schleife, sollte ATEM je eigene Einheiten zurückschreiben. |
| `deviceName` | `string?` | Der lesbare Name für die Oberfläche — „Garmin". |
| `activity` | `string?` | Wie die Uhr das Training nennt. **Nie eine Paar-Bedingung** — Uhren melden Krafttraining regelmässig als „Andere". |
| `averageHeartRate`, `maxHeartRate` | `number?` | Health Connect liefert keinen Ø-Puls; er entsteht im Gateway aus dem Pulsverlauf der Einheit — **zeitgewichtet**, nicht als Mittel der Punkte. Seit dem 21.09.2026 Ableitungen aus `pulse`. |
| `pulse` | `map<string, number>?` | **Der Pulsverlauf als Histogramm: Sekunden je bpm** (`{"118": 42, "119": 38, …}`). Ein Messwert gilt bis zum nächsten, höchstens 60 s; eine grössere Lücke zählt nicht zur Aufzeichnung. Daraus entstehen Ø, Maximum, Minimum **und** die Zonen. Nicht die Punktwolke: Zonen werden immer neu gerechnet (Board 16, Entscheidung 15), und dafür zählt nur, wie lange welcher Wert galt. |
| `pulseWindowSeconds` | `number?` | Die Länge der Einheit in Sekunden — der Nenner zu „aufgezeichnet". Ohne ihn stünde „21 min aufgezeichnet" ohne Bezug da. |
| `pulseCurve` | `map<string, number>?` | **Die Zeitachse zu `pulse` (Board 16, offene Frage 1, gelöst am 22.09.2026): bpm je Schlitz seit Beginn**, Schlüssel ist der Schlitzindex als String (`{"0": 96, "1": 104, "3": 118, …}`). Nur Schlitze mit tatsächlicher Messung — ein fehlender ist eine echte Lücke, nie interpoliert. Fehlt das Feld ganz, wurde die Einheit vor dem 22.09.2026 gelesen: Die Rohdaten dafür sind nicht mehr da, nur noch `pulse`. |
| `pulseCurveSlot` | `number?` | **Wie lang ein Schlitz von `pulseCurve` ist, in Sekunden** (Board 16, Nachtrag, P — seit 22.09.2026 abends). `10` in allem, was seitdem gelesen wurde; **fehlt das Feld, gilt `60`** — dann sind die Schlüssel Minuten. Es steht nie ohne `pulseCurve`: ein Raster ohne Werte sagt nichts. Kein Feld wird umgerechnet, und nichts wird nachgetragen: Was minutengenau abgelegt ist, bleibt es. |

**Warum zehn Sekunden (22.09.2026).** Je Minute *ein* gemittelter Wert löschte
genau die Struktur, die ein Intervalltraining ausmacht: 40 Sekunden hart und
20 leicht ergaben einen mittleren Dauerlauf. Zehn Sekunden kosten sechsmal so
viele Einträge — für eine Stunde rund 360 statt 60, gut drei Kilobyte mehr im
Dokument — und bleiben damit weit unter dem Dokumentlimit.

**Das Raster ist nicht die Auflösung.** Eine Uhr, die nur jede Minute misst,
füllt auch im Zehn-Sekunden-Raster nur jeden sechsten Schlitz. Was tatsächlich
dasteht, sagt der Median der Abstände (`PulseProfile.curveStepSeconds`) — und
nur der darf als Wort erscheinen. „Je 10 Sekunden ein Wert" über einer
minütlich gemessenen Kurve wäre eine Zahl ohne ihre Grundlage.
| `calories`, `distanceKm` | `number?` | |
| `sessionId` | `string?` | Die App-Einheit, sobald übernommen oder zusammengeführt. Beim Lösen wird das Feld **entfernt**, nicht auf `null` gesetzt — `merge` liesse den alten Verweis sonst stehen. |
| `decidedAt` | `timestamp?` | Wann angenommen oder abgelehnt wurde. |
| `seenAt` | `timestamp` | Wann ATEM den Datensatz zum ersten Mal gelesen hat. |

**Abgelehnt heisst abgelehnt und gemerkt, nicht gelöscht.** Ohne dieses Gedächtnis läge
derselbe Datensatz beim nächsten Lesen wieder im Eingang — die schnellste Art, eine Funktion
unbenutzbar zu machen. Löschen wäre ohnehin unmöglich: Der Datensatz gehört Health Connect.
Gelöscht wird hier allein bei der Kontolöschung.

### `userProfiles/{uid}.healthSessionsReadAt` — die Lesemarke

Ein Profilfeld, kein Dokument in einer Unter-Sammlung: ein einzelner Zeitpunkt,
überschreibbar, ohne Vergangenheit. Gelesen wird beim Öffnen der App gegen diese Marke, nie
der ganze Bestand; fehlt sie, dreissig Tage zurück. Weiter zurück gibt Health Connect ohne
die zusätzliche Berechtigung `READ_HEALTH_DATA_HISTORY` nichts heraus, und ein voller
Bestandsimport erzeugte einen Eingang, den niemand durcharbeitet.

### `userProfiles/{uid}` — Herzfrequenz (Board 16, D)

Vier Felder, die die Vorgänger-PWA nicht kennt und beim Schreiben stehen lässt:

| Feld | Typ | Bemerkung |
|---|---|---|
| `hrMax` | `number?` | **Nur, was jemand selbst eingetragen hat.** ATEM schätzt HFmax nie — „220 minus Alter" wäre eine erfundene Angabe mit ±20 bpm Streuung, und auf ihr stünden fünf Zonen und jede Verteilung. |
| `hrMaxSetAt` | `timestamp?` | Wann er eingetragen wurde („selbst eingetragen am 2. Sep"). |
| `hrZones` | `array<number>?` | **Vier Grenzen, aufsteigend** — jede der erste bpm-Wert der oberen Zone (`[112, 131, 149, 168]`: Zone 1 bis 111, Zone 5 ab 168). Vier Grenzen statt fünf Bereichen: Lücken und Überlappungen sind durch Konstruktion unmöglich. Eine ungültige Folge im Dokument gilt als „nicht festgelegt", sie wird nicht repariert. |
| `hrZonesSetAt` | `timestamp?` | Wann die Grenzen festgelegt wurden — steht über jeder Verteilung („deine Zonen vom 12. Sep"). |

| `healthWeightEnabled` | `bool?` | **Der Schalter in ATEM**, nicht die Freigabe des Systems: Aus heisst, ATEM liest und schreibt Körpergewicht nicht mehr. Health Connect kennt für eine App nur „alles entziehen", nicht je Datentyp — ein Schalter je Zeile muss deshalb hier sitzen. Fehlt das Feld, gilt **an**: Wer vor dem 21.09.2026 freigegeben hat, soll nicht plötzlich nichts mehr abgleichen. |
| `healthSessionsEnabled` | `bool?` | Dasselbe für Trainingseinheiten und Puls. |

Gespeichert werden immer **bpm**, nie Prozent. Der Vorschlag aus HFmax (60/70/80/90 %,
aufgerundet) rechnet einmal und schreibt Grenzen; danach bleibt jede einzeln änderbar, und
eine spätere Änderung von HFmax verschiebt sie nicht.

### `sessions` bekommt zwei Felder — die Herkunft

| Feld | Typ | Bemerkung |
|---|---|---|
| `healthSessionId` | `string?` | Die Kennung der verknüpften Uhr-Einheit. **Eine Verknüpfung, kein Überschreiben:** Der Uhr-Datensatz liegt als eigenes Dokument daneben und behält alles, was er mitbrachte. Deshalb ist „Verbindung lösen" verlustfrei. |
| `fromHealth` | `bool` | Ob die Einheit **aus** der Uhr entstanden ist. Nicht dasselbe wie ein Verweis: Eine in der App geführte Einheit kann mit einer Uhr-Einheit verknüpft sein, ohne aus ihr zu stammen. |

Beide fehlen in jedem Dokument von vor dem 20.09.2026 — das ist der Normalfall und heisst
„in der App geführt". Aus beiden zusammen folgen die drei Punktformen der Einheitenzeile:
gefüllt (nur App), hohl (nur Uhr), Ring mit Kern (beides). Die vierte Form — gestrichelt,
„ungeprüft" — gehört keiner Einheit, sondern einem Dokument in `healthSessions`.

**Keine Grösse hat zwei Quellen.** Sätze, Dauer, Anstrengung und Notiz kommen aus der App,
Puls und Kalorien aus der Uhr. Es wird nie gemittelt und nie gewählt, es wird zugeordnet —
deshalb steht hier auch keine Quellenkarte je Feld, sondern nur der Verweis.

### `userProfiles/{uid}/planning` — Zielbriefing und Woche (Boards 18–19, vorab am 23.09.2026)

Festgelegt **vor** dem Design-Gespräch, damit das Board nicht ins Blaue entwirft. Die Felder
im Einzelnen entscheiden die Boards; was hier steht, sind die Grenzen, die sie nicht
verschieben.

**Drei Dinge, die gleich klingen und es nicht sind:**

| | Was es ist | Wo es liegt |
|---|---|---|
| **Plan** | Eine Übungsliste mit Zielvorgaben. Hat kein Datum. | `plans` |
| **Termin** | Eine Einheit an einem bestimmten Tag, mit oder ohne Plan. Bestand der Vorgänger-App; ATEM liest ihn und hakt ihn ab, legt aber keinen an. | `schedule` |
| **Wochenplan** | Ein wiederkehrender Rhythmus: welche Art an welchem Tag, optional mit einem Plan. Hat kein Datum, sondern Wochentage. | `planning/week` (Board 19) |
| **Zielbriefing** | Was jemand selbst über sein Training sagt. Erzeugt keine Einheit. | `planning/goal` (Board 18) |

Ein Wochenplan ist deshalb **kein `Plan`**: In `plans` erschiene er in der Vorgänger-App als
Übungsliste ohne Übungen. Und er ist **kein Stapel `schedule`-Termine**: Vorab angelegte
Termine für Wochen im Voraus müssten bei jeder Änderung des Rhythmus gelöscht und neu
geschrieben werden, und ein abgehakter Termin aus einem alten Rhythmus wäre von einem neuen
nicht zu unterscheiden. „Heute" wird aus dem Rhythmus **abgeleitet**, nicht gespeichert.
Liegt für denselben Tag zusätzlich ein Termin in `schedule`, gewinnt der Termin — das
Datierte schlägt das Wiederkehrende —, solange Board 19 nicht anders entscheidet.

**Warum eine Unter-Sammlung und kein Feld im Profil.** Die Vorgänger-App legt das Profil mit
`set` **ohne** `merge` neu an, wenn sie es nicht laden konnte (`js/views/settings.js`,
`createDefaultProfile` — auch bei einem Netzfehler). Ein Feld im Profil wäre dann weg, ohne
dass es jemand merkt. Eine Unter-Sammlung übersteht das.

**`planning/goal` — das Zielbriefing:**

- **Nichts ist vorbelegt, nichts wird ergänzt.** Eine unbeantwortete Frage **fehlt** im
  Dokument. Sie steht nicht als `0`, `false` oder `[]` da: „Cardio 0× die Woche" ist eine
  Aussage, „Cardio nicht beantwortet" keine. Liest der Code eine fehlende Antwort als Null,
  entsteht genau die falsche Zahl, vor der Board 04 warnt.
- **Es gibt kein Briefing als Ganzes, nur einzelne Antworten** (Board 18, F1). Kein
  `completedAt`, kein Status, keine Schwelle: Jede Antwort gilt ab ihrem eigenen Datum.

Die Felder (Board 18, Sektion C):

| Feld | Typ | Bemerkung |
|---|---|---|
| `modalities` | `array<string>` | `strength`, `cardio` oder beide. **Die einzige Stelle, an der eine Null entstehen darf**: Fehlt `cardio` hier bei beantworteter Frage, ist „kein Cardio" gesagt. |
| `weekPattern` | `string` | `same` · `alternating` · `irregular` |
| `anchorWeekStart` | `string` | `yyyy-MM-dd`, der Montag einer Woche A. Nur bei `alternating`. Ohne ihn wüsste keine Woche, ob sie A oder B ist. |
| `perWeek` | `map` | `{strength?: 1–8, cardio?: 1–8}`, `8` heisst „8+". Einheiten, nicht Tage. Keine `0`. |
| `perWeekB` | `map` | Dasselbe für Woche B, nur bei `alternating`. |
| `schedule` | `string` | `fixed` · `free` |
| `days` | `map` | `{strength?: [1–7], cardio?: [1–7]}`, ISO-Wochentag. Nur bei `fixed`. |
| `multiPerDay` | `string` | `no` · `some` · `most` |
| `dayparts` | `map` | `{strength?: […], cardio?: […]}` aus `morning` · `midday` · `evening`. Nur bei `some`/`most`. |
| `places` | `array<string>` | `home` · `gym` · `outdoor` |
| `goals` | `array<string>` | `weight` · `endurance` · `mobility` · `fitness` · `health` · `strength` · `muscle`. Ungeordnet — die Reihenfolge im Array ist keine Rangfolge. |
| `describes` | `string` | `current` · `intended` |
| `answeredAt` | `map<string, timestamp>` | **Je Feld, nie fürs Ganze.** Gleich verschachtelt wie der Wert: `answeredAt.perWeek.strength` gehört zu `perWeek.strength`. Geschrieben über Feldpfade mit `update`, deshalb entsteht eine Verschachtelung und kein Schlüssel mit Punkt. |

**Drei Schreibregeln** (Board 18, C):
1. Offen heisst: der Schlüssel fehlt. Zurücknehmen löscht ihn **samt** `answeredAt`.
2. Abhängiges geht mit: Wer „nur Kraft" wählt, löscht im selben Schreibvorgang alles unter
   `cardio`. Versteckt aufbewahrte Werte sickerten sonst in eine spätere Ableitung.
3. Jede Antwort ist ein eigener Schreibvorgang, Feld-Update mit Merge. Eine Ablehnung setzt
   genau dieses Feld zurück, nie das Dokument.
- **Unbekannte Felder werden beim Lesen übergangen und beim Schreiben nicht gelöscht**
  (`merge`). Eine spätere Fassung darf Fragen ergänzen, ohne dass eine ältere App sie
  verwirft.
- **`updatedAt`** steht immer. Jede spätere Ableitung nennt, auf welchem Stand sie beruht
  („nach deinem Briefing vom 23. Sep").
- **Die Altfelder `trainingStyle` (`gym` · `bodyweight` · `hybrid`) und `trainingLevel` im
  Profil werden nicht übernommen und nicht überschrieben.** Sie beantworten eine andere
  Frage (Ausstattung, Selbsteinschätzung) und haben in ATEM keinen Abnehmer. Die
  Vorgänger-App liest sie weiter.

**`planning/week` — der Wochenplan:** Die Felder entscheidet Board 19. Vorab fest:

- Ein Eintrag verweist auf einen Plan über `planId` und trägt zusätzlich dessen Namen.
  Ein **gelöschter Plan ist der Normalfall**, nicht der Fehler — der Eintrag bleibt als
  freies Training seiner Art stehen, wie ein Termin ohne `planId` (siehe `schedule`).
- **Cardio hat keine Pläne.** Ein Cardio-Eintrag trägt seine Art und optional eine Dauer,
  nie eine `planId`.

**Folgen, die leicht übersehen werden** — dieselben wie bei `bodyWeights`:

1. `firestore.rules` braucht einen eigenen `match /planning/{doc}`-Block unter
   `userProfiles/{userId}`, sonst greift das abschliessende `allow read, write: if false`.
2. `FirestoreAccountRepository.profileSubcollections` bekommt `planning` — sonst bleibt das
   Briefing nach einer Kontolöschung stehen und fehlt im Datenexport.

## `allowedUsers`

Zwei Felder: `email`, `enabled`. Das ist die Zugangsliste der geschlossenen Beta aus Stufe 7.
Zwei Einträge — beide Konten des Entwicklers.

---

## Zugriffsregeln — und warum die Datei im Repo nichts beweist

Am 26.08.2026 fiel beim Vergleich auf: **Die aktiven Rules waren nicht die aus dem
Repository.** `firestore.rules` enthielt eine sorgfältige Fassung mit Allowlist,
Eigentümerprüfung und Standard-Verbot. Ausgerollt war seit dem 10.01.2026 dies:

```
match /{document=**} { allow read, write: if true; }  // Nur für Development!
```

Ohne Anmeldung, lesend und schreibend, auf den gesamten Bestand — bei einem
**öffentlichen** Repository, das Projekt-ID und API-Schlüssel im Klartext enthält
(`js/core/firebase.js`).

**Regel daraus: Die Datei im Repo ist eine Absicht, kein Zustand.** Vor jeder Arbeit am
Datenzugriff wird das aktive Ruleset abgerufen und verglichen, und die Wirkung wird mit
einer Leseanfrage ohne Anmeldung gegengeprüft. Erwartet wird `403`.

```
firebase deploy --only firestore:rules
```

Stand 26.08.2026: Ruleset `c716099d`, 217 Zeilen, deckungsgleich mit `firestore.rules`,
nicht angemeldeter Lesezugriff auf `sessions` antwortet mit `403`.

### Die Allowlist wird über die Dokument-ID geprüft, nicht über das Feld

`isAllowed()` schlägt `allowedUsers/{uid}` nach, ersatzweise `allowedUsers/{email}`. Das
Feld `email` **im Dokument** wird nie gelesen — Rules können nachschlagen, nicht suchen.

Das war beim Zusperren fast ein Eigentor: Der Eintrag für
`christian.mueller2311@gmail.com` lag unter der automatisch vergebenen ID
`6nwbVW2uIDfxkAx2c24P` (20 Zeichen, also `.add()` statt `.doc(uid).set()`). Weder UID noch
E-Mail trafen zu, und das Konto mit **64 der 136 Sessions** wäre ausgesperrt gewesen.
Behoben durch ein zusätzliches Dokument unter der echten UID; der verwaiste Eintrag bleibt
liegen.

**Für jeden neuen Zugang gilt: Dokument-ID = UID, nicht `.add()`.**

Die 26 Sessions von `demo-user-123` sind seit dem Zusperren unzugänglich. Das ist richtig
so — es sind keine echten Daten.

---

## Der Lesepfad ist am echten Bestand geprüft

27.08.2026, Honor VKJ-NX9, Debug-Build `com.atemhybrid.app`:

```
PROBE 46 Einheiten
```

46 ist die Anzahl der Sessions von `mueller.webdev@gmail.com` — genau die des
angemeldeten Kontos, nicht die Gesamtzahl 136. Damit ist der Weg vollständig belegt:
Google-Anmeldung, Firebase Auth, Allowlist-Prüfung, Eigentümerfilter der Regeln, Abfrage,
Mapper, Domänenobjekte. Kein übersprungenes Dokument.

**Nebenbefund, der Zeit gekostet hat:** `developer.log` aus `dart:developer` schreibt in den
Dart-VM-Dienst und erscheint in DevTools und unter `flutter run` — **nicht im Logcat**. Wer
mit `adb logcat` mitliest, sieht nichts, obwohl die App protokolliert. Für die Diagnose vom
Gerät ist `debugPrint` das richtige Mittel.

---

## Eine bewusste Abweichung vom Scoring der PWA

Die Portierung von `js/views/sessions/scoring.js` wird mit einem Orakel geprüft:
`tool/scoring_oracle.mjs` führt das **echte JavaScript** über deterministisch erzeugte
Einheiten aus und schreibt Eingaben und Ergebnisse nach
`test/fixtures/scoring_oracle.json`. `test/history/scoring_oracle_test.dart` schickt
dieselben Eingaben durch die Dart-Fassung und vergleicht Zahl für Zahl — Rohlast je
Einheit, Erholungserkennung, jede Stützstelle der Bewertungskurve, ACWR über sieben
Referenztage mit und ohne Ermüdungsabzug.

Dabei kam ein Fehler in der PWA zum Vorschein.

`getACWR` bildet die Fenstergrenze als `refDay.getTime() - 56 * 24 * 60 * 60 * 1000`.
Liegt eine Zeitumstellung im Fenster, ergibt das **23:00 des Vortags** statt Mitternacht:

```
refDay    : Fri Apr 10 2026 00:00:00 GMT+0200
loopStart : Thu Feb 12 2026 23:00:00 GMT+0100
letzter   : Thu Apr 09 2026 23:00:00 GMT+0200
```

Die Schleife läuft `while (cursor <= refDay)` und schleppt die Uhrzeit mit. Sie endet
damit einen Tag zu früh — **der Referenztag fällt aus dem gleitenden Mittel heraus**.
Zweimal im Jahr, jeweils für die folgenden acht Wochen. Dieselbe Rechnung steht in
`computeFormScore` mit einem 120-Tage-Fenster.

**Die Dart-Fassung rechnet kalendarisch** (`DateTime(y, m, d - 56)`) und ist damit
unabhängig von der Zeitumstellung. Das ist eine bewusste Abweichung, kein Versehen:

- Ohne Zeitumstellung im Fenster stimmen beide Fassungen **exakt** überein.
- Mit Zeitumstellung im Fenster **muss** die Dart-Fassung abweichen — der Test
  verlangt das ausdrücklich, damit der Fehler nicht unbemerkt übernommen wird.

Das Orakel liefert beide Auswertungen: `pwa` für den Ist-Zustand, die Felder daneben für
die korrigierte Rechnung. Solange App und PWA nebeneinander laufen, können ihre
Readiness-Werte im Frühjahr und Herbst deshalb um wenige Punkte auseinandergehen.

**Nicht übernommen wurde dagegen** eine zweite Auffälligkeit: `isRecoverySession` prüft
`type` gegen `cardio`, `recovery` und `strength` — **`bodyweight` fehlt in der Liste**. Ob
Absicht oder Versehen, ist nicht zu erkennen. Die Portierung bildet es ab, statt es
stillschweigend zu ändern: Eine Korrektur verschöbe jeden historischen Wert.
