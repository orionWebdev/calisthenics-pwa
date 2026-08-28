#!/usr/bin/env python3
"""Überträgt die Stringtabelle eines Boards in die ARB-Dateien.

## Warum die Schlüssel umgeschrieben werden

Die Boards benutzen Punktpfade (`exercise.field.name`). Flutter erzeugt aus
jedem ARB-Schlüssel einen Dart-Getter — ein Punkt darin ist kein gültiger
Bezeichner. Der Punktpfad bleibt deshalb die **Identität** des Strings und
steht in der Beschreibung; der ARB-Schlüssel ist seine lowerCamelCase-Form.
Die Abbildung ist umkehrbar und in `docs/contracts/02-i18n.md` festgehalten.

## Was mit Platzhaltern passiert

`{n}`, `{date}`, `{name}` werden erkannt und deklariert. Zahlen heissen `n`,
`c`, `a`, `p`, `s`, `min`, `rest`, `alt`, `neu` — alles andere gilt als Text.
ICU-Pluralformen (`{p, plural, one {…} other {…}}`) bleiben unverändert
stehen; ihre Variable wird als Zahl deklariert.

    python3 tool/board_strings.py 07            # zeigt nur an
    python3 tool/board_strings.py 07 --write    # schreibt
"""
import collections
import json
import re
import subprocess
import sys

DE = 'lib/l10n/arb/app_de.arb'
EN = 'lib/l10n/arb/app_en.arb'

# Platzhalter, die eine Zahl tragen. Alles andere ist Text.
NUMERIC = {'n', 'c', 'a', 'p', 's', 'min', 'rest', 'total', 'sets', 'count'}


def camel(key: str) -> str:
    parts = [p for p in re.split(r'[._-]', key) if p]
    return parts[0] + ''.join(p[:1].upper() + p[1:] for p in parts[1:])


def placeholders(text: str) -> dict:
    found = {}
    # ICU-Plural: {p, plural, one {…} other {…}} — die Variable ist eine Zahl.
    for name in re.findall(r'\{(\w+),\s*plural', text):
        found[name] = {'type': 'int'}
    # Einfache Platzhalter, aber nicht die `#` innerhalb einer Pluralform.
    for name in re.findall(r'\{(\w+)\}', text):
        if name in found:
            continue
        found[name] = {'type': 'int'} if name in NUMERIC else {'type': 'String'}
    return found


def align(german: str, english: str) -> str:
    """Gleicht die Platzhalternamen der englischen Fassung an die deutsche an.

    Die Boards benennen sie sprachlich — Deutsch `{alt}`/`{neu}`, Englisch
    `{old}`/`{new}`. Für Flutter sind Platzhalter aber **Bezeichner**, keine
    Wörter: Sie müssen über alle Sprachen gleich heissen, sonst entstehen
    Methoden mit unterschiedlichen Parametern. Und `new` ist obendrein ein
    Dart-Schlüsselwort.

    Deutsch ist die Vorlagensprache, also gewinnt Deutsch. Ersetzt wird nach
    Position — die Reihenfolge der Platzhalter ist in beiden Fassungen
    dieselbe, weil sie derselben Aussage folgen.
    """
    names_de = re.findall(r'\{(\w+)[,}]', german)
    names_en = re.findall(r'\{(\w+)[,}]', english)
    if names_de == names_en or len(names_de) != len(names_en):
        return english
    out = english
    for old, new in zip(names_en, names_de):
        if old == new:
            continue
        out = re.sub(r'\{' + old + r'([,}])', '{' + new + r'\1', out)
        # `#` in Pluralformen bleibt unberührt — es bezieht sich implizit.
    return out


def board(number: str) -> list[tuple[str, str, str]]:
    out = subprocess.run(
        ['python3', 'tool/read_board.py', number, '--list', 'string'],
        capture_output=True, text=True, check=True).stdout
    rows = []
    for line in out.splitlines():
        m = re.match(r'^  k=([\w.]+) \| de=(.*?) \| en=(.*)$', line)
        if m:
            rows.append(m.groups())
    return rows


def sorted_arb(data: dict) -> collections.OrderedDict:
    ordered = collections.OrderedDict()
    for key in sorted(k for k in data if not k.startswith('@')):
        ordered[key] = data[key]
        if '@' + key in data:
            ordered['@' + key] = data['@' + key]
    return ordered


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    number = sys.argv[1]
    write = '--write' in sys.argv

    rows = board(number)
    de = json.load(open(DE))
    en = json.load(open(EN))

    added = updated = same = 0
    for dotted, german, english in rows:
        key = camel(dotted)
        meta = {'description': dotted}
        ph = placeholders(german)
        if ph:
            meta['placeholders'] = ph

        if key not in de:
            added += 1
        elif de[key] != german:
            updated += 1
            print(f'  ~ {key}\n      alt: {de[key]}\n      neu: {german}')
        else:
            same += 1

        de[key] = german
        de['@' + key] = meta
        en[key] = align(german, english)
        en['@' + key] = meta

    print(f'\nBoard {number}: {len(rows)} Strings — '
          f'{added} neu, {updated} ersetzt, {same} unverändert')

    if not write:
        print('(Probelauf — mit --write schreiben)')
        return

    for path, data in ((DE, de), (EN, en)):
        with open(path, 'w') as handle:
            json.dump(sorted_arb(data), handle, ensure_ascii=False, indent=2)
            handle.write('\n')
    print('geschrieben')


if __name__ == '__main__':
    main()
