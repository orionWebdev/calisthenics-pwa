# Übergabe an eine neue Sitzung

**Stand:** 23.09.2026, Commit `2e51f60`, Branch `flutter/foundation`, Arbeitsbaum
sauber, nichts unveröffentlicht. **1312 Tests grün.**
Alles ab der Trennlinie in ein neues Claude-Code-Terminal im Repo-Wurzelverzeichnis einfügen.

---

Du übernimmst die Arbeit an **ATEM Hybrid** (Flutter, Android). Lies zuerst, dann arbeite.

## Wo alles steht

1. **`CLAUDE.md` im Repo-Wurzelverzeichnis** — die Arbeitsanweisung. Sie hat Vorrang vor
   allem, was hier steht: Tokens, Textstufen, 48-dp-Trefferflächen, 200 % Schrift auf
   320 dp, keine Ampelfarben, jede Zahl mit Nenner, Zustände sind Pflicht. Lies sie ganz,
   bevor du eine Zeile änderst.
2. **`docs/design-prompts/`** — die Gespräche mit Claude Design, aufsteigend nummeriert.
   Zuletzt `16b-nachtrag-herkunft-und-pulskurve.md` (zweimal durchgelaufen, vollständig
   umgesetzt).
3. **`design_handoff_atem_app/design_refs/`** — die Spezifikations-Boards. **01–11 und
   13–17** liegen als `.dc.html` im Repo (gespiegelt am 23.09.) und sind mit
   `python3 tool/read_board.py 16` ohne Browser lesbar. **Board 12** (Kraft-Tab als
   wischbare Seiten) gibt es nicht mehr — Board 13 hat es abgelöst.
   **Board 16 ist abgeschnitten**: `DesignSync get_file` liefert höchstens 256 KiB, das
   Board ist grösser. Die Datei im Repo endet mitten im Entscheidungsprotokoll (N12);
   alles danach steht nur in Claude Design (Projekt
   `14523979-ed88-4a5a-ac09-cacf10614050`). Ein Board, das so gross wird, muss der Nutzer
   von Hand exportieren.
4. **`docs/contracts/`** — die verbindlichen Verträge: A11y, i18n, Architektur, Firestore-
   Schema. Bei Datenmodell-Änderungen gehört ein Absatz in `04-firestore-schema.md`.
5. **`docs/gemini_produktstrategie_2026-09-18.md`** — der alte Fahrplan. **Er ist
   abgearbeitet und nicht mehr gepflegt**: Abschnitt 2 steht vollständig, Abschnitt 8
   ebenso, und alles ab Board 15 fehlt darin. Als Bestandsaufnahme brauchbar, als
   Wegweiser nicht mehr.
6. **`~/.claude/plans/bitte-schaue-dir-unsere-zazzy-cookie.md`** — der Arbeitsplan vom
   22.09. mit den zwei Gleisen, der Modellzuordnung und den offenen Nutzerentscheidungen.

## Was gerade fertig geworden ist (22./23.09.2026)

- **Gesundheitswerte in der Belastungssteuerung** (A1 des Plans, vier Commits). Fehlt eine
  eingetragene Anstrengung, speist der gemessene Pulsverlauf sie — für **Cardio**, nicht
  für Kraft. Reihenfolge: eingetragen schlägt gemessen schlägt Ersatzwert. Ein gemessener
  leichter Lauf zählt jetzt als aktive Erholung.
- **Der Nachtrag zu Board 16 ist vollständig**: Lastkachel mit Grundlagenzeile
  („gerechnet · ○ gemessen 3 von 5"), Pulsverlauf mit Zonenfarben, neutralem Gitter,
  Wertpunkten, Taktstreifen, Slider-Semantik und Wechselmarke; Zonenzeilen mit Farbpunkt.
- **Der Pulsverlauf wird alle zehn Sekunden abgelegt** statt je Minute
  (`pulseCurveSlot` im Schema). Vorhandene Kurven bleiben minutengenau; eine Minutenkurve
  wird einmal neu gelesen, solange die Uhr die Rohwerte hergibt.
- **Ein Zonensystem statt zwei** — `cardio_intensity.dart` fragt jetzt die festgelegten
  Grenzen statt einer eigenen Prozenttabelle.
- **Der Cardio-Tab steht wieder in der Leiste.** Regeneration bleibt draussen (drei Plätze).

## Was als Nächstes ansteht

**In dieser Reihenfolge, solange der Nutzer nichts anderes sagt:**

1. ~~Boards ins Repo spiegeln~~ — erledigt am 23.09. (13, 14, 15, 17; 12 ist abgelöst).
   Offen bleibt nur der Schwanz von Board 16, siehe oben.
2. ~~CI einrichten~~ — erledigt am 23.09. (`.github/workflows/ci.yml`; was fehlt und
   warum, steht in `docs/contracts/03-architecture.md` § CI). Ursprünglicher Auftrag:
   **CI einrichten.** `.github/workflows/` gibt es nicht, obwohl beide Tore existieren und
   im Vertrag als „CI-Tor" beschrieben sind: `flutter analyze lib test` · `flutter test` ·
   `dart tool/check_conventions.dart` · `flutter gen-l10n && git diff --exit-code
   lib/l10n/gen`. Die Tags `render` und `debt` bleiben draussen.
3. ~~Modul 18 — das Zielbriefing~~ — **gebaut am 23.09.** gegen Board 18
   (`design_refs/18_Zielbriefing.dc.html`): Einstellungen → Training →
   „Trainingsangaben", Daten unter `userProfiles/{uid}/planning/goal`.
   **Offen:** `firebase deploy --only firestore:rules` — ohne den neuen
   `planning`-Block lehnt der Server jede Antwort ab (die Seite zeigt dann
   die Speicherfehlerzeile). Das Board empfiehlt, die Seite **mit oder nach
   Board 19** auszuliefern; bis dahin ist sie ehrlich („Genutzt von · bisher
   keiner Auswertung"), aber ohne Abnehmer. **Als Nächstes: Board 19, die
   Woche von Hand** — Sektion K von Board 18 hält fest, was es voraussetzt.
   Ursprünglicher Auftrag: **Modul 18 — das Zielbriefing.** Der grösste offene Brocken, und der erste Schritt der
   Wochenplanung. **Entschieden am 22.09.:** Die Planung lebt als **eigene Unterseite aus
   dem Hybrid-Tab**, mit einem kleinen Widget im Tab, das „Was wird heute trainiert"
   beantwortet. Reihenfolge: **Zielbriefing → Woche von Hand → Vorschlag** (Boards 18, 19,
   20). Ein generierter Plan ohne Zielbriefing wäre das Sollverhältnis, das `CLAUDE.md`
   verbietet.
   **Vor dem Prompt** gehört ein Absatz ins Firestore-Schema: Ein Wochenplan ist kein
   `Plan` (der ist eine Übungsliste). Und Board 04 hat entschieden „Nur was ohne Angabe
   eine falsche Zahl erzeugt, darf den Einstieg blockieren" — ein Zielbriefing gehört
   deshalb **nicht** in das Onboarding.
3b. ~~Board 18b — Bewegungsgrammatik~~ — **gebaut am 23.09.** (sechs Commits
   `feat(18b)`, Regeln jetzt auch in `CLAUDE.md`). Offen daraus: die Kante für
   „erstmals gesehen" (gespeicherte Einheit im Verlauf, freigeschalteter
   Auswertungsblock — braucht ein Gedächtnis über App-Sitzungen hinweg), die
   Querblende beim Übungswechsel im Runner, die Ansage „Satz 3 erledigt.
   Pause 90 Sekunden." prüfen, und der Scan an Einstellungsblöcken.
3c. **Board 19 (Woche von Hand)** und **Board 21 (Hauptmuskel und
   Hilfsmuskeln)** — beide Prompts liegen in `docs/design-prompts/`, beide
   warten auf Claude Design. 21 ist datenseitig vorbereitet: alle 84
   kuratierten Übungen tragen `primaryMuscles`, die App verschmilzt sie heute
   in `displayMuscles` und zählt Hilfsmuskeln in der Muskelbalance voll.
4. **Store-Vorlauf**, sobald der Nutzer die Gewerbefrage entschieden hat. Die
   Datenschutzseite ist für die Health-Connect-Freigabe Pflicht und braucht fünf Angaben,
   die nur er hat. Persönliche Play-Konten von nach dem 13.11.2023 brauchen ausserdem
   **12 Tester über 14 Tage** — das hat Vorlauf.
5. **Muskelvisualisierung**, **8.2 Schritt 3** (Einheiten nach Health Connect
   zurückschreiben), **Lockscreen-Timer**, **KI-Empfehlungen** — in dieser Reihenfolge,
   alles später.

**Nicht bauen**, solange niemand fragt: Skill-Tree (Redaktionsarbeit am Übungskatalog),
Tempo/TUT.

## Offene Entscheidungen, die nur der Nutzer treffen kann

- **Gewerbe ja/nein** — entscheidet, ob die Paywall kommen kann und ob das Play-Konto
  persönlich oder eine Organisation wird.
- Die **fünf Platzhalter** in `web/legal/datenschutz.html` und `index.html`.
- Der **Free/Pro-Schnitt** und der Preis (zwei widersprüchliche Vorschläge liegen vor).
- **Bekommt Kraft auch eine pulsgespeiste Anstrengung?** Heute nur Cardio. Die
  Beschränkung steht an einer einzigen Stelle: `MeasuredEfforts.of`.

## Wie hier gearbeitet wird

- **Sprache:** Deutsch, im Code, in Kommentaren, in Commit-Nachrichten, im Gespräch.
- **Zwei Gleise in git-Worktrees.** `../atem-neben` auf `flutter/neben` existiert bereits.
  Am Arbeitsverzeichnis arbeiten zeitweise mehrere Sitzungen; am 20.09. ist dabei Arbeit
  verloren gegangen. **Vor jedem Commit `git status`**, fremde Änderungen nicht mit
  einsammeln, eine Datei nie aus `HEAD` neu aufbauen, wenn sie fremde Änderungen trägt.
- **Zeichenketten** nie von Hand in die ARB-Dateien schreiben:
  `python3 tool/i18n/add_strings.py neue.json`, dann `flutter gen-l10n`.
  **Platzhalter immer ausdrücklich deklarieren** — ohne `placeholders` ordnet `gen-l10n`
  die Parameter **alphabetisch**, und `„{span} · {resolution}"` wird zu
  `f(resolution, span)`. Genau so stand am 22.09. „je Minute ein Wert · 100–175 bpm" auf
  dem Schirm.
  **`tool/board_strings.py NN --write` sortiert die ganze ARB-Datei
  alphabetisch um** — der Inhalt stimmt, der Diff ist aber Rauschen über
  11 000 Zeilen. Danach die Reihenfolge aus `HEAD` wiederherstellen und nur
  die neuen Schlüssel anhängen (so geschehen am 23.09. für Board 18).
  **Und nur mit Bedacht** — für Board 16 hätte es 13
  bestehende Schlüssel überschrieben, darunter bewusst geänderte.
- **Tests:** `flutter analyze lib test`, `flutter test` und
  `dart tool/check_conventions.dart` müssen grün sein, bevor du committest. Zurzeit 1312
  Tests. Neue Funktionen brauchen Tests, A11y eingeschlossen. Bei Änderungen an der
  Lastrechnung muss `test/history/scoring_oracle_test.dart` **unverändert** grün bleiben.
- **Bilder statt Raten:** `ATEM_RENDER_DIR=/pfad flutter test --tags render
  test/render/…` schreibt echte PNG mit den richtigen Schriften. **Sieh sie dir an** — in
  dieser Runde kamen vier Fehler nur so ans Licht: vertauschte Platzhalter, ein doppelter
  Satzpunkt, „Aus 53 von 52 min Aufzeichnung", und Wertpunkte, die bei feiner Ablage die
  Zonenfarben vollständig überdeckten.
- **`dart format` nie über ganze Ordner.** Eigene Zeilen von Hand umbrechen, danach
  `git diff` lesen: Jede Zeile darin muss zur Aufgabe gehören.
- **Aufs Gerät:** `flutter build apk --release`, dann
  `~/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk`.
  **Falle:** `adb` braucht USB-Zugriff. Wird der adb-Server aus einer Sandbox heraus
  gestartet, sieht er **kein Gerät** — `adb devices` bleibt leer, obwohl das Telefon
  hängt. Dann `adb kill-server` und den nächsten Aufruf **ohne Sandbox** ausführen.
  `system_profiler SPUSBDataType` liefert aus der Sandbox ebenfalls nichts; seine Leere
  ist **kein** Beweis, dass nichts angeschlossen ist.
  Screenshots vom Honor gehen nicht über `screencap` (liefert Schwarz), sondern über
  `adb shell input keyevent 120` und Ziehen aus `/sdcard/Pictures/Screenshots`.
  Ziehgesten für den Schieber: `adb shell input motionevent DOWN/MOVE/UP`.
- **Design-Ablauf:** Prompt nach `docs/design-prompts/NN-thema.md` (mit eigenem
  Motion-Abschnitt) → der Nutzer lässt ihn in Claude Design laufen → **gegen das Board**
  bauen, nicht gegen die Beschreibung → **das Board ins Repo spiegeln**. Fehlt dir der
  Zugang, sag es ihm; bau nicht ersatzweise drauflos.
  Weicht das Board von `CLAUDE.md` ab, gewinnt `CLAUDE.md` — und die Abweichung gehört
  mit Grund in die Commit-Nachricht.
- **Nie committen:** `android/key.properties`, `android/app/atem-upload-key.jks`.
- **Nie erfinden:** echte Identitätsdaten für Impressum oder Datenschutz.
- **Kein Bezug zu Keyperformance** — nirgends, auch nicht in Store-Texten.

Beginne damit, `CLAUDE.md` zu lesen und `git status` sowie `git worktree list` zu prüfen,
und sag dann in drei Sätzen, was du als Nächstes tun willst.
