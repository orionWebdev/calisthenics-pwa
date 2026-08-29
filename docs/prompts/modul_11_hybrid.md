# Modul 11 — Hybrid: Kraft, Cardio und ihr Verhältnis

*Prompt für Claude Design. Unverändert einfügen.*

---

## Kontext

ATEM Hybrid — Android-App für hybrides Training. Dark Cyber-Athlete.
Das Design-System ist verbindlich, nicht verhandelbar:

```
Canvas #050507 · Surface #0B0B0E · Card #14141D · Border #232334 · Track #16161F
Magenta #F02277 (Marke, CTA) · Deep Rose #C01963 · Cyan #00F2FE (Daten, aktiv)
Lime #00FF87 (Erfolg, Recovery) · Violet #7A2BDB (nur Fläche, NIE Text)
Poppins (UI) + JetBrains Mono (Messwerte, Labels)
Radien: Card 20 · Pill 30 · StatBox 14 · IconBox 10
Kein Material-Ripple — Skalierung 0.97 und Glow, 200 ms
Dunkelste erlaubte Textfarbe: #94A3B8
```

Dies ist **Modul 11**. Die Module 01–10 sind abgenommen und gebaut. Es muss
ihre Bausteine wiederverwenden statt neu zu erfinden:

| Modul | Was daraus zur Verfügung steht |
|---|---|
| 01 | Acht Schriftrollen, Tap-Ziel-Regel, Bewegungskonstanten |
| 02 | Sheet (zwei Höhenmodi), Dialog (drei Fälle, höchstens drei Wege), drei Kartenrezepte, Skelett/Leer/Fehler |
| 03 | Pill mit vier Achsen, Statbox, Fortschrittsbalken, Notice-Slot |
| 05 | Workouts-Tab, Übungskarte mit Kategoriefarbe, Planliste, Weg ins Training |
| 06 | Einheitenliste mit Monatsstreifen und Lücken, Einheitendetail (vier Datenlagen), Formkurve mit Rug-Plot, Vergleichsgrundlage-Kapsel |
| 07 | Formularfelder, Schwierigkeitsauswahl, zweistufiges Löschen, 30-s-Fenster |
| 09 | Perzentil-Karte, Muskelbalance, Folgen-Tabelle, Aussagen mit Nenner |
| 10 | Dashboard: Bereitschaft, Formwert, Zonen |

---

## Der Anlass

Die App heißt Hybrid, behandelt aber nur Kraft. Ausdauer ist reine Lesedaten:
Es gibt keinen Weg, einen Lauf zu erfassen, und keine einzige Auswertung dazu.
40 % des Bestands sind unsichtbar.

**Gezählt im Produktivbestand (Stand 26.08.2026, 136 Einheiten):**

```
Arten             63 Kraft · 51 Ausdauer · 12 Regeneration · 10 Körpergewicht
Ausdauerarten     37 Laufen · 5 Rad · 4 Wandern · 5 sonstiges
Belegte Felder    Dauer 51/51 · Tempo 51/51 · Distanz 44/51
                  RPE 32/51 · ø Puls 4/51 · Maximalpuls 4/51
Regeneration      12 Einheiten, davon 11 ohne jede Angabe außer Datum und Dauer
```

Drei Dinge, die diese Zahlen entscheiden:

1. **Puls existiert praktisch nicht** (4 von 51). Keine Auswertung darf ihn
   voraussetzen. Health Connect kommt später — die Gestaltung muss ihn als
   *Verfeinerung* aufnehmen können, nicht als Grundlage.
2. **Schwimmen und Indoor-Rad kommen im Bestand nicht vor**, sind aber
   gewünscht. Sie müssen gestaltet sein, ohne den Bildschirm zu füllen.
3. **Regeneration ist heute inhaltsleer.** Elf von zwölf Einheiten sagen nur,
   dass es sie gab.

---

## Auftrag

### A — Die Navigation neu schneiden

Die Bottom-Bar hat weiterhin **genau drei Plätze**. Sie heißen künftig:

| Platz | Frage, die der Tab beantwortet | Was hineinwandert |
|---|---|---|
| **Kraft** | Was trainiere ich, und wie entwickelt es sich? | heutiger Workouts-Tab **plus** der komplette Verlauf (Einheitenliste, Einheitendetail, Übungshistorie, Muskelbalance) |
| **Cardio** | Was bin ich gelaufen, und wird es besser? | neu |
| **Hybrid** | Wie steht es um mich, über beides? | heutiger Start-Tab **plus** heutiger Analyse-Tab **plus** Regeneration |

Zu gestalten: die drei Tab-Wurzeln als Artboard, das Zusammenwachsen von
Start und Analyse zu **einem** Bildschirm ohne Doppelung, und der Weg vom
Hybrid-Tab in die beiden Fachbereiche.

**Nicht** zu diskutieren: ob es vier Tabs werden. Es bleiben drei.

### B — Der Cardio-Bereich

**B1 — Die Tab-Wurzel.** Was steht oben, wenn 37 Läufe und 5 Radfahrten im
Bestand sind? Was steht dort bei 3 Einheiten, was bei 0?

**B2 — Eine Ausdauereinheit erfassen.** Das ist der wichtigste Bildschirm des
Moduls, denn ohne ihn wächst nichts. Zwei Wege, beide gestalten:

- **Nacherfassen** (der Regelfall — die Uhr hat schon getrackt): Datum,
  Aktivität, Distanz, Dauer, optional ø Puls, Maximalpuls, RPE, Notiz.
  Tempo wird gerechnet, nie getippt.
- **Live mitlaufen lassen** (Laufband, Indoor-Rad): eine laufende Uhr, Distanz
  von Hand nachgetragen. **Kein GPS** — die App fragt keine Standortberechtigung.

Die Aktivitätsauswahl trägt acht Werte: Laufen, Rad, Indoor-Rad, Schwimmen,
Wandern, Gehen, Rudern, sonstiges. Vier davon kommen im Bestand nie vor —
zeige, wie die Auswahl das verkraftet, ohne alle acht gleich laut zu machen.

**B3 — Die Ausdauer-Auswertung.** Wochenkilometer, Tempoentwicklung je
Aktivität, Verteilung der Distanzen. Wiederverwenden: Formkurve, Monatsstreifen,
Perzentil-Karte aus Modul 06 und 09.

**Die Intensitätskaskade — dreistufig, Grundlage immer sichtbar.** Genau das
Muster der Vergleichsgrundlage-Kapsel aus Modul 06:

| Stufe | Quelle | heute belegt |
|---|---|---|
| 1 | ø Herzfrequenz | 4 von 51 |
| 2 | RPE 1–5 | 32 von 51 |
| 3 | Tempo gegen den eigenen Schnitt derselben Aktivität | 51 von 51 |

Stufe 1 ist **heute leer** und muss trotzdem gestaltet sein — sie füllt sich,
sobald Puls erfasst wird. Gestalte den Zustand „Stufe 1 verfügbar" und den
Zustand „Stufe 3, weil sonst nichts da ist".

### C — Der Hybrid-Bereich

**C1 — Zwei Spuren, ein Verhältnis. Niemals eine Summe.** Kraft misst in
Tonnage, Ausdauer in Minuten und Kilometern. Ein addierter Wert aus beidem
wäre eine Zahl, die niemand prüfen kann. Gesucht ist die Darstellung des
**Verhältnisses** — „diese Woche 65 % Kraft / 35 % Ausdauer" mit Nenner, dazu
die Verschiebung gegen den Vier-Wochen-Schnitt als Tatsache in `#CDD3EA` mit
Richtungsglyph.

**Kein Sollverhältnis. Kein Urteil.** Die App weiß nicht, wie viel Laufen
richtig ist. „Mehr Ausdauer" ist nicht „besser".

**C2 — Regeneration.** Keine eigene Ebene, sondern eine Zeile im Hybrid-Tab:
Regeneration ist keine Leistung, sondern eine Eingangsgröße der Bereitschaft.
Zu gestalten: die Zeile selbst, ein knappes Erfassungsformular (Art — Yoga,
Sauna, Dehnen, Mobility —, Dauer, Notiz), und der Zustand „seit {n} Tagen
keine Regeneration".

**Bereits entschieden und umgesetzt, nicht neu aufrollen:** Eine
Regenerationseinheit **bricht die Untätigkeitsstrafe**, trägt aber **keine
Last**. Die Oberfläche muss das benennen können — „Gestern Regeneration" statt
„Letzte Einheit gestern", weil sonst ein fallender Formwert neben einer
frischen Einheit steht und niemand den Widerspruch auflösen kann.

**C3 — Der leere und der dünne Hybrid-Tab.** Bei nur Kraft und keiner Ausdauer
gibt es kein Verhältnis. Der Block rendert dann nicht — der Bildschirm hört
früher auf (Regel aus Modul 05). Zeige, was stattdessen oben steht.

---

## Verbindliche Randbedingungen

- Nur Tokens aus der obigen Liste. Keine erfundenen Zwischentöne.
- Violet `#7A2BDB` ist nur Fläche, nie Text.
- Informationstragender Text ≥ 12 sp effektiv, Kontrast ≥ 4,5:1.
- Jedes Tap-Ziel ≥ 48 dp Trefferfläche — sichtbar darf es kleiner sein.
- Muss bei **200 % Systemschrift auf 320 dp Breite** ohne Überlauf funktionieren.
- Farbe nie als einziger Statusträger — immer Wort, Glyph oder Icon daneben.
- Höchstens ein `BackdropFilter` pro scrollendem Screen.
- **Jede Zahl nennt ihre Grundlage.** Nie einen Anteil ohne Nenner.
- **Keine Interpolation über Tage ohne Ereignis.** Die Lücke ist der Normalfall.
- Deltas sind Tatsachen in `#CDD3EA` mit Richtungsglyph — keine Ampelfarben.
- Zu jedem Bildschirm und jedem Block: **default, loading, empty,
  zu-wenig-Daten, error.** Kein Zustand ist „kommt später".
- Ein Block ohne Daten rendert nicht. Keine Platzhalterkarte, kein „Leg los!".

## A11y-Regeln, die im Board stehen müssen

- Eine Datenzeile ist **ein** Semantics-Knoten, nicht vier.
- Richtungsglyphen (▲ ▼ —) werden nie vorgelesen — das Wort steht im Label.
- Ein „—" ist nie stumm: „kein Vergleich verfügbar".
- Ladezustände `liveRegion: polite`, nie assertive.
- Ein deaktivierter Knopf trägt den Grund im Label.

---

## Liefergegenstände

1. **Artboards je Zustand** — für jeden Bildschirm aus A, B und C.
2. **Spezifikationstabelle** — Varianten, Maße, verwendete Tokens.
3. **Stringtabelle** `key | Deutsch | Englisch` für jeden sichtbaren Text.
   Deutsch ist primär. Zählformen brauchen in beiden Sprachen eine Einzahlform.
   Platzhalter in geschweiften Klammern.
4. **A11y-Notizen** — Semantics-Label, Rolle und Zustand je interaktivem Element.
5. **Liste der wiederverwendeten Bausteine** aus Modul 01–10, namentlich.
6. **Entscheidungsprotokoll** — jede verworfene Alternative mit dem Grund
   gegen sie. Besonders: warum keine gemeinsame Lastwährung.
