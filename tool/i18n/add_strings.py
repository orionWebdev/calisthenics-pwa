#!/usr/bin/env python3
"""Trägt Zeichenketten in `app_de.arb` und `app_en.arb` ein.

Warum es dieses Skript gibt: Die ARB-Dateien sind über 9.000 Zeilen lang, und
ein Schlüssel gehört **immer** in beide. Von Hand eingetragen fehlt er nach
kurzer Zeit in einer der beiden Sprachen — oder steht zweimal drin.

Aufruf (aus dem Repo-Wurzelverzeichnis):

    python3 tool/i18n/add_strings.py neue_strings.json
    flutter gen-l10n

Eingabe ist eine JSON-Datei:

    {
      "weightBlockTitle": {
        "de": "Gewicht",
        "en": "Weight",
        "description": "Board 14 · weight.title"
      },
      "weightEntries": {
        "de": "{n, plural, one{1 Eintrag} other{{n} Einträge}}",
        "en": "{n, plural, one{1 entry} other{{n} entries}}",
        "description": "Board 14 · A1",
        "placeholders": {"n": {"type": "int"}}
      }
    }

Zwei Dinge, an denen es absichtlich abbricht statt stillschweigend etwas zu
tun: ein Schlüssel, den es schon gibt, und ein einfaches Anführungszeichen im
Text. `l10n.yaml` setzt `use-escaping: true` — ein `'` muss dort als `''`
stehen, sonst bricht `flutter gen-l10n` mit einem ICU-Lexing-Fehler ab, der
nicht nach seiner Ursache aussieht.
"""

import collections
import json
import sys

ARB_DIR = 'lib/l10n/arb'


def load(path):
    with open(path, encoding='utf-8') as f:
        return json.load(f, object_pairs_hook=collections.OrderedDict)


def check_quotes(spec):
    """`use-escaping: true` verlangt `''` statt `'`."""
    bad = []
    for key, value in spec.items():
        for lang in ('de', 'en'):
            text = value.get(lang, '')
            stripped = text.replace("''", '')
            if "'" in stripped:
                bad.append(f'{key}.{lang}: {text}')
    if bad:
        sys.exit(
            'Einfaches Anführungszeichen — bei use-escaping muss es \'\' '
            'heissen:\n  ' + '\n  '.join(bad)
        )


def main():
    if len(sys.argv) != 2:
        sys.exit(f'Aufruf: {sys.argv[0]} <strings.json>')

    spec = load(sys.argv[1])
    de, en = load(f'{ARB_DIR}/app_de.arb'), load(f'{ARB_DIR}/app_en.arb')

    clash = [key for key in spec if key in de or key in en]
    if clash:
        sys.exit('Schlüssel existiert bereits: ' + ', '.join(clash))

    missing = [
        key for key, value in spec.items()
        if not value.get('de') or not value.get('en')
    ]
    if missing:
        sys.exit('Deutsch und Englisch sind Pflicht, fehlt bei: '
                 + ', '.join(missing))

    check_quotes(spec)

    for key, value in spec.items():
        meta = collections.OrderedDict()
        meta['description'] = value.get('description', key)
        if 'placeholders' in value:
            meta['placeholders'] = value['placeholders']
        de[key], de['@' + key] = value['de'], meta
        en[key], en['@' + key] = value['en'], meta

    for path, data in ((f'{ARB_DIR}/app_de.arb', de),
                       (f'{ARB_DIR}/app_en.arb', en)):
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write('\n')

    print(f'{len(spec)} Schlüssel in beide Dateien geschrieben. '
          'Jetzt `flutter gen-l10n`.')


if __name__ == '__main__':
    main()
