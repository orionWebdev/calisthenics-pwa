# Vertrag 1a — Barrierefreiheit

**Status:** verbindlich ab Stufe 1
**Gilt für:** jeden Widget-Code in `lib/`

Dieser Vertrag ist die Messlatte. Jede spätere Stufe wird gegen ihn geprüft, und jeder
Claude-Design-Prompt zitiert seine Randbedingungen wörtlich.

## Warum

Zwei Gründe, keiner davon Kosmetik. Der Play-Store-Pre-Launch-Report prüft Tap-Ziele,
Kontrast und fehlende Beschriftungen automatisch und meldet sie im Entwicklerkonto. Und der
European Accessibility Act gilt seit Juni 2025 für Verbraucherdienste, die in der EU verkauft
werden — bei einer Abo-App mit deutschem Anbieter ist das mindestens zu klären, nicht
stillschweigend zu ignorieren.

Der eigentliche Grund ist aber einfacher: Diese App wird im Training bedient, mit
schweißnassen Fingern, in schlechtem Licht, zwischen zwei Sätzen. Große Tap-Ziele und
lesbarer Text sind hier kein Zugeständnis an eine Randgruppe, sondern das Kernszenario.

---

## R1 — Mindestschriftgröße

**Informationstragender Text wird mit mindestens `12` deklariert.** Maßgeblich ist der
deklarierte Wert bei Skalierung 1.0, nicht der gerenderte.

Die heutigen zehn Größen zwischen 7,5 und 11,5 kollabieren auf drei Token:

| Token | Wert | Verwendung |
|---|---|---|
| `labelMicro` | 12 sp, `letterSpacing` 1.5–2.5, w700 | HUD-Labels, Tabellenköpfe, Nav, Chips |
| `labelSmall` | 12 sp | Badges, Unterzeilen, Hilfstexte |
| `labelMedium` | 13 sp | Buttons, Dialogaktionen |

Das ist eine **sichtbare Designänderung** und wird im ersten Claude-Design-Gespräch
(Stufe 3) verhandelt, nicht nebenbei entschieden.

## R2 — Die Ausnahme für dekorative Labels

Rein dekorative Beschriftung darf kleiner sein, aber nur unter drei Bedingungen:

1. Sie wird explizit als `decorative: true` deklariert
2. Sie trägt ein `semanticsLabel` — sonst Compile-Fehler
3. Ihre Information steht **zusätzlich** an anderer Stelle in lesbarer Größe

Die Liste bleibt kurz genug, um sie zu überblicken. **Obergrenze: sechs Stellen.**
Kandidaten: die drei Chart-Legenden und die Prozentzahl im Mini-Ring, deren Wert die
Kartenunterzeile ohnehin wiederholt.

Wer diese Ausnahme für etwas nutzt, das man lesen können muss, umgeht den Vertrag.

## R3 — Tap-Ziele

**Jedes interaktive Element hat eine Layoutfläche von mindestens 48 × 48 dp.** Nicht nur eine
vergrößerte Trefferfläche — die *Knotengröße* muss stimmen, sonst schlägt die Prüfung an und
man wäre versucht, sie zu unterdrücken.

Umgesetzt wird das über `AtemTappable`: eine `ConstrainedBox` vergrößert die Fläche, das
sichtbare Kind bleibt zentriert in seiner gestalteten Größe. Die Optik ändert sich nicht, nur
die umgebenden Abstände werden einmal nachgezogen.

Es gibt **keinen zweiten Weg**, etwas antippbar zu machen. Rohe `GestureDetector` und
`InkWell` außerhalb von `lib/core/widgets/` sind verboten und werden vom Analyzer gemeldet.

`AtemTappable` verlangt `semanticLabel` als Pflichtparameter. Damit wird „Label vergessen"
vom Prüfbefund zum Compile-Fehler.

**Ausnahme, die der Wrapper nicht heilt:** Textfelder. Die Prüfung überspringt sie nicht.
`AtemNumberField` braucht echte 48 dp Höhe.

## R4 — Kontrast

AA: **4,5:1** für Normaltext, **3:1** ab 18 sp oder ab 14 sp fett.

Gemessene Matrix (Text auf Fläche):

| | base | surfaceSolid | card | surfaceRaised |
|---|---|---|---|---|
| `textPrimary` | 20,4 | 19,7 | 18,3 | 17,2 |
| `textSecondary` | 7,9 | 7,7 | 7,1 | 6,7 |
| `textTertiary` | 13,7 | 13,2 | 12,3 | 11,6 |
| `cyan` | 14,7 | 14,2 | 13,2 | 12,4 |
| `green` | 15,2 | 14,7 | 13,6 | 12,8 |
| `amber` | 11,1 | 10,8 | 10,0 | 9,4 |
| `magenta` | 5,0 | 4,9 | **4,5** | **4,3 ✗** |
| `violet` | 3,1 | **3,0 ✗** | **2,8 ✗** | **2,6 ✗** |
| `violetLight` | 4,4 ✗ | 4,3 ✗ | 4,0 ✗ | 3,7 ✗ |

**Daraus folgen zwei harte Regeln:**

- **`violet` und `violetLight` sind niemals Textfarbe.** Nur Fläche, Rand, Verlaufsstop.
  Die heutigen Muskel-Chips im Runner verstoßen dagegen und werden umgestellt.
- **`magenta` ist auf `surfaceRaised` keine Textfarbe** — also nicht in Bottom Sheets und
  Dialogen. Auf `card` liegt es mit 4,53 knapp über der Schwelle und ist dort zulässig.

Geprüft wird das **statisch** über eine Matrix aller Paare, nicht über
`textContrastGuideline`. Dessen eigene Dokumentation nennt das Verfahren „very naive"; auf
Glow, Blur und Verläufen liefert es falsche Treffer in beide Richtungen. Es läuft mit, aber
nur als Bericht.

## R5 — Schriftskalierung

Unterstützt wird **1.0 bis 2.0**. Am Wurzelknoten wird auf 2.0 gedeckelt — als Schutz gegen
Hersteller-Oberflächen, die zusätzlich skalieren, nicht als Ausweichstrategie.

**Nach unten wird nie gedeckelt.** Ein Deckel unter 1.3 verweigert dem Nutzer eine
ausdrücklich getroffene Einstellung und ist ein WCAG-Verstoß.

**Umbrechen ist die Regel.** Feste Höhen um Text werden zu `minHeight`. Feste Spaltenbreiten
brechen ab einem Schwellwert in eine gestapelte Anordnung um — die Satz-Tabelle im Runner mit
fünf Spalten ist bei 320 dp und 200 % nicht zu halten und wechselt ab etwa Faktor 1,33 in eine
zweizeilige Darstellung.

**Lokales Deckeln nur, wo die Geometrie eine Grafik ist und nicht Text** — Arc-Gauge,
Chart-Tooltip, Mini-Ring. Erlaubt ist das ausschließlich, wenn dieselbe Information direkt
daneben in voll skalierendem Text steht. Der Gauge hat mit Stufenlabel und Empfehlungstext
genau das. **Ein Deckel ohne diese Wiederholung ist nicht zulässig.**

**`FittedBox` um Text ist verboten.** Es macht die Skalierungseinstellung des Nutzers
stillschweigend rückgängig. Die Micro-Stats auf dem Dashboard tun das heute.

## R6 — Farbe ist nie der einzige Statusträger

Jeder Zustand braucht zusätzlich Form, Text oder Symbol.

Heutige Verstöße, die in Stufe 5 fallen:

- **Satz abgehakt** — das Häkchen wird in beiden Zuständen gezeichnet, nur die Farbe wechselt
- **Satz-Typ W/N/D/F** — ein Buchstabe plus Farbe, ohne Legende
- **Hohe Intensität** — nur Rand- und Textfarbe ändern sich, der Text bleibt gleich
- **Chart** — Load und Recovery unterscheiden sich allein durch die Farbe; Strain ist
  immerhin gestrichelt

## R7 — Semantics

| Element | Vertrag |
|---|---|
| Interaktiv | `Semantics(button: true, enabled:, selected:, label:, onTap:)` über `AtemTappable` |
| Icon | **immer** `ExcludeSemantics`, nie eigenes Label — das Label lebt am umschließenden Element |
| Messwert + Beschriftung | zu **einem** Knoten verschmelzen: „HRV 82 Millisekunden", nicht „82 ms" und dann „HRV" |
| Fortschritt, Ring, Gauge | `Semantics(label:, value: '<n> %')` |
| Diagramm | ein zusammenfassendes `Semantics(label:)`, Painter `ExcludeSemantics` |
| Ladezustand | Platzhalter `ExcludeSemantics` unter einem `Semantics(label: l10n.loading)` |
| Fehler | `Semantics(liveRegion: true)` |
| Barriere von Sheet/Dialog | `barrierLabel` gesetzt |

Labels stammen **immer** aus dem ARB, nie aus Literalen. Ob ein Label *sinnvoll* ist, kann
keine Maschine prüfen — dafür gibt es den TalkBack-Durchgang je Stufe.

## R8 — Bewegung

Dekorative Dauerschleifen laufen über `AtemMotion.decorative(context)` und liefern
`Duration.zero`, wenn `MediaQuery.disableAnimationsOf(context)` gesetzt ist.

Das ist nicht nur eine Rücksicht auf Nutzer mit vestibulären Beschwerden — es ist die
Voraussetzung dafür, dass `pumpAndSettle()` in Tests überhaupt terminiert. Heute laufen auf
dem Dashboard fünf Controller mit `..repeat()`; jeder Test, der zur Ruhe kommen will, hängt.

---

## Prüfung

| Regel | Wie geprüft | Blockierend |
|---|---|---|
| R1 | Analyzer: `atem_no_small_font_size` | ja |
| R2 | Analyzer: `atem_decorative_label_needs_semantics` | ja |
| R3 | `androidTapTargetGuideline` über die 3×3-Matrix | ja |
| R3 | Analyzer: `atem_no_raw_gesture_detector` | ja |
| R4 | Statischer Kontrast-Matrix-Test | ja |
| R4 | `textContrastGuideline` | **nein, nur Bericht** |
| R5 | Überlauf über die 3×3-Matrix (1.0/1.3/2.0 × 320/360/412) | ja |
| R5 | Analyzer: `atem_no_fitted_box` | ja |
| R6 | — | **manuell, je Stufe** |
| R7 | `labeledTapTargetGuideline` | ja |
| R7 | Sinnhaftigkeit der Labels | **manuell, TalkBack-Durchgang** |
| R8 | `pumpAndSettle()` terminiert | ja |

Die manuellen Punkte sind als solche benannt. Sie werden nicht als automatisiert ausgegeben
und gehören zur Fertig-Definition jeder Stufe:

- ein TalkBack-Durchgang je Screen
- ein Durchgang mit „Animationen entfernen"
- ein Durchgang bei 200 % Schrift auf einem 320-dp-Gerät
