# Handoff: ATEM Hybrid — vollständige App (Modul 1–11)

**Zielplattform:** Android (Flutter). Sekundär iOS.
**Sprache im Produkt:** Deutsch primär, Englisch vollständig übersetzt (Stringtabellen liegen je Modul bei).
**Stand:** 29.08.2026 · Datenerhebung am Produktivbestand 26.08.2026.

---

## 1. Was in diesem Bundle liegt

```
design_handoff_atem_app/
├── README.md                  ← dieses Dokument (Einstieg, System, Reihenfolge)
├── CLAUDE.md                  ← Arbeitsanweisung für Claude Code (in den Repo-Root kopieren)
├── MODULE.md                  ← Modul-für-Modul-Inhaltsverzeichnis mit Sektions-Ankern
├── PROMPT_MODUL_11.md         ← fertiger Anleitungsprompt für Modul 11 (kopieren und abschicken)
├── design_refs/               ← die Design-Referenzen selbst (im Browser öffnen)
│   ├── 01_Fundament_Typo_Interaction.dc.html
│   ├── 02_Flaechen_Zustaende.dc.html
│   ├── 03_Status_Progress.dc.html
│   ├── 04_Anmeldung_Onboarding.dc.html
│   ├── 05_Workouts.dc.html
│   ├── 06_Verlauf.dc.html
│   ├── 07_Daten_Eingaben.dc.html
│   ├── 08_Einstellungen_Profil.dc.html
│   ├── 09_Aussagekraft.dc.html
│   ├── 10_Dashboard.dc.html
│   ├── 11_Hybrid_Cardio.dc.html
│   ├── Prototyp_Dashboard.dc.html          ← interaktiv, iOS-Rahmen
│   ├── Prototyp_Workout_Runner.dc.html     ← interaktiv, iOS-Rahmen
│   ├── support.js                          ← Laufzeit der .dc.html-Dateien, NICHT portieren
│   └── ios-frame.jsx                       ← nur Gerätrahmen der Prototypen, NICHT portieren
└── tokens/
    ├── atem_theme.dart                     ← Farben, Gradients, Glows, TextStyles — direkt nutzbar
    └── main.dart.reference                 ← bestehender Flutter-Einstieg als Referenz
```

**So öffnest du die Referenzen:** jede `.dc.html` direkt im Browser (Doppelklick). `support.js` muss im selben Ordner liegen — sie liegt bei. Kein Server, kein Build nötig.

---

## 2. Wie diese Dateien zu lesen sind

Die Dateien in `design_refs/` sind **Design-Referenzen in HTML** — kein Produktionscode und nicht zum Kopieren gedacht. Zwei verschiedene Sorten:

| Sorte | Dateien | Was sie ist |
|---|---|---|
| **Spezifikations-Board** | `01`–`11` | Ein Blatt pro Modul: Artboards aller Zustände nebeneinander, dazu Spezifikationstabelle, Stringtabelle DE/EN, A11y-Notizen, Bausteinliste, Entscheidungsprotokoll. **Das ist die verbindliche Quelle.** |
| **Interaktiver Prototyp** | `Prototyp_*` | Klickbar, mit Animationen und Timern, im iOS-Rahmen. Zeigt Bewegung und Timing, das ein statisches Board nicht zeigt. Farben dort sind eine **frühere Fassung** — bei Konflikt gilt immer das Board bzw. `atem_theme.dart`. |

**Fidelity: high-fidelity.** Farben, Typografie, Abstände, Radien, Zustände und Texte sind final. Pixelgenau nachbauen, mit Flutter-Bordmitteln und den bestehenden Patterns im Repo.

Jedes Spezifikations-Board hat denselben Aufbau. Die Sektionsbuchstaben stehen als Überschrift im Board:

- **Kopf + Leitsatz** — der eine Satz, aus dem die Modulregeln folgen. Bei Zweifeln entscheidet dieser Satz.
- **A1, A2, A3 …** — Artboards. Jede Karte ist ein Zustand (default, loading, empty, zu-wenig-Daten, error, pressed, disabled). Unter jedem Artboard steht ein Absatz, der die Regel dahinter erklärt.
- **B / C / D** — Regelwerke, Kaskaden, Matrizen, Datenlage.
- **E oder F — Spezifikation:** Varianten, Maße in dp/sp, verwendete Tokens. Hier stehen die Zahlen.
- **F oder G — Stringtabelle:** `key | Deutsch | Englisch`. Übernimm die Keys unverändert in die ARB-Dateien.
- **G oder H — A11y:** Semantics-Label, Rolle, Zustand je interaktivem Element. Verbindlich, nicht optional.
- **H oder I — Wiederverwendete Bausteine:** woher ein Element kommt und was daran geändert wurde. **Lies das zuerst, bevor du ein Widget neu schreibst.**
- **I / J — Entscheidungsprotokoll:** was verworfen wurde und warum. Wenn dir eine „bessere" Lösung einfällt, steht sie mit hoher Wahrscheinlichkeit hier — mitsamt dem Grund gegen sie.
- **K — Offene Fragen** (Modul 8, 9, 11): Punkte mit dokumentierter Annahme. Baubar, aber vor Release zu bestätigen.

---

## 3. Design-System (verbindlich)

Alle Werte auch in `tokens/atem_theme.dart`. Bei Abweichung zwischen README und Dart gilt Dart.

### Flächen
| Token | Hex | Verwendung |
|---|---|---|
| Canvas | `#050507` | Bildschirmhintergrund |
| Surface | `#0B0B0E` | Sektionsflächen, Sheets |
| Card | `#14141D` | Karten, Zeilen, Felder |
| Border | `#232334` | jeder 1-px-Rand |
| Track | `#16161F` | Balken-, Slider-, Skelett-Hintergrund |

### Akzente
| Token | Hex | Verwendung |
|---|---|---|
| Magenta | `#F02277` | Marke, primäre CTA, destruktiv, Bestwert |
| Deep Rose | `#C01963` | Magenta gedrückt / Gradient-Ende |
| Cyan | `#00F2FE` | Daten, aktiv, Fokus, Links |
| Lime | `#00FF87` | Erfolg, Recovery, „bleibt erhalten" |
| Violet | `#7A2BDB` | **nur Fläche, NIE Text** |

### Text
| Rolle | Hex | Kontrast auf Canvas |
|---|---|---|
| Primär | `#FFFFFF` | — |
| Sekundär | `#CDD3EA` | ≥ 4,5:1 |
| Tertiär / Label | `#94A3B8` | ≥ 4,5:1 |

`#94A3B8` ist die **dunkelste erlaubte Textfarbe**. Alles darunter ist ein Fehler, kein Stilmittel.

### Muskelfarben (9, fest)
`Brust #f472b6` · `Rücken #60a5fa` · `Schultern #a78bfa` · `Arme #f59e0b` · `Bizeps #fbbf24` · `Trizeps #e879f9` · `Core #34d399` · `Beine #fb923c` · `Waden #2dd4bf`

Alle neun sind fließtextsicher auf Canvas — schlechtester Kontrast 6,33:1. Sie dürfen als Textfarbe verwendet werden. **Keine zehnte Farbe, keine vierte Farbebene.**

### Typografie
- **Poppins** — alle UI-Texte, Titel, Fließtext. Gewichte 400/500/600/700.
- **JetBrains Mono** — Messwerte, Labels, Datumsangaben, Keys. Gewichte 400/500/600/700, letter-spacing 0.06–0.16 em bei Labels.
- Informationstragender Text **≥ 12 sp effektiv**. Mono-Labels dürfen kleiner sein, wenn sie eine Beschriftung neben einem größeren Wert sind — nie, wenn sie die Aussage tragen. Die genaue Skala mit acht benannten Rollen steht in Modul 1.

### Radien
Card **20** · Pill **30** · StatBox **14** · IconBox **10** · Sheet **24 oben**

### Interaktion
- **Kein Material-Ripple.** Gedrückt = `scale 0.97` + Glow im Akzent, 200 ms.
- `InkWell`/`InkResponse` deshalb nur mit `splashColor: transparent`, oder direkt `GestureDetector` + `AnimatedScale`.
- Jedes Tap-Ziel **≥ 48 dp Trefferfläche**, auch wenn das sichtbare Element kleiner ist.
- **Höchstens ein `BackdropFilter` im scrollenden Bereich** pro Screen. Blur ist teuer und der Screen scrollt.

### Harte Randbedingungen
1. Nur Tokens aus dieser Liste. Keine erfundenen Zwischentöne.
2. Kontrast ≥ 4,5:1 für jeden informationstragenden Text.
3. Muss bei **200 % Systemschrift** auf **320 dp Breite** ohne Überlauf funktionieren. Die Boards zeigen bei kritischen Zeilen das 200-%-Verhalten explizit.
4. **Farbe nie als einziger Statusträger.** Immer Wort, Glyph oder Icon daneben.
5. **Jeden Zustand bauen:** default, loading, empty, zu-wenig-Daten, error. Kein Zustand ist „kommt später".

---

## 4. Informationsarchitektur

**Bottom-Bar: genau drei Plätze.** Seit Modul 11: **Kraft · Cardio · Hybrid**. Alle drei gefüllt — kein „Kommt noch". Der frühere Schnitt (Home · Workouts · Analyse) ist damit überholt; die Screens selbst bleiben, sie hängen nur anders.

```
Kraft      → Modul 5 + 11   Segment „Trainieren"  → Pläne, Übungen, Weg ins Training
                           Segment „Verlauf"     → Modul 6 (Einheitenliste, Einheitendetail,
                                                   Übungshistorie, Muskelbalance — Modul 9)
                           ├─ Übungsdetail        → Modul 5 + 7 + 9
                           ├─ Plan anlegen/edit   → Modul 7
                           └─ Workout Runner      → Prototyp Workout Runner

Cardio     → Modul 11      Segment „Einheiten"   → Wochenkilometer + Einheitenliste
                           Segment „Auswertung"  → Wochenstreifen, Tempokurve, Verteilung, Perzentil
                           ├─ Ausdauer erfassen   → nacherfassen (Regelfall) und Live-Uhr (kein GPS)
                           └─ Einheitendetail     → Modul 6-Detail + Intensitätskasten

Hybrid     → Modul 10 + 11 Bereitschaft (heute) · Verhältnis (Woche) · Formwert und Zonen (4 Wochen)
                           └─ Regenerationszeile  → Sheet mit vier Feldern (Modul 11)

Einstellungen & Profil    → Modul 8   — KEIN Bar-Slot, erreichbar über das
                                        Profilbild im Hybrid-Header
Anmeldung & Onboarding    → Modul 4   — vor allem anderen, geschlossene Beta
```

Jeder Tab hat seinen **eigenen Navigator-Stack**. Die drei Stacks werden nie zusammengelegt; Systemzurück wechselt nach einem Tabsprung zurück in den Hybrid-Tab an dieselbe Scrollposition.

---

## 5. Empfohlene Umsetzungsreihenfolge

Die Module bauen aufeinander auf. In dieser Reihenfolge entsteht kein Nacharbeit-Berg:

1. **Modul 1 — Fundament.** Typenskala als benannte `TextStyle`-Rollen, Tap-Ziel-Helper, Motion-Konstanten. Danach kommt keine freie Schriftgröße mehr vor.
2. **Modul 2 — Flächen & Zustände.** Sheet mit zwei Höhenmodi, Dialog-Anatomie (max. drei Wege), drei Kartenrezepte. Diese Widgets tragen später jedes Formular und jeden Löschvorgang.
3. **Modul 3 — Statusträger & Fortschritt.** Ein Pill-Baustein mit vier Achsen ersetzt sechs Rezepte; eine Fortschritts-Implementierung ersetzt vier.
4. **Modul 4 — Anmeldung & Onboarding.** Fünf Zustände ohne Layout-Sprung. Danach ist die App betretbar.
5. **Modul 5 — Workouts.** Der Tab plus Übungs- und Plan-Detail. Hier entsteht die Regel „ein Block rendert nur mit Daten, der Bildschirm hört früher auf" — sie gilt ab hier überall.
6. **Modul 6 — Verlauf.** Liste, Detail, Formkurve. Lücken sind der Normalfall, nicht der Fehlerfall.
7. **Modul 7 — Daten ändern.** Alles Schreibende: anlegen, bearbeiten, löschen, Undo, Zwei-Stufen-Bestätigung.
8. **Modul 8 — Einstellungen & Profil.** Acht Einstellungen; Körpergewicht rechnet rückwirkend, Kontolöschung ist zweistufig mit getipptem Wort.
9. **Modul 9 — Aussagekraft.** Drei Blöcke in bereits gebaute Screens: Vergleich (Einheitendetail), Muskelbalance (Workouts), Übungsverlauf (Übungsdetail). Braucht 5, 6 und 7 fertig.
10. **Modul 10 / Dashboard.** Der Home-Screen. Bewusst zuletzt: er zitiert Bausteine aus allen anderen.
11. **Modul 11 — Hybrid & Cardio.** Navigation neu schneiden, Cardio-Bereich samt Erfassung bauen, Verhältnis und Regeneration im Hybrid-Tab. Braucht 5, 6, 7, 9 und 10 fertig — es hängt sie um und zitiert ihre Bausteine. Anleitungsprompt: `PROMPT_MODUL_11.md`.

---

## 6. Datenlage — worauf der Entwurf sich stützt

Erhoben am 26.08.2026 am Produktivbestand. Diese Zahlen sind der Grund für fast jede Schwelle im Entwurf:

| Zahl | Bedeutung | Folge im Design |
|---|---|---|
| **136 Einheiten** | 63 Kraft · 10 Körpergewicht · 55 Cardio · 8 Regeneration | Regeneration ist zu selten für Vergleiche und bekommt keinen |
| **47 von 63** | Krafteinheiten, die überhaupt Übungen tragen | Die Muskelbalance rechnet über 47, nicht 136 — Nenner steht sichtbar da |
| **52 von 136** | Einheiten mit Plan-ID | Der stärkste Vergleich greift nur bei einem Drittel; die gröberen Stufen sind der Normalfall |
| **154 Übungen** | 84 kuratiert (meist nie ausgeführt) · 70 eigene | Der Verlaufsblock muss ausfallen können, ohne eine Lücke zu lassen |
| **10 Pläne / 60 Einträge** | ~6 Einträge je Plan | Genug Überdeckung für die Übungs-Vergleichsstufe |
| **110 Einheiten an 87 Tagen** | Lücken bis 74 Tage | Lücken sind Normalfall; „seit 50 Tagen nichts" ist ein zu gestaltender Zustand |
| **+250 Einheiten / Jahr** | Wachstum | Alle Schwellen werden von allein überschritten — jeder Zwischenzustand ist temporär, aber gestaltet |

Aus Modul 11 kommen die Zahlen der zweiten Hälfte des Bestands dazu — sie tragen fast jede Schwelle im Cardio-Bereich:

| Zahl | Bedeutung | Folge im Design |
|---|---|---|
| **51 Ausdauereinheiten** | 37 Laufen · 5 Rad · 4 Wandern · 5 sonstiges | Nur Laufen erreicht die Kurvenschwelle (8 je Aktivität); alle anderen zeigen Schnitt und Spanne |
| **4 von 51 mit Ø Puls** | Puls existiert praktisch nicht | Keine Auswertung setzt Puls voraus. Stufe 1 der Kaskade ist gebaut, aber heute leer — Verfeinerung, nicht Grundlage |
| **32 von 51 mit RPE** | eigene Einschätzung | Stufe 2 der Kaskade, der häufigste bewusst gesetzte Wert |
| **51 von 51 mit Dauer/Tempo** | trägt immer | Stufe 3: Tempo gegen den eigenen Schnitt derselben Aktivität — der Rückfall, der nie ausfällt |
| **44 von 51 mit Distanz** | 7 ohne | Tempo bleibt dort „—", die Einheit zählt trotzdem in Minuten. Nenner der Verteilung ist 44, nicht 51 |
| **11 von 12 Regeneration ohne Angabe** | nur Datum und Dauer | Vier Felder im Formular, eine Zeile im Tab — mehr wäre ein Formular für Daten, die niemand einträgt |
| **4 von 8 Aktivitäten unbenutzt** | Schwimmen, Indoor-Rad, Rudern, Gehen | Gestaltet, aber nicht gleich laut: Kapseln unter „Weitere", nicht Zeilen |

---

## 7. Datenmodell (aus den Modulen 5–9)

Kein ORM-Schema, aber die Felder, auf die der Entwurf sich verlässt:

- **Einheit (Session):** `id`, `date`, `type` (Kraft | Körpergewicht | Cardio | Regeneration), `durationMin`, `load`, `volumeKg`, `sets`, `acwr`, `planId?`, `entries[]`
- **Übungseintrag (SessionEntry):** `exerciseId`, `sets[]` (`weightKg?`, `reps` **als Text**), `restSec?`
- **Übung (Exercise):** `id`, `name`, `equipment`, `difficulty` (**Zahl 1–5**, Pflicht beim Anlegen), `muscleGroups[]` (1–3 der neun), `curated` (bool), `instructions?`, `cues[]?`, `commonMistakes[]?`
- **Plan:** `id`, `name` (einziges Pflichtfeld), `entries[]` (`exerciseId`, Zielwerte `sets`/`reps`, `restSec`, Reihenfolge)
- **Profil:** `bodyWeightKg`, `restDefaultSec`, `unitSystem`, `language`

Aus Modul 11 dazu:

- **Ausdauereinheit (CardioSession):** `id`, `date`, `activity` (run | bike | bikeIndoor | swim | hike | walk | row | other), `distanceKm?`, `durationMin`, `avgHr?`, `maxHr?`, `rpe?` (1–5), `note?`
- **Regenerationseinheit (RecoverySession):** `id`, `date`, `kind` (yoga | sauna | stretch | mobility), `durationMin`, `note?`

Drei Festlegungen dazu:
- **Tempo ist kein Feld.** Berechneter Getter aus `distanceKm` und `durationMin` — min/km bei Laufen, Gehen, Wandern, Schwimmen; km/h bei Rad, Indoor-Rad, Rudern. Ohne Distanz `null`, Anzeige „—".
- **Regeneration trägt keine Last.** Sie bricht die Untätigkeitsstrafe der Bereitschaft, erhöht aber keinen Formwert. Die Oberfläche benennt die Art der letzten Einheit („Gestern Regeneration"), damit ein fallender Formwert neben einer frischen Einheit erklärt ist.
- **Kein gemeinsames Lastfeld.** Es gibt keinen Hybrid-Score und keine Summe aus Tonnage und Kilometern. Das Verhältnis rechnet über Trainingsminuten mit sichtbarem Nenner (Modul 11, Sektion J, erster Eintrag).

Zwei Fallen, die im Entwurf beantwortet sind:
- **`reps` ist eine Zeichenkette.** Im Bestand stehen „8-12", „max" und „10" nebeneinander. Kein Zahlen-Stepper — Textfeld, nur Längenvalidierung, unverändert speichern (Modul 7, Entscheidung 07).
- **`difficulty` ist eine Zahl.** Die Datenbank verlangt sie beim Anlegen; alte Datensätze tragen teils Wörter. Segmentauswahl mit Zahl **und** Wort, kein Vorbelegen (Modul 7, Entscheidungen 03–05).

---

## 8. Was NICHT portiert wird

- `support.js` — Laufzeit der Referenzdateien. Nur damit die HTML im Browser rendert.
- `ios-frame.jsx` — Gerätrahmen der Prototypen. Nicht Teil der App.
- Die HTML-/CSS-Struktur der Boards selbst — Boards sind Dokumentation, keine Screens.
- Farben aus `Prototyp_*` — frühere Fassung (`#030308`, `#FF007A`, `#9D4EDD` …). Bei Konflikt gilt `atem_theme.dart`.

## 9. HTML → Flutter, die wiederkehrenden Übersetzungen

| HTML/CSS im Board | Flutter |
|---|---|
| `backdrop-filter: blur(n)` | `BackdropFilter(filter: ImageFilter.blur(sigmaX: n/2, sigmaY: n/2))` — max. 1 pro scrollendem Screen |
| SVG-Polyline / Arc / Chart | `CustomPainter` |
| `@keyframes` (Puls, Flackern, Skelett) | `AnimationController` + `AnimatedBuilder`; Skelett-Puls 1,4 s ease-in-out |
| `box-shadow` mit Glow | `BoxShadow(color: akzent.withOpacity(...), blurRadius: n, spreadRadius: -m)` |
| Gradient-Border | äußerer Container mit Gradient + `padding: 1.5`, innerer mit Card-Farbe |
| `text-overflow: ellipsis` | `Text(..., maxLines: 1, overflow: TextOverflow.ellipsis)` |
| `flex-wrap` + `gap` | `Wrap(spacing:, runSpacing:)` |
| `min-height: 48px` auf Zeilen | `ConstrainedBox(minHeight: 48)` — Trefferfläche, nicht nur Optik |
| Semantics-Notiz im Board | `Semantics(label:, button:, enabled:, liveRegion:)` — merge je Zeile, nicht je Wort |

## 10. Assets

Keine Bild-Assets. Alle Icons sind Stroke-SVGs (1,6–2,5 px) und lassen sich als `CustomPainter` oder Icon-Font nachbauen — die Boards zeigen jede Form. Fonts **Poppins** und **JetBrains Mono** über `google_fonts` oder als gebündelte TTF (`pubspec.yaml`). Keine Anthropic- oder Fremdmarken-Assets enthalten.

## 11. Offene Punkte vor Release

Alle drei sind mit der dokumentierten Annahme baubar — keine blockiert die Umsetzung. Details in Modul 9, Sektion K.

1. **Überdeckungsschwelle Vergleichsstufe B** — 60 % Jaccard über `exerciseId`, am Bestand noch nicht geprüft. Als eine Konstante halten.
2. **Muskelzuordnung bei Mehrfachnennung** — ein Satz Bankdrücken zählt voll für Brust *und* Trizeps (nicht 0,5/0,5).
3. **Bestwert-Kriterium** — bestes Satzgewicht, wie im Runner. Bei Körpergewichtsübungen ohne Zusatzlast tritt die Wiederholungszahl an seine Stelle.

Aus Modul 8 zusätzlich: Impressumsinhalt (aktuell Platzhalter), Löschverhalten offline (Annahme: gesperrt bis Verbindung), CSV-Exportumfang.

Aus Modul 11 zusätzlich (Details in Modul 11, Sektion K):

4. **Nenner des Verhältnisses** — Trainingsminuten, Nenner immer sichtbar. Sie bevorteilen lange Ausdauer; die Fachgröße je Spur steht darunter.
5. **Schwellen bei Kurve und Perzentil** — Kurve ab 8, Perzentil ab 10 Einheiten je Aktivität. Rad und Wandern bleiben damit vorerst bei Schnitt und Spanne.
6. **Zonengrenzen bei Stufe 1** — nur mit gemessenem Maximalpuls (Einheit oder Profil). **Keine Altersformel.** Ohne Maximalpuls fällt die Kaskade auf Stufe 2.
