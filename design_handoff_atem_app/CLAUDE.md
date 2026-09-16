# ATEM Hybrid — Arbeitsanweisung

Diese Datei in den Repo-Root legen. Sie gilt für jede Aufgabe an dieser App.

## Was hier gebaut wird
ATEM Hybrid — Android-App (Flutter) für hybrides Training. Ästhetik: Dark Cyber-Athlete.
Design-Referenzen: `design_handoff_atem_app/` — Spezifikations-Boards für Modul 1–11 plus zwei interaktive Prototypen.
Für Modul 11 liegt ein fertiger Anleitungsprompt bereit: `design_handoff_atem_app/PROMPT_MODUL_11.md`.

## Reihenfolge der Wahrheit
Bei Widersprüchen gilt, von oben nach unten:
1. `tokens/atem_theme.dart` — Farb- und Stilwerte
2. Das Spezifikations-Board des betroffenen Moduls (`design_refs/01`–`11`) — Maße, Zustände, Texte, A11y
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
- Bottom-Bar hat genau drei Plätze: **Kraft, Cardio, Hybrid** (Modul 11; der frühere Schnitt Home/Workouts/Analyse ist überholt). Keine neuen Bereiche, keine leeren Slots, kein FAB in der Bar.
- Informationstragender Text ≥ 12 sp effektiv, Kontrast ≥ 4,5:1.

## Zustände sind Pflicht
Jeder Screen und jeder Block braucht **default, loading, empty, zu-wenig-Daten und error**. Kein Zustand ist „kommt später". Die Boards zeigen jeden einzelnen als eigenes Artboard.

Zwei Regeln dazu:
- **Auf Auswertungsbildschirmen rendert jeder Block immer** (seit 16.09.2026). Unter seiner Schwelle zeigt er Titel, was er zeigen wird, die Bedingung und den Fortschritt mit Nenner — aber **keinen Wert und keinen Null-Chart**. Baustein: `AtemThresholdBlock`. Grund: Nach einem Neubeginn war die Auswertung sonst leer, und niemand sah, was die App kann.
- **Auf allen anderen Bildschirmen rendert ein Block ohne Daten nicht** — der Bildschirm hört einfach früher auf. Keine Platzhalterkarte, kein „Leg los!"-Aufruf (Modul 5).
- **Wo die Daten dünn sind, muss das sichtbar sein** — mit Nenner und Grundlage, nicht mit einer glatt aussehenden Zahl.

## Umgang mit Zahlen und Aussagen
- Jede Zahl nennt ihre Grundlage („268 Sätze · 14 von 18 Kraft-Einheiten"). Nie einen Anteil ohne Nenner.
- Kein Sollverhältnis, kein Urteil. Die App weiß nicht, wie viel Rücken richtig ist.
- Deltas sind Tatsachen in `#CDD3EA` mit Richtungsglyph — **keine Ampelfarben**. „Mehr" ist nicht „besser".
- Keine Interpolation über Tage ohne Ereignis.

## Kraft und Ausdauer (Modul 11)
- **Keine gemeinsame Lastwährung.** Kein Hybrid-Score, keine Summe aus Tonnage und Kilometern. Das Verhältnis rechnet über Trainingsminuten, mit Nenner und der Fachgröße je Spur darunter.
- **Puls ist nie Voraussetzung** (4 von 51 Einheiten). Intensität kommt aus der dreistufigen Kaskade, die geführte Stufe steht sichtbar dabei. Keine Altersformel für den Maximalpuls.
- **Kein GPS**, kein Hintergrund-Standortdienst, keine Standortberechtigung im Manifest. Live-Erfassung zählt Zeit, die Distanz kommt von Hand.
- **Tempo ist Ausgabe, nie Eingabe.** Distanz und Dauer sind die Wahrheit; Tempo ist ein berechneter Getter.
- **Regeneration trägt keine Last.** Sie bricht die Untätigkeitsstrafe. Die Oberfläche nennt die Art der letzten Einheit („Gestern Regeneration"), nicht nur ihr Datum.
- Eine leere Woche ist ein 2-dp-Balken in `#232334`, kein Nullbalken — „gemessen: 0" ist etwas anderes als „nichts gemessen".

## Schreiben und Löschen (Modul 7 + 8)
- Reversibel (anlegen, bearbeiten): optimistisch schreiben, bei Abweisung zurück ins Formular — nicht in einen Toast.
- Irreversibel (löschen): zwei Stufen. Stufe 1 informiert und zählt die Folgen, Stufe 2 entscheidet. Genau zwei Wege in Stufe 2, kein dritter.
- Kontolöschung: Stufe 2 verlangt getipptes „LÖSCHEN"; Stufe 1 bietet Datenexport als Alternative.
- Undo-Fenster 30 s, ohne Undo Snackbar 4 s.
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
