# Prompt für Claude Design — Modul 17: „Trainieren" und die Trennung der Themen

## Worum es geht

ATEM Hybrid ist eine private Android-App für hybrides Training (Kraft und
Ausdauer), Ästhetik „Dark Cyber-Athlete". Der **Kraft-Tab** ist seit Modul 13
eine einzige durchgehende Seite mit vier Themen: **Trainieren · Verlauf ·
Auswertung · Pläne**. Eine geheftete Zeile oben zeigt immer genau ein Wort —
das Thema, in dem man gerade steht — plus Zähler („1 / 4"), Chevron und vier
Fortschrittsmarken.

Zwei Dinge an dieser Seite stimmen nicht. Beide hängen zusammen, deshalb ein
Prompt.

## Problem 1 — „Trainieren" wirkt unfertig

Es ist das erste Thema und damit der erste Eindruck der App. Heute stehen dort
vier Dinge untereinander:

1. eine hervorgehobene Karte mit Gradient-Rand: „HEUTE GEPLANT", der Name der
   geplanten Einheit, ein Magenta-Knopf „Starten"
2. zwei halbbreite Karten nebeneinander: „Frei starten" und „Plan wählen",
   je mit Symbolkasten und Unterzeile
3. zwei schmucklose Zeilen mit Chevron: „Übungskatalog", „Einheit nachtragen"

Das ist eine Rangfolge nach Häufigkeit — die soll bleiben —, aber es sieht
aus wie drei zufällig übereinandergelegte Rezepte und nicht wie ein Anfang.

**Was der Bildschirm leisten muss:** In den ersten zwei Sekunden beantworten,
was man jetzt tun kann, und den häufigsten Weg ohne Nachdenken erreichbar
machen. Er ist der Ort, an dem ein Training beginnt — nicht der Ort, an dem
man etwas nachliest.

**Zwei Zustände, die es wirklich gibt und die beide gut aussehen müssen:**

- **Mit Plan für heute** (der Fall oben)
- **Ohne Plan für heute** — dann gibt es kein „Heute geplant". Was tritt an
  seine Stelle? Keine Platzhalterkarte, kein „Leg los!" (siehe *Haltung*).

Dazu die Pflichtzustände: **lädt** und **Fehler**.

## Problem 2 — die Themen trennen sich zu schwach

Zwischen zwei Themen liegt heute eine **Fuge**: eine Haarlinie über die ganze
Breite mit einem schwachen Schimmer im Bereichston (im Kraft-Tab Amber).
Nach dem letzten Thema steht eine Endfuge. Sie ist bewusst stumm gehalten —
den Wechsel sagt die Ortszeile oben an, nicht die Fuge.

**Am Gerät trennt sie zu wenig.** Man scrollt aus der Auswertung in die Pläne,
ohne zu merken, dass ein neues Thema begonnen hat.

Eine Idee war, **jedem Thema einen eigenen Hintergrund** zu geben. Sie steht
zur Diskussion, ist aber nicht gesetzt — und sie kollidiert mit zwei festen
Regeln (siehe unten). Wenn es eine bessere Antwort gibt, ist sie willkommen.

**Die Frage lautet:** Woran merkt man beim Scrollen, dass ein Thema zu Ende ist
und das nächste beginnt — ohne dass die Seite in vier Bildschirme zerfällt und
ohne eine neue Farbebene?

## Nicht verhandelbar

- Nur die Farbtokens aus `atem_theme.dart` / README §3. **Keine erfundenen
  Zwischentöne, keine vierte Farbebene.** Es gibt genau drei Flächen: den
  Grund `#050507`, die Karte `#14141D`, die angehobene Fläche `#1A1A26` — dazu
  `#0B0B0E` für deckende Kästen. Wer Hintergründe je Thema vorschlägt, muss
  sagen, aus welchen dieser Werte sie kommen.
- **Cyan trägt Handlung**, global reserviert: Wer Cyan sieht, kann tippen.
  **Der Bereichston trägt den Ort** — im Kraft-Tab Amber `#FFB020`, wie der
  Nav-Punkt. Amber ist nie ein Versprechen auf eine Handlung.
  **Violett `#7A2BDB` ist nur Fläche, nie Text.** Magenta ist Marke und
  Eingriff (der eine Haupt-CTA, Löschen, Störung).
- `#94A3B8` ist die dunkelste erlaubte Textfarbe. Informationstragender Text
  ≥ 12 sp, Kontrast ≥ 4,5:1.
- Farbe ist nie der einzige Statusträger — immer Wort, Glyph oder Icon daneben.
- Jedes Tap-Ziel ≥ 48 dp. Kein Material-Ripple: gedrückt = `scale 0.97` +
  Akzent-Glow, 200 ms.
- Muss bei **200 % Systemschrift auf 320 dp Breite** ohne Überlauf
  funktionieren. Kein Verkleinern von Text, kein horizontales Scrollen.
- **Höchstens ein `BackdropFilter` pro scrollendem Screen.** Die Seite scrollt
  über alle vier Themen — ein Blur je Thema gibt es nicht.
- **Genau eine Karte mit Gradient-Rand je Bildschirm.** Zwei nehmen sich
  gegenseitig die Wirkung. Heute trägt sie der geplante Weg.

## Was die Seite schon hat und was bleibt

- **Die Ortszeile** (Modul 13) bleibt unverändert: ein Wort, Zähler, Chevron,
  vier Marken. Sie blendet nie aus und ist zugleich die Überschrift — **kein
  Thema trägt seinen Namen ein zweites Mal im Inhalt.**
- **Ein Ladegate je Seite**, nicht eines je Thema. Leere Themen bleiben stehen.
- **Die Eintrittskaskade** läuft, wenn ein Block 25 % der Viewporthöhe kreuzt.
- Die Rangfolge in „Trainieren" nach **Häufigkeit**: die hervorgehobene Karte
  ist der Weg, den die Seite verkauft; Halbkarten sind die regelmässigen
  Alternativen; Zeilen mit Chevron sind Unterseiten und Seltenes.

## Haltung

- **Ein Block ohne Daten rendert nicht** — der Bildschirm hört einfach früher
  auf. Keine Platzhalterkarte, kein Aufruf („Leg los!"), kein leerer Zustand,
  der so tut, als fehle dem Nutzer etwas. (Auf Auswertungsbildschirmen gilt
  eine andere Regel, hier nicht.)
- **Kein Urteil, kein Sollwert.** Die App sagt nicht, dass heute Training
  anstünde.
- **Jede Zahl nennt ihre Grundlage.** Nie ein Anteil ohne Nenner.
- **Drei Textstufen:** Weiss für Titel und die Hauptzahl · `#CDD3EA` für
  Sätze, die gelesen werden · `#94A3B8` für Metazeilen und Beschriftungen.

## Was ich von dir brauche

Ein Spezifikations-Board im Format der Module 1–16: **Leitsatz**, Artboards je
Zustand, **Spezifikation** (Maße, Abstände, Flächen, Typo, Tap-Ziele),
**Motion**, **Stringtabelle** (`key | Deutsch | Englisch`, Deutsch ist primär),
**A11y-Notizen** (Element · Semantics-Label · Rolle · Zustand),
**Wiederverwendung** und ein **Entscheidungsprotokoll** mit Gewähltem und
Verworfenem samt Begründung.

Zwei Fragen, zu denen ich **keine** Vorgabe mache:

1. Wie sieht „Trainieren" aus, damit es in zwei Sekunden sagt, was jetzt geht —
   mit und ohne Plan für heute, ohne dass der Fall ohne Plan wie ein Mangel
   wirkt?
2. Woran merkt man beim Scrollen den Themenwechsel? Wenn die Antwort
   Hintergründe je Thema sind: aus welchen vorhandenen Flächen, und wie bleibt
   die Seite dabei **eine** Seite? Wenn es eine bessere Antwort gibt — Raum,
   Rhythmus, Grösse, etwas an der Fuge selbst —, dann diese.

**Gestalte deine eigene Lösung.** Ich habe bewusst keine Maße, keine
Reihenfolge und kein Layout vorgegeben. Was oben steht, ist das Problem und
die Grenzen — nicht der Entwurf.
