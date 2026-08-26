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
| `type` | string | 136/136 |

`type` ist der Diskriminator: `strength` (63) · `cardio` (51) · `recovery` (12) ·
`bodyweight` (10).

Je nach Art trägt das Dokument völlig verschiedene Felder:

**Kraft und Körpergewicht** — `exercises: array`, Einträge `{exerciseId: string, sets: array}`,
dazu `planId`, `planName`, `rpe`, `preWorkoutEnergy`, `postWorkoutFeeling`.

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
