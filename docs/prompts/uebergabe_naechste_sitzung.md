# Übergabe an eine neue Sitzung

**Stand:** 20.09.2026, Commit `6b61094`, Branch `flutter/foundation`, Arbeitsbaum sauber.
Alles ab der Trennlinie in ein neues Claude-Code-Terminal im Repo-Wurzelverzeichnis einfügen.

---

Du übernimmst die Arbeit an **ATEM Hybrid** (Flutter, Android). Lies zuerst, dann arbeite.

## Wo alles steht

1. **`CLAUDE.md` im Repo-Wurzelverzeichnis** — die Arbeitsanweisung. Sie hat Vorrang vor
   allem, was ich hier schreibe: Tokens, Textstufen, 48-dp-Trefferflächen, 200 % Schrift auf
   320 dp, keine Ampelfarben, jede Zahl mit Nenner, Zustände sind Pflicht. Lies sie ganz,
   bevor du eine Zeile änderst.
2. **`docs/gemini_produktstrategie_2026-09-18.md`** — der Fahrplan. Abschnitt 6 nennt die
   Reihenfolge, Abschnitt 7 den Stand der Play-Store-Freigabe, **Abschnitt 8 die drei neuen
   Vorhaben** vom 20.09.2026. Erledigtes ist im Dokument mit ✅ und Datum markiert; trag
   nach, was du fertigstellst.
3. **`docs/contracts/`** — die verbindlichen Verträge: A11y, i18n, Architektur, Firestore-
   Schema. Bei Datenmodell-Änderungen gehört ein Absatz in `04-firestore-schema.md`.
4. **`docs/design-prompts/`** — die Gespräche mit Claude Design, aufsteigend nummeriert.
5. **`design_handoff_atem_app/`** — die Spezifikations-Boards der Module 1–11.

## Was gerade fertig geworden ist

- 2.1 Weighted Calisthenics, 2.2 Satz-RPE mit Seiten und harten Sätzen, 2.4 Scheibenrechner,
  2.3 RIR-Umschalter — alle vier ✅ im Fahrplan.
- Der Kraft-Tab ist seit dem 20.09. **ein durchgehender One-Pager** mit
  `AtemSectionNav` (vier Abschnitte: Trainieren, Verlauf, Auswertung, Pläne).
- Der Runner springt nach dem letzten Satz einer Übung sofort weiter; eine fehlende
  Anstrengung lässt sich über „+ Anstrengung eintragen" nachtragen.

## Was als Nächstes ansteht

**In dieser Reihenfolge, solange der Nutzer nichts anderes sagt:**

1. **Gewichtstracking im Hybrid-Tab** (Abschnitt 8.1). **Nicht anfangen zu bauen, bevor das
   Design-Board da ist.** Der Prompt dafür liegt fertig in
   `docs/design-prompts/14-gewichtstracking.md`; der Nutzer lässt ihn in Claude Design
   durchlaufen. Wenn er sagt, das Board sei fertig: über `DesignSync get_file` lesen
   (Projekt `14523979-ed88-4a5a-ac09-cacf10614050`, vorher `/design-login`) und **gegen das
   Board** bauen, nicht gegen die Beschreibung. Fehlt dir der Zugang, sag es ihm — bau nicht
   ersatzweise drauflos.
   Offene Entscheidung, die dabei fällt: Das Profil führt heute genau **einen**
   `bodyWeight`-Wert; eine Kurve braucht eine Reihe (Vorschlag im Dokument:
   `userProfiles/{uid}/bodyWeights/{datum}` mit `kg`, `date`, `source`).
2. **Health Connect** (8.2), klein anfangen: nur Gewicht lesen, das speist Punkt 1. Google
   Fit ist abgeschaltet und keine Option. Der Aufwand steckt in Googles Freigabe je
   Datentyp, nicht im Code.
3. **Garmin** (8.3) **nicht** direkt anbinden. Garmin Connect schreibt nach Health Connect;
   damit erledigt Punkt 2 Garmin, Fitbit und Withings in einem Zug.
4. **Skill-Tree** (2.5) bleibt zurückgestellt — er braucht zuerst ausgearbeitete
   Übungsketten vom Nutzer, das ist Redaktionsarbeit.
5. **Tempo/TUT** (2.6) **nicht bauen**, solange niemand danach fragt.
6. **Play Store** (Abschnitt 7) ruht. Der Deploy ist ausdrücklich der **letzte** Schritt.
   Nicht von selbst an Rechtstexten, Registrierungs-Öffnung oder Paywall weiterarbeiten.

## Wie hier gearbeitet wird

- **Sprache:** Deutsch, im Code, in Kommentaren, in Commit-Nachrichten, im Gespräch.
- **Zeichenketten** nie von Hand in die ARB-Dateien schreiben. Es gibt ein Hilfsskript im
  Scratchpad der Sitzung (`add_strings.py <json>`); frag den Nutzer danach, wenn du es nicht
  findest. Danach `flutter gen-l10n`.
- **Tests:** `flutter analyze lib test` und `flutter test` müssen grün sein, bevor du
  committest. Zurzeit 929 Tests. Neue Funktionen brauchen Tests, A11y eingeschlossen.
- **Bilder statt Raten:** `test/render/` schreibt mit `ATEM_RENDER_DIR=/pfad flutter test
  test/render/…` echte PNG mit richtigen Schriften. Sieh dir an, was du gebaut hast.
- **`dart format` nie über ganze Ordner** — das Repo ist mit einer älteren Formatierung
  geschrieben, und der Befehl bricht hunderte fremde Zeilen um. Eigene Zeilen von Hand
  umbrechen, danach `git diff` lesen: Jede Zeile darin muss zur Aufgabe gehören.
- **Vor jedem Commit `git status`.** An diesem Arbeitsverzeichnis arbeiten zeitweise mehrere
  Sitzungen gleichzeitig. Fremde uncommittete Arbeit nicht mit einsammeln, und eine Datei
  niemals aus `HEAD` neu aufbauen, wenn sie fremde Änderungen trägt — dabei ist am 20.09.
  schon einmal Arbeit verloren gegangen. Zwei getrennte Commits sind richtig.
- **Aufs Gerät:** `flutter build apk --release`, dann
  `~/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/flutter-apk/app-release.apk`.
  Danach starten und `adb logcat` auf Abstürze prüfen. Screenshots vom Honor gehen **nicht**
  über `screencap` (liefert Schwarz), sondern über `adb shell input keyevent 120` und
  anschliessendes Ziehen aus `/sdcard/Pictures/Screenshots`.
- **Nie committen:** `android/key.properties`, `android/app/atem-upload-key.jks`.
- **Nie erfinden:** echte Identitätsdaten für Impressum oder Datenschutz. Die fünf
  Platzhalter kann nur der Nutzer füllen.
- **Kein Bezug zu Keyperformance** — nirgends, auch nicht in Store-Texten.

Beginne damit, `CLAUDE.md` und die Abschnitte 6 bis 8 der Produktstrategie zu lesen, und sag
dann in drei Sätzen, was du als Nächstes tun willst.
