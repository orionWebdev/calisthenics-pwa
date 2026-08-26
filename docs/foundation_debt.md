# Schuldenverzeichnis des Fundaments

**Erhoben:** 26.08.2026, Commit `986767f`
**Getilgt:** 26.08.2026, Ende Stufe 5
**Zweck:** Der Nachweis, dass die Prüfungen aus Stufe 2 greifen — und die
Messlatte, an der Stufe 5 überprüft wurde.

Jede Zahl hier musste am Ende von Stufe 5 **null** sein. Sie ist es.

---

## Stand nach Stufe 5

| Messung | Erhebung | Heute |
|---|---|---|
| Dashboard — Layout / Tap-Ziel / Label | –, 5, 0 | **0 / 0 / 0** |
| Workout Runner — Layout / Tap-Ziel / Label | –, 19, 14 | **0 / 0 / 0** |
| `fontSize` < 12 | 41 | **0** |
| Rohe `GestureDetector` / `InkWell` | 5 | **0** |
| `FittedBox` um Text | 1 | **0** |
| Textliterale in `Text(...)` | 17 | **0** |
| `package:flutter/*` in `domain/` | 2 | **0** |

Alle fünf Konventionsregeln in `tool/check_conventions.dart` stehen seit Stufe 5 auf
`active: true`, und `flutter test` schließt das A11y-Tor ohne Ausschluss ein.

### Was die Erhebung selbst falsch gemessen hat

Der Schuldenbericht lief ursprünglich gegen **eine einzige Zelle** von 390x1400 dp bei
Skalierung 1,0 — einen Bildschirm, der höher ist als jedes reale Gerät. Dort läuft nichts
über, und nichts wird an einem `ClipRRect` beschnitten. Er meldete deshalb für das neu
gebaute Dashboard `tap-target: 0`, während das Tor über dieselben Screens vier Verstöße
fand: zwei Überläufe und zwei Tap-Ziele von 31 bzw. 34 dp.

Die beiden zu kleinen Ziele waren gar keine zu kleinen Ziele. Die Navigationszeile lief
über, und ein Überlauf beschneidet die Semantics-Rechtecke am `ClipRRect` der Leiste — der
Layoutfehler erschien als Größenfehler. Ein Messgerät, das lockerer misst als die Prüfung,
ist schlimmer als keines: Es meldet Entwarnung. Bericht und Tor teilen sich jetzt
`collectA11yFindings` als einzige Quelle und laufen über dieselbe 3x3-Matrix.

---

## Barrierefreiheit — gemessen am gerenderten Semantics-Baum

Erhoben mit `test/a11y/debt_report_test.dart`. Die Zahlen unten stammen aus der
ursprünglichen Einzelzelle bei 390 dp — siehe „Was die Erhebung selbst falsch gemessen hat".

| Screen | Tap-Ziel < 48 dp | Ohne Label |
|---|---|---|
| Dashboard | **5** | 0 |
| Workout Runner | **19** | **14** |

### Dashboard

Alle fünf Verstöße sind die Einträge der Floating Nav, jeweils 43 dp hoch. Sie tragen
sichtbaren Text, deshalb keine Label-Verstöße — aber ohne `Semantics(button:, selected:)`
fehlt TalkBack die Rolle und der aktive Zustand.

Die vier Quick-Action-Kacheln erscheinen **gar nicht** in der Liste: Ihnen fehlt `onTap`,
sie sind also nicht antippbar. Das ist eine Regression, kein Erfolg.

### Workout Runner

| Element | Größe | Anzahl |
|---|---|---|
| Icon-Buttons oben (Pause, Notizen, Beenden) | 40×40 | 3, alle ohne Label |
| Pfeile Übungswechsel | 44×44 | 2, ohne Label |
| Satz-Typ-Chip (W/N/D/F) | 34×32 | 3 |
| Gewichtsfeld | 66×44 | 3, ohne Label |
| Wiederholungsfeld | 54×44 | 3, ohne Label |
| Häkchen | 44×44 | 3, ohne Label |
| „FORM GUIDE" | 128×22 | 1 |
| „+ SATZ HINZUFÜGEN" | 358×43 | 1 |

Der destruktivste Knopf der App — „Workout beenden" — ist 40×40 groß und für einen
Screenreader namenlos.

---

## Statische Muster

Erhoben mit `tool/check_conventions.dart` über `lib/`.

| Regel | Verstöße | Schwerpunkt |
|---|---|---|
| `fontSize` < 12 | **41** | dashboard 21, runner 17, theme 3 |
| Rohe `GestureDetector` / `InkWell` | **5** | dashboard 4, runner 1 |
| `FittedBox` um Text | **1** | dashboard (`_MicroStat`) |
| Textliterale in `Text(...)` | **17** ⚠️ | dashboard, runner |
| `package:flutter/*` in `domain/` | **2** | `dashboard_data.dart`, `workout_session.dart` |
| `violet` als Textfarbe | **0** ⚠️ | siehe unten |

### Wo die Messung untertreibt

Zwei Zahlen sind **Untergrenzen**, nicht Wahrheiten — die Textsuche kann nicht sehen,
was ein AST sieht:

**`violet` als Textfarbe: gemeldet 0, tatsächlich vorhanden.** Der Runner ruft
`_chip(muskel, AtemColors.violet)` auf; erst innerhalb der Hilfsmethode wird daraus
`color: color`. Der Verstoß ist echt — Violet auf Card liegt bei 2,8:1 —, aber über die
Aufrufkette hinweg für eine Textsuche unsichtbar.

**Textliterale: gemeldet 17, tatsächlich rund 118.** Der Prüfer arbeitet zeilenweise und
verlangt `Text('` im selben Zeilenumbruch. Nicht erfasst: über mehrere Zeilen umgebrochene
Aufrufe, interpolierte Strings, `Text.rich`, `TextSpan`, Literale in `switch`-Ausdrücken und
die deutschen UI-Texte in den Enum-Konstanten von `ReadinessLevel` und `SetType`.

Beides sind genau die Fälle, für die der Analyzer-Ansatz gebaut wird. Bis er steht, gilt:
Die Zahlen taugen als Fortschrittsanzeige, nicht als Vollständigkeitsbeweis.

---

## Nicht maschinell erfasst

Diese Punkte stehen im A11y-Vertrag, lassen sich aber nur von Hand prüfen. Sie gehören
zur Fertig-Definition von Stufe 5:

- **Farbe als einziger Statusträger** — bekannt: abgehakter Satz (nur Farbwechsel am
  Häkchen), Satz-Typ W/N/D/F, „High Intensity"-Badge, Load- gegen Recovery-Kurve
- **Sinnhaftigkeit der Semantics-Labels** — ein Label kann vorhanden und trotzdem
  unbrauchbar sein
- **Lesereihenfolge und Fokusreihenfolge** unter TalkBack
- **Überlauf bei 200 % Schrift auf echter Hardware** — die Matrix prüft das im Test,
  aber Herstelleroberflächen skalieren teils zusätzlich

---

## Bekannte Layoutfehler, die die Matrix noch nicht meldet

Aus dem Audit, noch nicht als Testbefund reproduziert:

- **`_PerformancePainter` rechnet absolut** für eine 358×152-Fläche. Auf 320 dp ist die
  Zeichenfläche nur rund 110 dp hoch, die Tagesbeschriftung wird bei y=140 gemalt und
  weggeschnitten. Der Painter wirft keine Exception, malt aber ins Leere — deshalb
  taucht das nicht als `layout`-Befund auf.
- **Floating Nav ohne Safe-Area-Inset.** `Positioned(bottom: 16)` ohne
  `MediaQuery.viewPaddingOf(context).bottom`; auf Geräten mit Drei-Tasten-Navigation
  liegt die Leiste unter der Systemleiste. Im Test nicht sichtbar, weil dort kein
  Systeminset existiert.

Beide sind in Stufe 5 behoben: Der Chart-Painter rechnet in Bruchteilen der übergebenen
`Size`, und die Navigation addiert `MediaQuery.viewPaddingOf(context).bottom`. Beide bleiben
hier stehen, weil sie zeigen, was die Matrix **nicht** fängt: ein Painter, der ins Leere
malt, und ein Inset, das im Test nicht existiert. Dafür braucht es weiterhin den Blick auf
das Gerät.
