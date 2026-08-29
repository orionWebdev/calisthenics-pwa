# Anleitungsprompt — Modul 11 (Hybrid & Cardio)

Diesen Text als erste Nachricht an Claude Code geben. Er setzt voraus, dass `design_handoff_atem_app/` im Repo liegt und `CLAUDE.md` im Root.

---

## Prompt (kopieren)

```
Du baust Modul 11 der Flutter-App ATEM Hybrid.

KONTEXT LESEN, BEVOR DU CODE SCHREIBST — in dieser Reihenfolge:
1. CLAUDE.md im Repo-Root (Arbeitsanweisung, nicht verhandelbare Regeln)
2. design_handoff_atem_app/README.md, Abschnitte 3 (Design-System), 4 (Informationsarchitektur), 9 (HTML→Flutter)
3. design_handoff_atem_app/design_refs/11_Hybrid_Cardio.dc.html — das verbindliche Spezifikations-Board.
   Öffne es im Browser (support.js liegt daneben). Lies vollständig: Leitsatz, A, B1–B4, C1–C3, D,
   F Spezifikation, G Strings, H A11y, I Wiederverwendung, J Entscheidungsprotokoll, K Offene Fragen.
4. Die Boards 05, 06, 07, 09, 10 nur dort, wo Sektion I („Wiederverwendete Bausteine") sie nennt.

WAS MODUL 11 IST
Die App heißt Hybrid, kann aber nur Kraft. 51 Ausdauer- und 12 Regenerationseinheiten liegen im
Bestand — ohne Erfassungsweg und ohne eine einzige Auswertung. Modul 11 schneidet die Navigation
neu (Kraft · Cardio · Hybrid), baut den Cardio-Bereich samt Erfassung und stellt Kraft und Ausdauer
als Verhältnis nebeneinander.

LEITSATZ (entscheidet jede Auslegungsfrage)
Hybrid heißt nicht, Kraft und Ausdauer zu einer Zahl zu verrechnen, sondern beide Spuren einzeln
messbar zu halten und nur ihr Verhältnis zu zeigen.

REIHENFOLGE DER ARBEIT — ein Commit je Schritt, nach jedem Schritt anhalten und zeigen:
S1  Navigation umschneiden: drei Tab-Wurzeln Kraft / Cardio / Hybrid, drei getrennte Navigator-Stacks.
    Kraft und Cardio bekommen je einen Segment-Umschalter (Trainieren|Verlauf, Einheiten|Auswertung).
    Bestehende Screens umhängen, nicht neu bauen. Board-Sektion A.
S2  Datenmodell + Repository für CardioSession und RecoverySession (Felder siehe unten), Migration
    des Bestands, Tempo als berechneter Getter — nie ein persistiertes Feld.
S3  Erfassung nacherfassen (Board B2/1) inklusive Aktivitätsauswahl-Sheet (B2/2). Ohne diesen Screen
    wächst der Bestand nicht — er ist der wichtigste des Moduls.
S4  Live-Uhr (B2/3): laufende Uhr, Distanz von Hand, kein GPS und keine Standortberechtigung.
    Persistent gegen Prozesskill: Startzeitpunkt + Pausenspannen speichern, Anzeige daraus rechnen.
S5  Cardio-Wurzel mit allen Zuständen (B1: default, dünn, leer, loading, error).
S6  Ausdauer-Auswertung (B3) — Wochenstreifen, Tempokurve, Distanzverteilung, Perzentil.
    Wiederverwenden, nicht neu erfinden: Monatsstreifen und Formkurve aus 06, Perzentil-Karte aus 09.
S7  Intensitätskaskade (B4) als eine Funktion + ein Widget. Dreistufig, geführte Stufe sichtbar.
S8  Hybrid-Tab: Verhältnis (C1), Regenerationszeile + Sheet (C2), dünne und leere Fassung (C3).
S9  Strings DE/EN aus Board-Sektion G in die ARB-Dateien, Keys unverändert. Danach A11y-Durchgang
    nach Sektion H und ein Testlauf bei 200 % Systemschrift auf 320 dp Breite.

DATENMODELL (nur diese Felder, keine Vorratsfelder)
CardioSession: id, date, activity (run|bike|bikeIndoor|swim|hike|walk|row|other), distanceKm?,
               durationMin, avgHr?, maxHr?, rpe? (1–5), note?
               → paceOrSpeed ist ein berechneter Getter. min/km bei run|walk|hike|swim,
                 km/h bei bike|bikeIndoor|row. Ohne Distanz: null, Anzeige "—".
RecoverySession: id, date, kind (yoga|sauna|stretch|mobility), durationMin, note?
               → bricht die Untätigkeitsstrafe, trägt keine Last. Der Formwert steigt davon nicht.

HARTE REGELN FÜR DIESES MODUL (Verstoß = Rückbau)
- Keine gemeinsame Lastwährung. Kein Hybrid-Score, keine Summe aus Tonnage und Kilometern.
  Das Verhältnis rechnet über Trainingsminuten, mit sichtbarem Nenner und der Fachgröße je Spur.
- Kein Sollverhältnis, kein Urteil. "Mehr Ausdauer" ist nicht "besser".
- Puls ist nie Voraussetzung (4 von 51 Einheiten). Stufe 1 der Kaskade wird gebaut, führt aber nur
  bei gemessenem Ø- UND Maximalpuls. Keine Altersformel (220 minus Alter) — nirgends.
- Kein GPS, kein Hintergrund-Standortdienst, keine Standortberechtigung im Manifest.
- Tempo ist Ausgabe, nie Eingabe. Distanz und Dauer sind die Wahrheit.
- Es bleiben genau drei Tabs. Kein FAB in der Bottom-Bar.
- Ein Block ohne Daten rendert nicht — der Bildschirm hört früher auf. Keine Platzhalterkarte.
- Jede Zahl nennt ihre Grundlage. Deltas in #CDD3EA mit Richtungsglyph, keine Ampelfarben.
- Leere Woche ist ein 2-dp-Balken in #232334, kein Nullbalken. Keine Interpolation.
- Violet #7A2BDB nur als Fläche (Ausdauer-Segment), nie als Text.
- Höchstens ein BackdropFilter im scrollenden Bereich je Screen — im Hybrid-Tab ist er in der
  Bereitschaftskarte schon vergeben.

BEVOR DU ETWAS "BESSER" MACHST
Lies Board-Sektion J (14 verworfene Alternativen mit Grund). Hybrid-Score, vierter Tab, GPS-Tracking,
Sollverhältnis 80/20, Tempo als Eingabefeld, RPE in Prozent, FAB in der Bar: alle geprüft und
verworfen. Wenn du eine dieser Ideen vorschlagen willst, nenne zuerst den Grund im Protokoll und
warum er nicht mehr gilt.

WENN ETWAS FEHLT
Board-Sektion K nennt drei offene Punkte mit dokumentierter Annahme — baue mit der Annahme weiter
und frag nicht nach. Fehlt eine Angabe, die dort nicht steht: frag, bevor du erfindest.

FERTIG HEISST
Alle Zustände aus der Zustandsmatrix (Board C3/3) gebaut, Strings in beiden Sprachen, Semantics je
Sektion H, sauber bei 200 % Schrift auf 320 dp, keine neue Farbe und kein neuer Radius im Diff.
```

---

## Zusatzprompts für einzelne Schritte

**Nur die Navigation (S1):**
```
Setze ausschließlich Schritt S1 aus dem Modul-11-Prompt um: Bottom-Bar auf Kraft / Cardio / Hybrid,
drei getrennte Navigator-Stacks, Segment-Umschalter in Kraft und Cardio, bestehende Screens umhängen.
Cardio-Wurzel zunächst als Leerzustand aus Board B1/2. Kein neuer Screen, kein neues Widget außer
dem Segment-Umschalter (Pill-Baustein aus Modul 03 wiederverwenden). Board-Sektion A ist verbindlich,
inklusive der drei Wege in Sektion A unten (Hybrid → Kraft, Hybrid → Cardio, Systemzurück).
```

**Nur die Erfassung (S3+S4):**
```
Setze S3 und S4 aus dem Modul-11-Prompt um. Ein Formular für beide Wege: die Live-Uhr endet in
demselben vorbefüllten Formular. Feldrezepte, Fokusring, Fehlertexte und das 30-Sekunden-Undo-Fenster
unverändert aus Modul 07 übernehmen. RPE-Auswahl ist die Schwierigkeitsauswahl aus 07 mit anderer
Beschriftung. Aktivitätsauswahl: belegte Aktivitäten als 48-dp-Zeilen mit Zählung, die vier
unbelegten als Kapseln unter "Weitere" — Sortierung nach eigener Häufigkeit, nicht alphabetisch.
```

**Nur die Intensitätskaskade (S7):**
```
Setze S7 aus dem Modul-11-Prompt um: eine Funktion, die aus einer CardioSession die geführte Stufe
bestimmt (Board B4, Karte C: vier Regeln in dieser Reihenfolge), und ein Widget, das sie darstellt.
Genau eine Stufe urteilt, die anderen stehen als Zahl ohne Bewertung darunter; nicht belegte Stufen
zeigen "—" mit Namen und werden als "nicht erfasst" vorgelesen. Die geführte Stufe steht in der
Kapsel über den Werten, nach dem Muster der Vergleichsgrundlage-Kapsel aus Modul 06.
```

**Review eines fertigen Screens:**
```
Prüfe den gebauten Screen gegen design_refs/11_Hybrid_Cardio.dc.html: Maße und Tokens gegen Sektion F,
Texte und Keys gegen G, Semantics gegen H, Zustände gegen die Matrix in C3/3. Liste Abweichungen als
Tabelle (Stelle | erwartet | gebaut) und schlage Korrekturen vor, bevor du etwas änderst.
```
