#!/usr/bin/env python3
"""Destilliert aus der Firestore-Sicherung einen Prüfbestand ohne echte Werte.

Der Deserialisierer muss jede Feld-Typ-Kombination verkraften, die im
Produktivbestand tatsächlich vorkommt — `duration` als integer *und* als double,
`notes` als string *und* als null *und* gar nicht. Ein Test dagegen braucht
diese **Formen**, nicht die Werte.

Das Skript sammelt alle unterschiedlichen Formen und schreibt je Form ein
synthetisches Dokument mit Platzhalterwerten des jeweiligen Typs. Ergebnis ist
eine Datei, die ins Repository darf: Sie enthält keine Trainingsdaten, keine
Zeitpunkte und keine Kennungen — nur die Struktur.

    python3 tool/session_shapes.py ~/atem-firestore-sicherung-<datum> \
        test/fixtures/session_shapes.json
"""

import json
import sys

# Platzhalter je Firestore-Typ, in der Form, die das **Dart-SDK** liefert —
# nicht in der REST-Kodierung der Sicherung. Die REST-Schnittstelle schickt
# Ganzzahlen als Zeichenkette ("7"), das SDK als int. Ein Prüfbestand in
# REST-Form würde am Mapper vorbeitesten.
#
# Zeitstempel werden als {"__ts__": ...} markiert; der Test macht daraus einen
# echten `Timestamp`. JSON kennt den Typ nicht.
PLACEHOLDER = {
    "stringValue": "x",
    "integerValue": 7,
    "doubleValue": 1.5,
    "booleanValue": True,
    "nullValue": None,
    "timestampValue": {"__ts__": "2026-01-15T09:00:00Z"},
}


# Felder, deren Wert die Verzweigung steuert. Sie behalten ihren echten Inhalt:
# Es sind Aufzählungen, keine personenbezogenen Daten, und mit `type: "x"` in
# jeder Form würde der Test die Fallunterscheidung gar nicht erreichen.
CATEGORICAL = {"type", "activityType", "difficulty", "discipline"}


def type_of(value):
    return next(iter(value))


def shape(fields):
    """Form eines Dokuments: Feldname -> Typ, Arrays mit den Formen ihrer Einträge."""
    out = {}
    for key, value in sorted(fields.items()):
        kind = type_of(value)
        if kind == "arrayValue":
            inner = value["arrayValue"].get("values", [])
            out[key] = ("array", tuple(
                sorted({json.dumps(shape(v.get("mapValue", {}).get("fields", {})),
                                   sort_keys=True)
                        for v in inner if "mapValue" in v})
            ))
        elif kind == "mapValue":
            out[key] = ("map", json.dumps(shape(value["mapValue"].get("fields", {})),
                                          sort_keys=True))
        elif key in CATEGORICAL and kind == "stringValue":
            out[key] = ("literal", value["stringValue"])
        else:
            out[key] = kind
    return out


def synth(form):
    """Baut aus einer Form ein Dokument mit Platzhalterwerten."""
    doc = {}
    for key, kind in form.items():
        if isinstance(kind, (list, tuple)) and kind[0] == "array":
            doc[key] = [synth(json.loads(s)) for s in kind[1]]
        elif isinstance(kind, (list, tuple)) and kind[0] == "map":
            doc[key] = synth(json.loads(kind[1]))
        elif isinstance(kind, (list, tuple)) and kind[0] == "literal":
            doc[key] = kind[1]
        else:
            doc[key] = PLACEHOLDER[kind]
    return doc


def main():
    source, target = sys.argv[1], sys.argv[2]
    docs = json.load(open(f"{source}/sessions.json"))["documents"]

    seen, shapes = set(), []
    for doc in docs:
        form = shape(doc.get("fields", {}))
        key = json.dumps(form, sort_keys=True)
        if key not in seen:
            seen.add(key)
            shapes.append(form)

    # Nach Feldzahl sortieren: Die kargen Dokumente zuerst, sie sind die
    # härteren Fälle für einen Deserialisierer.
    shapes.sort(key=lambda f: (len(f), sorted(f)))
    out = [synth(f) for f in shapes]

    with open(target, "w") as handle:
        json.dump(out, handle, indent=1, ensure_ascii=False, sort_keys=True)

    print(f"{len(docs)} Dokumente -> {len(out)} unterschiedliche Formen -> {target}")

    fields = {}
    for form in shapes:
        for key, kind in form.items():
            fields.setdefault(key, set()).add(kind if isinstance(kind, str) else kind[0])
    mehrdeutig = {k: v for k, v in fields.items() if len(v) > 1}
    print(f"{len(fields)} Feldnamen, davon {len(mehrdeutig)} mit mehr als einem Typ:")
    for k, v in sorted(mehrdeutig.items()):
        print(f"  {k}: {', '.join(sorted(x.replace('Value', '') for x in v))}")


if __name__ == "__main__":
    main()
