#!/usr/bin/env python3
"""Liest den kompletten Firestore-Bestand in lokale JSON-Dateien.

Der Ersatz für `gcloud firestore export`, der auf dem Spark-Tarif nicht zur
Verfügung steht: Er schreibt in einen Cloud-Storage-Bucket, und Spark stellt
keinen bereit. Dieses Skript liest ausschließlich — es schreibt nichts nach
Firestore — und braucht nur ein Zugriffstoken aus `gcloud auth print-access-token`.

Aufruf:
    gcloud auth print-access-token | python3 tool/firestore_dump.py <zielordner>

Es folgt Untersammlungen eine Ebene tief. Tiefer geht die PWA nicht: Ihre
Dokumente sind flach und tragen die Zugehörigkeit als Feld `userId`.
"""

import json
import os
import sys
import urllib.error
import urllib.request

PROJECT = "calisthenics-pro-57d6d"
ROOT = "https://firestore.googleapis.com/v1"
BASE = f"{ROOT}/projects/{PROJECT}/databases/(default)/documents"
PAGE_SIZE = 300


def call(token, url, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    request = urllib.request.Request(
        url,
        data=data,
        method="POST" if data is not None else "GET",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request) as response:
            return json.loads(response.read())
    except urllib.error.HTTPError as error:
        body = error.read().decode()[:400]
        raise SystemExit(f"HTTP {error.code} bei {url}\n{body}")


def collection_ids(token, parent):
    ids, page = [], None
    while True:
        payload = {"pageSize": 100}
        if page:
            payload["pageToken"] = page
        result = call(token, f"{parent}:listCollectionIds", payload)
        ids.extend(result.get("collectionIds", []))
        page = result.get("nextPageToken")
        if not page:
            return ids


def documents(token, parent, collection):
    docs, page = [], None
    while True:
        url = f"{parent}/{collection}?pageSize={PAGE_SIZE}"
        if page:
            url += f"&pageToken={page}"
        result = call(token, url)
        docs.extend(result.get("documents", []))
        page = result.get("nextPageToken")
        if not page:
            return docs


def main():
    token = sys.stdin.read().strip()
    if not token:
        raise SystemExit("Kein Token auf stdin.")

    target = sys.argv[1] if len(sys.argv) > 1 else "firestore-dump"
    os.makedirs(target, exist_ok=True)

    total = 0
    report = {}

    for collection in sorted(collection_ids(token, BASE)):
        docs = documents(token, BASE, collection)
        total += len(docs)

        # Untersammlungen eine Ebene tief — sonst fehlten sie stillschweigend
        # in einer Sicherung, die vorgibt, vollständig zu sein.
        nested = {}
        for doc in docs:
            # `name` kommt als Ressourcenpfad zurück, nicht als URL.
            name = f"{ROOT}/{doc['name']}"
            for sub in collection_ids(token, name):
                sub_docs = documents(token, name, sub)
                if sub_docs:
                    key = doc["name"].rsplit("/", 1)[-1]
                    nested.setdefault(key, {})[sub] = sub_docs
                    total += len(sub_docs)

        path = os.path.join(target, f"{collection}.json")
        with open(path, "w") as handle:
            json.dump(
                {"collection": collection, "documents": docs, "subcollections": nested},
                handle,
                indent=1,
                ensure_ascii=False,
            )

        sub_count = sum(len(v) for d in nested.values() for v in d.values())
        report[collection] = (len(docs), sub_count)
        print(f"{collection:22} {len(docs):5} Dokumente"
              + (f"  (+{sub_count} in Untersammlungen)" if sub_count else ""))

    print(f"\n{total} Dokumente insgesamt nach {target}/")
    with open(os.path.join(target, "_bericht.json"), "w") as handle:
        json.dump({"project": PROJECT, "total": total, "collections": report}, handle, indent=1)


if __name__ == "__main__":
    main()
