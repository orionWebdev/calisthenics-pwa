# ATEM Hybrid — Arbeitsanweisung

Diese Datei in den Repo-Root legen. Sie gilt für jede Aufgabe an dieser App.

## Was hier gebaut wird
ATEM Hybrid — Android-App (Flutter) für hybrides Training. Ästhetik: Dark Cyber-Athlete.
Design-Referenzen: `design_handoff_atem_app/` — Spezifikations-Boards für Modul 1–11, 13–19 und 18b plus zwei interaktive Prototypen.
Board 12 (Kraft-Tab als wischbare Seiten) ist durch Board 13 abgelöst und existiert nicht mehr.
Lesbar ohne Browser: `python3 tool/read_board.py NN`.

## Reihenfolge der Wahrheit
Bei Widersprüchen gilt, von oben nach unten:
1. `tokens/atem_theme.dart` — Farb- und Stilwerte
2. Das Spezifikations-Board des betroffenen Moduls (`design_refs/01`–`19`) — Maße, Zustände, Texte, A11y
3. Der Leitsatz im Kopf des Boards — bei Auslegungsfragen
4. Die interaktiven Prototypen — nur für Bewegung und Timing; ihre Farben sind eine veraltete Fassung

## Vor jeder Aufgabe
1. Öffne das Board des Moduls und lies **Leitsatz**, **Spezifikation**, **A11y**, **Wiederverwendete Bausteine** und **Entscheidungsprotokoll**.
2. Prüfe die Bausteinliste, **bevor** du ein Widget schreibst. Fast alles ist Wiederverwendung.
3. Prüfe das Entscheidungsprotokoll, bevor du etwas „besser" machst. Eine verworfene Idee steht dort mit dem Grund gegen sie.

## Nicht verhandelbar
- Nur die Tokens aus `atem_theme.dart` / README §3. Keine erfundenen Zwischentöne, keine zehnte Muskelfarbe, keine vierte Farbebene.
- `#94A3B8` ist die dunkelste erlaubte Textfarbe.
- Violet `#7A2BDB` ist **nur Fläche, nie Text**.
- Kein Material-Ripple. Gedrückt = `scale 0.97` + Akzent-Glow, 200 ms.
- Jedes Tap-Ziel ≥ 48 dp Trefferfläche.
- Muss bei 200 % Systemschrift auf 320 dp Breite ohne Überlauf funktionieren.
- Farbe nie als einziger Statusträger — immer Wort, Glyph oder Icon daneben.
- Höchstens ein `BackdropFilter` pro scrollendem Screen.
- Bottom-Bar hat genau drei Plätze. Keine neuen Bereiche, keine leeren Slots.
  Ab Modul 11 heißen sie **Kraft · Cardio · Hybrid** (vorher Home · Workouts ·
  Analyse). Der Verlauf gehört in **Kraft**, Regeneration in **Hybrid**.
- Informationstragender Text ≥ 12 sp effektiv, Kontrast ≥ 4,5:1.

## Zustände sind Pflicht
Jeder Screen und jeder Block braucht **default, loading, empty, zu-wenig-Daten und error**. Kein Zustand ist „kommt später". Die Boards zeigen jeden einzelnen als eigenes Artboard.

Zwei Regeln dazu:
- **Auf Auswertungsbildschirmen rendert jeder Block immer** (seit 16.09.2026). Unter seiner Schwelle zeigt er Titel, was er zeigen wird, die Bedingung und den Fortschritt mit Nenner — aber **keinen Wert und keinen Null-Chart**. Baustein: `AtemThresholdBlock`. Er zeigt **drei Dinge und keine vierte**: Namen, den **Umriss** des künftigen Inhalts (`AtemThresholdShape`: Kurve, Balken, Zeilen, Ring — an die Datenform gebunden, keine freie Wahl) und die Bedingung mit Nenner. Kein ⓘ, kein Tap-Ziel, und **statisch**: Ein atmender Umriss sähe aus wie das Ladeskelett und müsste bei reduzierter Bewegung halb eingefroren stehen bleiben. Grund: Nach einem Neubeginn war die Auswertung sonst leer, und niemand sah, was die App kann.
- **Auf allen anderen Bildschirmen rendert ein Block ohne Daten nicht** — der Bildschirm hört einfach früher auf. Keine Platzhalterkarte, kein „Leg los!"-Aufruf (Modul 5).
- **Wo die Daten dünn sind, muss das sichtbar sein** — mit Nenner und Grundlage, nicht mit einer glatt aussehenden Zahl.

## Die Ortszeile — Themen statt Seiten (Board 13, seit 20.09.2026)
Der Kraft-Tab ist **eine durchgehende Seite** mit vier Themen: Trainieren,
Verlauf, Auswertung, Pläne. Kein `PageView`, kein Tab-Kopf.
- Bausteine: `AtemSectionPage` mit `AtemSectionBar` und `AtemSectionSeam` —
  global, Bereichszahl und -ton sind Parameter.
- **Die Zeile zeigt genau ein Wort**: das Thema, in dem man steht. Die anderen
  liegen vollständig in einer Liste, die ein Tipp aufklappt. Nie ellipsieren,
  nie verkleinern, nie durch Symbole ersetzen — daran scheitert jede
  Reiterleiste bei 200 % auf 320 dp.
- Vier Träger, Farbe ist der letzte: Wort · Zähler „2 / 4" · Chevron ·
  Marken. Die Marken sind drei **Formzustände** (erledigt gefüllt, aktuell
  mitwachsend, offen leer), nicht drei Farben.
- **Sie blendet nie aus.** Sie ist die einzige Ortsangabe und zugleich der
  Fortschrittsanzeiger. Deckende Fläche (`surfaceSolid`), kein Blur.
- **Die Zeile ist die Überschrift.** Kein Thema trägt seinen Namen ein zweites
  Mal im Inhalt; Blocküberschriften heissen nach dem Block. Genau **ein
  Rezept**: `labelMicro` in Versalien, optional mit Aktion rechts.
- Zwischen zwei Themen liegt die Fuge, nach dem letzten die Endfuge — Ende
  statt Ankündigung. Sie ist stumm; den Wechsel sagt die Zeile an, gedrosselt
  auf eine Ansage je Wechsel und frühestens 400 ms nach der letzten.
- Ein Thema **scrollt nicht selbst**; Sprungziele kommen aus
  `precedingScrollExtent`, nicht aus `localToGlobal`.
- **Ein Ladegate je Seite**, nicht eines je Thema. Leere Themen bleiben
  stehen: Fehlte beim Neubeginn die halbe Seite, sähe die App kleiner aus,
  als sie ist.
- Die Eintrittskaskade läuft, wenn ein Block 25 % der Viewporthöhe kreuzt —
  nicht beim Bauen. Auf einer Seite, die alles auf einmal baut, wäre sie
  sonst vorbei, bevor man dort ankommt.

## Farbteilung: Ort gegen Handlung (Board 13, seit 20.09.2026)
- **Cyan trägt Handlung** — global reserviert. Textaktionen („Alle 6"), die
  Marke „HIER", Links. Wer Cyan sieht, kann tippen.
- **Der Bereichston trägt den Ort** — im Kraft-Tab Amber `#FFB020`, wie der
  Nav-Punkt der Bottom-Bar. Marken, Fuge, Kicker der Startkarte, Symbolkästen
  der Wege, Sperr-Fortschritt, Rand eines freigeschalteten Blocks. **Amber ist
  nie ein Versprechen auf eine Handlung.**
- Messwerte behalten ihre Fachfarben, der Marken-CTA bleibt der
  Magenta-Verlauf.
- Rangfolge in „Trainieren": Gradient-Rand-Karte (genau eine) = der Weg, den
  die Seite verkauft · Halbkarten = die regelmässigen Alternativen · Zeilen
  mit Chevron = Unterseiten und Seltenes. Nach **Häufigkeit** belegt, nicht
  nach Wichtigkeitsgefühl.

## Bewegung: Licht antwortet, es ruft nicht (Board 18b, seit 23.09.2026)
- **Fünf Verben, je ein Effekt:** Wählen = Bloom + Kern/Häkchen · Schreiben =
  Speicher-Scan · Erscheinen = Lichtkante · Ort = Aurora + Titelglanz ·
  Ablehnen = Flackern + Rücksprung. Ein Effekt nur dort, wo genau dieses Verb
  gerade geschehen ist.
- **Kein Baustein entscheidet selbst, ob er leuchtet** — er fragt
  `AtemReceiptScope` (Stufe Standard · Fokus im Runner · Still bei
  „Animationen reduzieren", Tempo-Dämpfung 700 ms, Kante einmal je Gegenstand
  und Besuch, die jüngste Berührung gewinnt).
- **Nichts leuchtet an Offenem, Fehlendem, Unerledigtem.** Kein stehender
  Schein an Punkten. Dauerschleifen gibt es genau zwei: die Aurora (nur
  Unterseiten; auf Plankarten stehend) und das Ladeskelett.
- **Die Lichtkante läuft bei jedem Aufklappen** (Nutzerentscheidung
  23.09.2026, gegen 18b C6) — auch im Runner bei der Satzhistorie.
- Kurven und Dauern nur aus `AtemMotion` (`settle`, `pop`, `draw`, `travel`,
  `enter`, `exit`, `drift`, `press`).
- Haptik bestätigt die Berührung, nie das Ergebnis: Raste bei Wahl, mittel
  nur beim Satz abhaken, nie beim Speichern oder Ablehnen.

## Text und Erklärungen (seit 17.09.2026)
- **Drei Textstufen:** Weiss für Titel und die Hauptzahl eines Blocks · `#CDD3EA` nur für Sätze, die gelesen werden · `#94A3B8` für Metazeilen, Grundlage und Beschriftungen. Die Hauptzahl trägt den Akzent des Bereichs (Kraft Amber, sonst Cyan) — ein Blickfang je Block, keine Ampelfarben.
- **Erklärungen sind versteckt.** Sichtbar bleiben Titel, Wert, eine kurze Grundlage mit Nenner und — unter der Schwelle — Bedingung und Fortschritt. Was der Block zeigt, wie gerechnet wird, Formeln und Hinweise („Kein Sollverhältnis") stehen hinter dem ⓘ neben dem Titel und klappen im Block auf. Baustein: `AtemExplainHeader`.
- Höchstens **eine** sichtbare Hinweiszeile je Block ausser der Grundlage.

## Umgang mit Zahlen und Aussagen
- Jede Zahl nennt ihre Grundlage („268 Sätze · 14 von 18 Kraft-Einheiten"). Nie einen Anteil ohne Nenner.
- Kein Sollverhältnis, kein Urteil. Die App weiß nicht, wie viel Rücken richtig ist.
- Deltas sind Tatsachen in `#CDD3EA` mit Richtungsglyph — **keine Ampelfarben**. „Mehr" ist nicht „besser".
- Keine Interpolation über Tage ohne Ereignis.

## Schreiben und Löschen (Modul 7 + 8)
- Reversibel (anlegen, bearbeiten): optimistisch schreiben, bei Abweisung zurück ins Formular — nicht in einen Toast.
- Irreversibel (löschen): zwei Stufen. Stufe 1 informiert und zählt die Folgen, Stufe 2 entscheidet. Genau zwei Wege in Stufe 2, kein dritter.
- Kontolöschung: Stufe 2 verlangt getipptes „LÖSCHEN"; Stufe 1 bietet Datenexport als Alternative.
- Jede Snackbar steht 6 s, mit oder ohne Undo (seit 16.09.2026; vorher 30 s mit Undo, 4 s ohne).
- `reps` bleibt Text. `difficulty` ist eine Zahl 1–5, ohne Vorbelegung.
- `userId` ist nie sichtbar und nie eine Formularfehlermeldung.

## Barrierefreiheit
Die A11y-Sektion jedes Boards ist verbindlich, nicht optional. Kernregeln:
- Eine Datenzeile ist **ein** Semantics-Knoten, nicht vier („Last 412, vorher 380, 32 mehr").
- Richtungsglyphen (▲ ▼ —) werden nie vorgelesen — das Wort steht im Label.
- Ein „—" ist nie stumm: „kein Vergleich verfügbar".
- Dekorative Farbpunkte: `excludeSemantics`.
- Ladezustände: `liveRegion: polite`, nie assertive.
- Ein deaktivierter Knopf trägt den Grund im Label („Speichern, nicht möglich, noch 3 Angaben nötig").

## Strings
Jedes Board hat eine Stringtabelle `key | Deutsch | Englisch`. Keys unverändert in die ARB-Dateien übernehmen. Deutsch ist primär. Zählformen brauchen in beiden Sprachen eine Einzahlform. Platzhalter in geschweiften Klammern (`{n}`, `{date}`, `{plan}`).
