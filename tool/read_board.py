#!/usr/bin/env python3
"""Liest ein Spezifikations-Board aus `design_handoff_atem_app/design_refs`.

Die `.dc.html`-Dateien sind Vorlagen: Das Markup enthält `<sc-for>`-Schleifen,
die Daten stehen als JavaScript-Objektliteral im selben Dokument. Wer nur den
Text herausschneidet, bekommt `{{ s.de }}` statt der Zeichenkette.

Dieses Werkzeug zieht beides heraus — die Fliesstexte und die Datenlisten — und
gibt sie als lesbaren Text aus. Es interpretiert nichts; es macht die Boards nur
ohne Browser lesbar.

    python3 tool/read_board.py 09              # alles
    python3 tool/read_board.py 09 --list       # nur die Datenlisten
    python3 tool/read_board.py 09 strings a11y # ausgewählte Listen
"""
import html
import re
import sys
from pathlib import Path

REFS = Path('design_handoff_atem_app/design_refs')


def find(name: str) -> Path:
    matches = sorted(REFS.glob(f'{name}*.dc.html'))
    if not matches:
        matches = sorted(p for p in REFS.glob('*.dc.html')
                         if name.lower() in p.name.lower())
    if not matches:
        raise SystemExit(f'Kein Board zu „{name}" in {REFS}')
    return matches[0]


def unescape(text: str) -> str:
    return html.unescape(re.sub(r'\s+', ' ', text)).strip()


def lists(source: str) -> dict[str, list[dict[str, str]]]:
    """Jede `name: bb([ {...}, ... ])`-Liste als Folge von Feld-Wert-Paaren."""
    found = {}
    # Zwei Schreibweisen im selben Dokument: `name: bb([ … ])` und `name: [ … ]`.
    # Wer nur die erste kennt, verliert A11y-Notizen und Entscheidungsprotokoll.
    for match in re.finditer(r'(\w+):\s*(?:bb\()?\[', source):
        name = match.group(1)
        start = match.end()
        depth = 1
        i = start
        while i < len(source) and depth:
            if source[i] == '[':
                depth += 1
            elif source[i] == ']':
                depth -= 1
            i += 1
        block = source[start:i - 1]

        entries = [
            _fields(raw) for raw in _objects(block)
        ]
        entries = [e for e in entries if e]
        if entries:
            found[name] = entries
    return found


def _objects(block: str) -> list[str]:
    """Die obersten `{...}`-Objekte einer Liste.

    Klammern in Zeichenketten zählen nicht mit — sonst zerbricht jeder
    Platzhalter wie `{n}` die Zählung, und zwei Drittel der Einträge fallen
    stillschweigend weg. Genau das ist beim ersten Anlauf passiert.
    """
    out = []
    depth = 0
    quote = None
    start = 0
    i = 0
    while i < len(block):
        ch = block[i]
        if quote:
            if ch == '\\':
                i += 2
                continue
            if ch == quote:
                quote = None
        elif ch in "'\"":
            quote = ch
        elif ch == '{':
            if depth == 0:
                start = i
            depth += 1
        elif ch == '}':
            depth -= 1
            if depth == 0:
                out.append(block[start + 1:i])
        i += 1
    return out


def _fields(raw: str) -> dict[str, str]:
    fields = {}
    for field in re.finditer(r"(\w+):\s*'((?:[^'\\]|\\.)*)'", raw):
        value = field.group(2).replace("\\'", "'").replace('\\n', ' ')
        fields[field.group(1)] = unescape(value)
    return fields


def prose(source: str) -> list[str]:
    """Sichtbarer Text ausserhalb der Vorlagen — Leitsatz, Absätze, Marker."""
    body = re.sub(r'<script.*?</script>', '', source, flags=re.S)
    body = re.sub(r'<style.*?</style>', '', body, flags=re.S)
    out = []
    for chunk in re.split(r'</?(?:div|p|h[1-6]|li|section)[^>]*>', body):
        text = unescape(re.sub(r'<[^>]+>', ' ', chunk))
        # Vorlagenplatzhalter tragen keine Information.
        if not text or '{{' in text or len(text) < 3:
            continue
        if text not in out:
            out.append(text)
    return out


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)

    args = sys.argv[1:]
    only_lists = '--list' in args
    args = [a for a in args if not a.startswith('--')]
    path = find(args[0])
    wanted = [a.lower() for a in args[1:]]

    source = path.read_text(encoding='utf-8')
    print(f'# {path.name}\n')

    if not only_lists and not wanted:
        print('## Fliesstext\n')
        for line in prose(source):
            print(line)
        print()

    print('## Datenlisten\n')
    for name, entries in lists(source).items():
        if wanted and not any(w in name.lower() for w in wanted):
            continue
        print(f'### {name} ({len(entries)})\n')
        for entry in entries:
            print('  ' + ' | '.join(f'{k}={v}' for k, v in entry.items()))
        print()


if __name__ == '__main__':
    main()
