# Design-Gespräch 12 — Der Kraft-Tab: drei Seiten, grössere Elemente

**Stand:** 15.09.2026 · Anlass: Gerätetest auf dem Honor VKJ-NX9 (361 dp, Systemschrift 1,15)
Kopiere ab der Trennlinie in Claude Design.

---

## Kontext

ATEM Hybrid — Android-App für hybrides Training. Ästhetik: Dark Cyber-Athlete.
Farbsystem, Typenskala (Modul 1, ergänzt am 15.09. um `meta` und `labelUi`) und
Bausteine (Module 2 und 3) sind verbindlich und nicht Gegenstand dieses
Gesprächs. Die Bottom-Bar zeigt vorübergehend nur **Hybrid · Kraft**; Cardio und
Regeneration kommen zurück, sobald der Kraft-Tab steht.

Der Kraft-Tab ist heute **ein Bildschirm mit zwei Segmenten** (Trainieren |
Verlauf). Das Segment „Trainieren" ist eine einzige Scrollliste:

1. Kopf „Kraft · 16 Einheiten" und Segment-Umschalter
2. Karte „Heute": Planung des Tages, darin zwei Knöpfe (Freies Training,
   Plan wählen), darunter ein dritter Ghost-Knopf „Ohne Sätze erfassen"
3. Sektion „Pläne": Listenkarten mit Name und „7 Übungen"
4. Sektion „Übungen · 154": Suchfeld, Muskelfilter, Trefferliste, „Alle zeigen"
5. Sektion „Muskelbalance" (Modul 9)

## Das Problem — gemessen am Gerät

**Alles hebt sich von nichts ab.** Auf 361 dp stehen fünf Blöcke übereinander,
die alle dasselbe Rezept nutzen: `Card #14141D` auf `Canvas #050507`, 1-px-Rand
`#232334`, Radius 20, Text in `#CDD3EA`. Der einzige Kontrast ist der
Gradient-Knopf „Freies Training starten". Ergebnis: eine graue Säule gleich
hoher Karten, die man durchscrollt, ohne dass das Auge irgendwo hält.

Konkret:

- **Drei Aufgaben auf einer Seite.** Trainieren (heute), Verwalten (Pläne) und
  Nachschlagen (Übungen) sind drei verschiedene Absichten. Sie teilen sich eine
  Scrollliste und konkurrieren um dieselbe Fläche.
- **Drei Startwege ohne Rangfolge.** Gradient-Knopf, Outline-Knopf und
  Ghost-Knopf stehen direkt untereinander. Der dritte („Ohne Sätze erfassen")
  ist der seltenste Weg, hat aber dieselbe Breite wie der erste.
- **Kleine Zeilen, kleine Ziele.** Planzeilen sind ~56 dp hoch, Übungstreffer
  ~52 dp. Das erfüllt die 48-dp-Regel knapp, fühlt sich auf einem 6,8-Zoll-Gerät
  aber eng an: viel Rand, wenig Fläche.
- **Eine Flächenebene.** Die Boards kennen Canvas, Surface, Card und
  SurfaceRaised. Der Kraft-Tab nutzt nur Card. Damit fehlt die Tiefe, die
  Wichtiges von Umgebendem trennt.
- **Sektionsköpfe als einziger Rhythmus.** Zwischen den Blöcken stehen nur
  12-sp-Mono-Köpfe. Sie gliedern, aber sie gewichten nicht.

## Auftrag

Entwirf den Kraft-Tab neu als **drei Seiten, die man wischt**, und mache jedes
Element grösser als heute. Leitsatz zur Prüfung:

> *Eine Seite, eine Absicht. Was ich heute tue, steht oben und gross; was ich
> verwalte oder nachschlage, liegt eine Wischgeste weiter.*

### 1. Die drei Seiten

| Seite | Absicht | Inhalt heute | Inhalt neu |
|---|---|---|---|
| **Training** | Heute trainieren | Heute-Karte, drei Knöpfe, Muskelbalance | Heute-Karte als Hero, **ein** Primärweg, der Verlauf (heute Segment 2) als zweiter Block darunter |
| **Pläne** | Pläne anlegen und pflegen | Liste mit „Alle 3" | Alle Pläne als grosse Kacheln oder Zeilen, Anlegen als eigener Weg |
| **Übungen** | Nachschlagen | Suchfeld, Filter, Vorschau | Der komplette Übungskatalog, Suche oben |

Fragen, die das Board beantworten muss:

- **Wo bleibt „Verlauf"?** Heute ist er das zweite Segment. Vorschlag: Er wird
  Teil der Trainingsseite (unter dem Heute-Block, „Zuletzt" mit den letzten
  Einheiten und dem Weg zum kompletten Verlauf). Alternative: eine vierte
  Seite. Entscheide und begründe — vier Seiten sind auf 320 dp eng.
- **Wie zeigt die Seite an, dass es Nachbarn gibt?** Segment-Pille wie heute
  (drei statt zwei), Punkte, oder Reiter unter dem Tab-Namen. Auf jeden Fall:
  antippbar **und** wischbar, Rolle `tab`, Semantics „Pläne, Seite 2 von 3".
- **Wo landet „Ohne Sätze erfassen"?** Es ist ein Erfassungsweg, kein
  Startweg. Kandidaten: hinter „Plan wählen" im Startblatt, oder auf der
  Trainingsseite unter „Zuletzt" als Sekundärlink.
- **Muskelbalance:** Sie ist Auswertung, nicht Training. Vorschlag: zum
  Verlaufsblock, eingeklappt. Prüfe, ob sie auf der Trainingsseite überhaupt
  richtig ist oder in den Hybrid-Tab gehört.

### 2. „Grösser" — was das konkret heisst

Nicht mehr Schrift, sondern **mehr Fläche je Element und weniger Elemente je
Bildschirm**. Vorschlag als Ausgangspunkt, gern widersprechen:

- Heute-Karte als **Hero**: volle Breite, mindestens 160 dp hoch, Plan-Name in
  `titleLarge`, ein Primärknopf in voller Höhe (56 dp statt 48).
- Planzeilen **≥ 72 dp**, mit Ikon- oder Farbfläche links und zwei Zeilen
  (Name, „7 Übungen · zuletzt vor 3 Tagen").
- Übungstreffer **≥ 64 dp**, Muskelgruppe als Farbpunkt plus Wort.
- Knöpfe: Primär 56 dp, Sekundär 48 dp, Tertiär als Textlink — **nie drei
  gleich breite Knöpfe untereinander.**
- Abstände: Blöcke 32 dp statt 28, Zeilen 12 dp Innenpolster statt 10.
- Höchstens **zwei** Blöcke pro Seite ohne Scrollen sichtbar. Der Rest kommt
  beim Scrollen.

Zeig je Element vorher/nachher bei 1,0 und 1,15 Systemschrift auf 361 dp, dazu
den 200-%-Fall auf 320 dp.

### 3. Abheben — die zweite Flächenebene

Der Tab braucht Hierarchie durch Fläche, nicht durch Farbe:

- **Ein** Element pro Seite darf den Bereichston (`tabStrength`) als schwachen
  Verlauf tragen — auf der Trainingsseite die Heute-Karte.
- Listenzeilen ohne eigenen Rand, getrennt durch 1-px-Linien in `Border`; die
  Karte um die Liste ist `Surface`, nicht `Card`.
- Kacheln (Pläne) in `Card`, Hero in `SurfaceRaised`. Drei Ebenen, jede mit
  einer Aufgabe.
- Sektionsköpfe bleiben Mono-Versalien (`labelMicro`), aber sie bekommen
  eine Zahl daneben in `meta` und einen Weg rechts („Alle 3"), damit der Kopf
  auch etwas tut.

### 4. Das Wischen

- `PageView` mit drei Kindern; der Zustand jeder Seite (Scrollstand, Suche)
  überlebt den Wechsel.
- Wischen und Tippen führen zum selben Ergebnis; Systemzurück wechselt
  **nicht** die Seite, sondern schliesst den Tab-Stapel wie heute.
- Der Bereichston in der Bottom-Bar bleibt Kraft, egal welche Seite.
- Kollision: Der Runner, das Startblatt und Formulare liegen über dem
  `PageView`; dort darf kein Wischen die Seite wechseln.

## Bewegung

Messlatte ist GSAP-Qualität: orchestriert, nicht verstreut.

- **Seitenwechsel:** Inhalt folgt dem Finger 1:1; nach Loslassen 240 ms
  `easeOutCubic`. Der Seitenanzeiger wandert synchron, nicht nach.
- **Eintritt einer Seite:** Blöcke kaskadieren von oben, 40 ms Versatz, wie die
  Eintrittskaskade aus Commit 1b3f8f4. Beim Zurückwischen keine Kaskade.
- **Hero:** Der Bereichston-Verlauf atmet nicht; er ist Ruhelage. Der
  Primärknopf trägt den bestehenden Puls-Glow (2200 ms).
- **Zeilen:** Gedrückt = `scale 0.97` + Akzent-Glow, 200 ms. Kein Ripple.
- **„Animationen reduzieren":** Seitenwechsel ohne Kaskade, Wechsel als
  Überblendung 120 ms.

## Verbindliche Randbedingungen

- Nur Tokens aus `atem_theme.dart`; `#7A2BDB` nie als Text.
- Jedes Tap-Ziel ≥ 48 dp, jedes informationstragende Label ≥ 12 sp.
- Muss bei 200 % Systemschrift auf 320 dp ohne Überlauf funktionieren.
- Jeder Block braucht default, loading, empty, zu-wenig-Daten, error.
  Ein Block ohne Daten rendert nicht.
- Höchstens ein `BackdropFilter` je scrollender Seite.
- Bausteinliste aus Modul 2, 3, 5, 6 und 9 zuerst prüfen; das
  Entscheidungsprotokoll von Modul 5 (11 Einträge) und 11 gilt weiter.
- Keine neuen Muskelfarben, keine vierte Farbebene.

## Liefergegenstände

1. **Artboards** — die drei Seiten je in default, empty und 200 %; dazu der
   Übergang zwischen zwei Seiten als drei Einzelbilder
2. **Spezifikationstabelle** — je Element: Höhe, Innenpolster, Fläche,
   Typ-Rolle, Tap-Ziel
3. **Bewegungstabelle** — je Übergang: Auslöser, Eigenschaft, Dauer, Kurve,
   Ruhelage
4. **Stringtabelle** — `key | Deutsch | Englisch`, Keys unverändert in die ARB
5. **A11y-Notizen** — Seitenanzeiger, Wischgeste, Hero, Zeilen
6. **Entscheidungsprotokoll** — insbesondere: Verlauf als Block oder Seite,
   Muskelbalance hier oder Hybrid, Ort von „Ohne Sätze erfassen"
