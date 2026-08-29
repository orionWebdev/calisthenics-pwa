# Modul-für-Modul-Inhaltsverzeichnis

Jede Zeile nennt die Sektionen, die im Board tatsächlich als Überschrift stehen. Öffne die Datei im Browser und such nach dem Sektionsbuchstaben.

---

## 01 — Fundament: Typenskala, Tap-Ziele & Bewegung
`design_refs/01_Fundament_Typo_Interaction.dc.html`

Zehn Schriftgrößen kollabieren auf **acht benannte Rollen**; informationstragender Text wächst auf ≥ 12 sp; jedes Tap-Ziel bekommt 48 dp; Bewegung wird auf einen Satz Konstanten festgelegt.

**Zuerst umsetzen.** Danach kommt keine freie Schriftgröße und keine freie Animationsdauer mehr im Code vor.

---

## 02 — Flächen & Zustände
`design_refs/02_Flaechen_Zustaende.dc.html` · Modul 2

Sheet-Bauplan mit **zwei Höhenmodi**, Dialog-Anatomie für drei Fälle (**höchstens drei Wege**), drei Kartenrezepte mit benennbaren Zuständen.

Trägt später jedes Formular, jeden Löschvorgang und jede Auswahl. Vor Modul 4 fertig haben.

---

## 03 — Statusträger & Fortschritt
`design_refs/03_Status_Progress.dc.html` · Modul 3

Sechs Pill-Rezepte kollabieren auf **einen Baustein mit vier Achsen**; vier Fortschritts-Implementierungen auf eine.

Liefert: Pill/Chip, Statbox, Fortschrittsbalken, Notice-Slot. Diese vier tauchen in jedem folgenden Modul auf.

---

## 04 — Anmeldung & Onboarding (geschlossene Beta)
`design_refs/04_Anmeldung_Onboarding.dc.html` · Modul 4

Ein Login-Layout trägt **alle fünf Zustände ohne Layout-Sprung**; der unentschiedene erste Moment ist von „abgelehnt" unterscheidbar.

Enthält außerdem: der leere Erststart (relevant für Modul 8 — nach Kontolöschung betritt der Nutzer die App hier wieder, leer).

---

## 05 — Workouts: Übungen, Pläne und der Weg ins Training
`design_refs/05_Workouts.dc.html` · Modul 5

Der Tab beantwortet zuerst „Was mache ich jetzt?", danach „Was gibt es sonst?". Farbe kodiert die Kategorie.

**Regel, die ab hier überall gilt:** ein Block rendert nur mit Daten — der Bildschirm hört einfach früher auf. Ebenso: die Formkurve erscheint unter 8 Einheiten gar nicht.

---

## 06 — Verlauf: was passiert ist, und was es bedeutet
`design_refs/06_Verlauf.dc.html` · Modul 6

110 Einheiten an 87 Tagen, Lücken bis 74 Tage. **Die Lücke ist der Normalfall, nicht der Fehlerfall.**

Sektionen: `B` Die Lücke (vier Lagen, eine Karte) · `A1` Verlaufs-Tab · `A2` Einheitenliste (Monate, Lücken, Mehrfachtage) · `A3` Detail einer Einheit (vier Datenlagen) · `A4` Auswertung / Form-Trend · `C` Verteilung statt Durchschnitt · `D` Chart-Spezifikation für 320 dp · `E` Spezifikation · `F` Strings · `G` A11y · `H` Wiederverwendung · `I` Entscheidungsprotokoll

---

## 07 — Daten ändern: anlegen, bearbeiten, löschen
`design_refs/07_Daten_Eingaben.dc.html` · Modul 7

Alles Schreibende in einem Zug. Leitsatz: ein Formular fragt so wenig, wie die Datenbank verlangt — und ein Löschen sagt so genau, was es zerstört.

Sektionen: `B` Schreibregeln + die difficulty-Falle · `A1` Workouts-Tab Gewichtung · `A2` Übung anlegen (drei Pflichtfelder) · `A3` Übungsdetail (eigen bearbeitbar, kuratiert nicht) · `A4` Plan anlegen/bearbeiten · `A5` Absolvierte Einheit bearbeiten und löschen · `C` Schreibmatrix (welche Sicherung wann) · `E` Spezifikation · `F` Strings · `G` A11y · `H` Wiederverwendung · `I` Entscheidungsprotokoll (11 Einträge)

**Wichtigste Festlegungen:** `reps` bleibt Text · `difficulty` ist Zahl 1–5 ohne Vorbelegung · kuratierte Datensätze sind schreibgeschützt (Schloss-Chip, kein gesperrter Button) · kaputte Planeinträge blockieren nicht, sie bleiben als sichtbare Lücke · optimistisch schreiben, ehrlich zurücknehmen · kein Undo beim Übungslöschen (Kette wäre nicht exakt zurückdrehbar).

---

## 08 — Einstellungen und Profil
`design_refs/08_Einstellungen_Profil.dc.html` · Modul 8 · letztes Modul vor Veröffentlichung

Acht Einstellungen, von denen **eine rückwirkend rechnet** und **eine Jahre vernichtet**. Der Rest ist Vorliebe.

Sektionen: `B` Klassen und Wirkzeitpunkt · `A1` Der Bildschirm (Profilkopf als Tatsache, nicht als Formular) · `A2` Körpergewicht · `A3` Pausenzeit und Einheitensystem · `A4` Konto löschen (sechs Sammlungen, zwei Stufen, ein getipptes Wort) · `A5` Daten ausgeben · `F` Spezifikation · `G` Strings · `H` A11y · `I` Wiederverwendung · `K` Offene Fragen

**Festlegungen:** Körpergewicht zeigt eine **Live-Vorschau** (Last, ACWR, Formkurve, Bestwert) unter dem Feld statt einer Warnung, mit 30-s-Undo · Dark-Theme-Zeile entfällt (steht als Einzeiler in „Über die App") · Sprache nur Deutsch/Englisch, Systemvorgabe wird einmal beim Erststart berücksichtigt · Kontolöschung zweistufig, Stufe 2 verlangt getipptes „LÖSCHEN", Stufe 1 bietet Export (JSON/CSV) als Alternative · **kein Bar-Slot** — Zugang über das Profilbild im Dashboard-Header.

**Offen:** Impressumsinhalt · Löschverhalten offline (Annahme: gesperrt bis Verbindung) · CSV-Exportumfang.

---

## 09 — Aussagekraft: Vergleich, Balance, Verlauf
`design_refs/09_Aussagekraft.dc.html` · Modul 9

Drei bestehende Screens bekommen je einen Block, der aus vorhandenen Daten eine Aussage macht. Keine neuen Bereiche. Braucht Modul 5, 6 und 7 fertig.

Sektionen: `B` Die drei Blöcke (Grundlage, Mindestdaten, Grenze) · `A1` Einheitendetail — der Vergleich, vier Zustände · `A2` Was „gleichartig" heißt — drei Stufen · `A3` Workouts-Tab — Muskelbalance, drei Zustände · `A4` Übungsdetail — dein Verlauf, drei Zustände · `C` Datenlage · `F` Spezifikation · `G` Strings · `H` A11y · `I` Wiederverwendung · `J` Entscheidungsprotokoll (12 Einträge) · `K` Offene Fragen

**Die drei Blöcke:**

| Block | Ort | Mindestdaten | Sonst |
|---|---|---|---|
| Vergleich | Einheitendetail | eine Bezugseinheit | ein Satz im Wertekasten |
| Muskelbalance | Workouts-Tab | 8 Einheiten **mit Übungen** | Fortschrittsbalken bis zur Schwelle |
| Übungsverlauf | Übungsdetail | eine Ausführung | Block fehlt, Screen endet früher |

**Vergleichskaskade — drei benannte Stufen, jede mit eigenem Chip:**
- **A · Gleicher Plan** — `planId` gleich, jüngste davor. Trifft 52/136. Alle vier Werte.
- **B · Gleiche Übungen** — Jaccard-Überdeckung ≥ 60 % über `exerciseId`, innerhalb 90 Tagen. Alle vier Werte.
- **C · Gleiche Art** — Typ gleich, **Median** der letzten 5 (nicht Mittelwert). Nur Dauer und Last; Volumen und Sätze tragen „—". Regeneration bekommt gar keinen Block.

**Verlaufsstufen im Übungsdetail:** 0 → Block fehlt · 1 → nur „Damals" · 2–4 → Werte ohne Kurve · ≥ 5 → mit Kurve.

**Neu entstandener Baustein (der einzige):** die **Bezugskapsel** — Chip mit Grundlage und Datum über einer Wertegruppe.

---

## 10 — Dashboard (Home)
`design_refs/10_Dashboard.dc.html` · plus `Prototyp_Dashboard.dc.html`

Der Home-Screen: Readiness-Gauge, Wochen-Performance-Chart, heutige Session, Quick-Actions, Bottom-Nav, Profilbild im Header (Zugang zu Modul 8).

**Zuletzt bauen** — er zitiert Bausteine aus allen anderen Modulen.

Der interaktive Prototyp zeigt Timing und Animationen (Puls-Glow 2,2 s, Flacker-Dot ~2,6 s, laufender Session-Zustand). **Seine Farben sind eine veraltete Fassung** (`#030308`, `#FF007A`, `#9D4EDD`) — es gilt `atem_theme.dart`.

---

## 11 — Hybrid & Cardio: drei Tabs, zwei Spuren, ein Verhältnis
`design_refs/11_Hybrid_Cardio.dc.html` · Modul 11 · Anleitungsprompt: `PROMPT_MODUL_11.md`

Die App heißt Hybrid und kann nur Kraft. 51 Ausdauer- und 12 Regenerationseinheiten liegen im Bestand — ohne Erfassungsweg und ohne eine einzige Auswertung. **40 % des Bestands waren unsichtbar.**

Leitsatz: *Hybrid heißt nicht, Kraft und Ausdauer zu einer Zahl zu verrechnen, sondern beide Spuren einzeln messbar zu halten und nur ihr Verhältnis zu zeigen.*

Sektionen: `A` Navigation neu geschnitten (drei Tab-Wurzeln + drei Wege) · `B1` Cardio-Wurzel (voll, dünn, leer, ladend, Fehler) · `B2` Ausdauereinheit erfassen (nacherfassen, Aktivitätsauswahl, Live-Uhr) · `B3` Ausdauer-Auswertung (Wochenstreifen, Tempokurve, Verteilung, Perzentil) · `B4` Intensitätskaskade (drei Stufen + Führungsregel) · `C1` Zwei Spuren, ein Verhältnis · `C2` Regeneration (Zeile, Sheet, Sprachregel) · `C3` dünner und leerer Hybrid-Tab + **Zustandsmatrix** · `D` Datenlage · `F` Spezifikation · `G` Strings (rund 90 Keys) · `H` A11y · `I` Wiederverwendung aus Modul 01–10 · `J` Entscheidungsprotokoll (14 Einträge) · `K` Offene Fragen

**Navigation — es bleiben genau drei Plätze:**

| Platz | Frage | Was hineinwandert |
|---|---|---|
| **Kraft** | Was trainiere ich, und wie entwickelt es sich? | heutiger Workouts-Tab + kompletter Verlauf (Modul 6 + 9), Segment „Trainieren \| Verlauf" |
| **Cardio** | Was bin ich gelaufen, und wird es besser? | neu: Wurzel, Erfassung, Auswertung, Segment „Einheiten \| Auswertung" |
| **Hybrid** | Wie steht es um mich, über beides? | heutiger Start- + Analyse-Tab (Modul 10) + Regenerationszeile |

**Intensitätskaskade — dreistufig, geführte Stufe immer sichtbar:**
- **1 · Ø Herzfrequenz** — 4/51 belegt. Führt nur mit gemessenem Ø- *und* Maximalpuls. Heute leer, aber gebaut (Health Connect füllt sie später).
- **2 · RPE 1–5** — 32/51. Trägt ein Wort, keinen Prozentwert.
- **3 · Tempo gegen eigenen Schnitt derselben Aktivität** — 51/51. Der Rückfall, der nie ausfällt (Median, nie über Aktivitäten hinweg).
- Sonst: kein Intensitätskasten. Genau eine Stufe urteilt, die anderen stehen als Zahl ohne Bewertung.

**Schwellen:** Wochenkilometer ab 3 Wochen mit Einheiten · Tempokurve ab 8 Einheiten je Aktivität · Perzentil ab 10 je Aktivität · Bereitschaft und Formwert ab 8 Einheiten · Verhältnis schon ab 2 Einheiten (es ist ein Anteil, keine Prognose), Verschiebung erst ab 4 Wochen.

**Wichtigste Festlegungen:** keine gemeinsame Lastwährung (kein Hybrid-Score) · Verhältnis über Trainingsminuten mit Nenner, kein Sollverhältnis · kein GPS und keine Standortberechtigung · Tempo ist Ausgabe, nie Eingabe · acht Aktivitäten, aber nicht gleich laut (vier unbelegte als Kapseln unter „Weitere") · Regeneration ist eine Zeile im Hybrid-Tab, kein vierter Tab, und trägt keine Last · leere Woche als 2-dp-Balken, kein Nullbalken.

**Neu entstandene Bausteine (nur zwei):** **Verhältnisbalken** (zwei Segmente, eigene Fachgröße je Spur — Ausdauer in Violet als Fläche) und **Live-Uhr** (persistent gegen Prozesskill).

**Offen:** Nenner des Verhältnisses (Annahme: Trainingsminuten) · Schwellen bei Kurve und Perzentil (bleiben, Schnitt+Spanne treten an die Stelle) · Zonengrenzen Stufe 1 (nur mit gemessenem Maximalpuls, keine Altersformel).

---

## Prototypen
`Prototyp_Dashboard.dc.html` · `Prototyp_Workout_Runner.dc.html`

Klickbar, im iOS-Rahmen. Nur als Referenz für **Bewegung, Timing und Ablauf** heranziehen — nicht für Farben, Maße oder Texte.

Der Workout Runner ist der Weg ins Training aus Modul 5 und benutzt bereits zwei Werte, die in Modul 9 wieder auftauchen: bestes Satzgewicht und letzte Ausführung. **Das Bestwert-Kriterium muss zwischen Runner und Übungsdetail identisch bleiben.**
