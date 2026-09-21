# Prompt für Claude Design — Modul 16: Das Einheitendetail

## Worum es geht

ATEM Hybrid ist eine private Android-App für hybrides Training (Kraft und
Ausdauer), Ästhetik „Dark Cyber-Athlete". Das **Einheitendetail** ist der
Bildschirm, den man öffnet, wenn man auf eine abgeschlossene Einheit im
Verlauf tippt. Er ist der einzige Ort, an dem eine einzelne Einheit
vollständig zu sehen ist.

Er soll neu gestaltet werden. Das ist kein Feinschliff: Der Bildschirm
bekommt Daten, für die er nie gebaut wurde, und trägt schon heute zu wenig
Ordnung.

## Was heute nicht stimmt

Die Zusammenfassung oben ist **unübersichtlich: sehr viel grauer Text,
keine Farbe, keine Rangfolge.** Man sieht nicht auf einen Blick, was diese
Einheit war und was an ihr bemerkenswert ist. Alles wiegt gleich viel.

## Was dazukommt

Seit ATEM Trainings aus Health Connect übernimmt, trägt eine Einheit
Grössen, die vorher niemand hatte:

- **Ø-Puls, Maximalpuls, Minimalpuls**
- **Zeit in Herzfrequenzzonen** — fünf Zonen, die der Nutzer selbst
  festlegt. Dafür braucht es **zusätzlich eine Stelle in den Einstellungen**,
  an der man die fünf Zonen definiert. Auch die will gestaltet werden.
- **Kalorien**
- **Dauer und Startzeit** (bisher stand nur der Tag da)
- **Herkunft**: selbst geführt · aus der Uhr übernommen · beides
  zusammengeführt

## Vier Arten, ein Bildschirm

Derselbe Bildschirm zeigt vier sehr verschiedene Einheiten:

- **Kraft** und **Körpergewicht** — Übungen, Sätze, Wiederholungen,
  Gewichte, Anstrengung
- **Ausdauer** — heute Zeit und Strecke
- **Regeneration** — oft nur Dauer

Und es kommt mehr: **Laufen, Radfahren, Schwimmen** als eigene Ausdauerarten
mit Strecke, Tempo, Splits, Höhenmetern. Das muss die Lösung heute schon
tragen, ohne dass sie später zerfällt.

Eine Einheit kann ausserdem **fast nichts** enthalten: 16 von 63
Krafteinheiten im Bestand haben gar keine Übungen, 25 von 136 keine Dauer.
Das ist gültiger Bestand, kein Fehler.

## Nicht verhandelbar

- Nur die Farbtokens aus `atem_theme.dart` / README §3. Keine erfundenen
  Zwischentöne, keine zehnte Muskelfarbe, keine vierte Farbebene.
- `#94A3B8` ist die dunkelste erlaubte Textfarbe. Informationstragender Text
  ≥ 12 sp, Kontrast ≥ 4,5:1.
- Violett `#7A2BDB` ist **nur Fläche, nie Text**.
- Cyan trägt **Handlung** — es ist global dafür reserviert. Wer Cyan sieht,
  kann tippen.
- Farbe ist nie der einzige Statusträger — immer Wort, Glyph oder Icon
  daneben.
- Jedes Tap-Ziel ≥ 48 dp. Kein Material-Ripple: gedrückt = `scale 0.97` +
  Akzent-Glow, 200 ms.
- Muss bei **200 % Systemschrift auf 320 dp Breite** ohne Überlauf
  funktionieren.
- Höchstens ein `BackdropFilter` pro scrollendem Screen.

## Haltung zu Zahlen

- **Jede Zahl nennt ihre Grundlage** („Ø 124 aus 4 von 14 Einheiten"). Nie
  ein Anteil ohne Nenner.
- **Kein Sollverhältnis, kein Urteil.** Die App weiss nicht, wie viel Zone 4
  richtig ist. Zonen beschreiben, was war — sie bewerten nicht.
- **Deltas sind Tatsachen**, in `#CDD3EA` mit Richtungsglyph. Keine
  Ampelfarben. „Mehr" ist nicht „besser".
- **Drei Textstufen:** Weiss für Titel und die Hauptzahl · `#CDD3EA` für
  Sätze, die gelesen werden · `#94A3B8` für Metazeilen und Beschriftungen.
  Ein Blickfang je Block, nicht zehn.
- **Erklärungen sind versteckt.** Was ein Block zeigt und wie gerechnet
  wird, steht hinter einem ⓘ neben dem Titel und klappt im Block auf.
  Sichtbar bleiben Titel, Wert und eine kurze Grundlage.

## Eine Regel aus Modul 15, die hier gilt

Puls und Kalorien einer übernommenen Einheit liegen **am Uhr-Datensatz**,
nicht in der Einheit. Keine Grösse hat zwei Quellen — nur deshalb ist
„Verbindung lösen" verlustfrei. Der Bildschirm zeigt also Werte, die aus
zwei Dokumenten kommen, und muss das kenntlich machen, ohne daraus zwei
getrennte Bereiche zu bauen. Eine **Quellenkapsel** („App · Sätze, Dauer,
Anstrengung" / „Uhr · Puls, Kalorien") gibt es bereits.

## Zustände sind Pflicht

Jeder Block braucht **default, loading, empty, zu-wenig-Daten und error**.
Kein Zustand ist „kommt später". Auf diesem Bildschirm gilt: Ein Block ohne
Daten **rendert nicht** — der Bildschirm hört einfach früher auf. Keine
Platzhalterkarte, kein „Leg los!"-Aufruf.

## Was ich von dir brauche

Ein Spezifikations-Board im Format der Module 1–15: **Leitsatz**,
Artboards je Zustand, **Spezifikation** (Maße, Abstände, Flächen, Typo,
Tap-Ziele), **Motion**, **Stringtabelle** (`key | Deutsch | Englisch`,
Deutsch ist primär), **A11y-Notizen** (Element · Semantics-Label · Rolle ·
Zustand), **Wiederverwendung** und ein **Entscheidungsprotokoll** mit
Gewähltem und Verworfenem samt Begründung.

Zwei Fragen, die das Board beantworten soll und zu denen ich **keine**
Vorgabe mache:

1. Wie wird aus vier Arten ein Bildschirm, der nicht in vier Bildschirme
   zerfällt — und der Laufen, Radfahren und Schwimmen aufnimmt, ohne dass
   die Lösung kippt?
2. Wie sieht die obere Zusammenfassung aus, damit man in zwei Sekunden
   weiss, was diese Einheit war — ohne dass Farbe zur Bewertung wird?

**Gestalte deine eigene Lösung.** Ich habe bewusst keine Maße, keine
Reihenfolge und kein Layout vorgegeben. Was oben steht, ist das Problem und
die Grenzen — nicht der Entwurf.
