# Modul 9 — Tiefe statt Fläche

Anlass: Rückmeldung nach dem ersten vollständigen Durchlauf auf dem Gerät —
„wirkt leer und wenig aussagend". Die Leiste ist daraufhin von fünf auf drei
Plätze gekürzt (zwei führten auf „Kommt noch"). Dieses Modul beantwortet die
zweite Hälfte: Die drei verbliebenen Bildschirme sollen mehr sagen.

## Umgesetzt am 28.08.2026

Gebaut gegen `design_refs/09_Aussagekraft.dc.html`.

### Die drei offenen Punkte aus Sektion K

**Überdeckungsschwelle Stufe B** — bleibt bei 60 % Jaccard über `exerciseId`,
als **eine** Konstante in `ComparisonResolver.overlapThreshold`. Nach einer
Woche Produktivbetrieb an der Verteilung nachzuziehen; sie steht deshalb an
einer Stelle und nicht verstreut.

**Muskelzuordnung bei Mehrfachnennung** — volle Zählung je genannter Gruppe.
Ein Satz Bankdrücken ist ein Satz Brust *und* ein Satz Trizeps, nicht 0,5 und
0,5. Die Summe übersteigt damit die absolvierten Sätze; die Grundlagenzeile
sagt deshalb „Sätze", nicht „Summe".

**Bestwert-Kriterium** — bestes Satzgewicht, wie im Runner. Bei
Körpergewichtsübungen ohne Zusatzlast tritt die Wiederholungszahl an seine
Stelle; was gemessen wird, steht im Untertitel der Kachel.

### Eine Abweichung

Die Legende der Verlaufskurve steht **unter** den beiden Datumsangaben, nicht
zwischen ihnen. „Ring markiert den Bestwert" ist bei 320 dp breiter als der
Platz zwischen zwei Datumsangaben — die Prüfmatrix fand 315 px Überlauf.
