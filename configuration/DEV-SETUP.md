# 🛠️ Development Setup - Calisthenics Pro

## Überblick

Dieser Guide erklärt das lokale Development-Setup ohne npm und ohne Cache-Probleme.

## ⚠️ Wichtig: Keine Live Server Extension verwenden!

**Live Server verursacht Cache-Probleme** und sollte nicht verwendet werden. Stattdessen verwenden wir einen speziellen Python-basierten Dev-Server.

---

## 🚀 Lokaler Development Server starten

### Voraussetzung
- Python 3.x muss installiert sein (bereits auf den meisten Systemen vorhanden)

### Server starten

1. **VSCode Terminal öffnen** (`` Ctrl+` `` oder `Terminal > New Terminal`)

2. **Server starten** mit:
   ```bash
   python dev-server.py
   ```

3. **Browser öffnen** und navigiere zu:
   - `http://localhost:8080`

4. **Server stoppen** mit:
   - `Ctrl+C` im Terminal

---

## 🎯 Features des Dev-Servers

### ✅ No-Cache Headers
Der Server sendet für alle Dateien `Cache-Control: no-store` Header. Das bedeutet:
- **Änderungen sind sofort sichtbar** - kein Hard Reload nötig
- **Kein Browser-Caching** während der Entwicklung
- Einfach Speichern (Strg+S) und Browser-Refresh (F5)

### ✅ Service Worker disabled
Der Service Worker wird automatisch **nur auf localhost deaktiviert**:
- Keine Cache-Probleme während Development
- In Production (deployed) funktioniert der Service Worker normal
- Siehe [js/app.js:252-254](js/app.js#L252-L254) für die Implementation

### ✅ CORS enabled
- Cross-Origin-Requests funktionieren lokal
- Nützlich für externe APIs und Firebase

---

## 📋 Typischer Development Workflow

1. **Server starten**
   ```bash
   python dev-server.py
   ```

2. **Browser öffnen**
   - `http://localhost:8080`

3. **Code ändern**
   - Bearbeite HTML, CSS oder JS Dateien in VSCode
   - Speichere mit `Ctrl+S`

4. **Browser aktualisieren**
   - Drücke `F5` im Browser
   - Änderungen sind sofort sichtbar!

5. **Fertig entwickeln**
   - Drücke `Ctrl+C` im Terminal um Server zu stoppen

---

## 🔍 Debugging & Logs

### Normale Logs
Standardmäßig werden nur wichtige Requests geloggt (HTML, API calls).

### Verbose Logging
Für detaillierte Logs (inkl. CSS, JS, Bilder):
```bash
python dev-server.py --verbose
```

### Browser DevTools
- **F12** - DevTools öffnen
- **Console Tab** - Zeigt `🔧 Development mode: Service Worker registration skipped`
- **Network Tab** - Prüfe ob `Cache-Control: no-store` gesetzt ist
- **Application Tab** - Prüfe Service Worker Status (sollte leer sein)

---

## 🐛 Troubleshooting

### Port bereits belegt
**Fehler:** `OSError: Port 8080 is already in use`

**Lösung:**
1. Anderen Server stoppen, oder
2. Port in `dev-server.py` ändern (Zeile 13: `PORT = 8080`)

### Browser cached noch immer
Falls trotzdem Cache-Probleme auftreten:

1. **Hard Reload im Browser:**
   - `Ctrl+Shift+R` (Windows/Linux)
   - `Cmd+Shift+R` (Mac)

2. **Browser Cache komplett leeren:**
   - `F12` → `Application` Tab
   - Links: `Storage`
   - Button: `Clear site data`

3. **Service Worker deregistrieren (falls aktiv):**
   - `F12` → `Application` Tab
   - Links: `Service Workers`
   - Button: `Unregister` bei allen Workers

4. **Inkognito-Modus verwenden** (temporär):
   - `Ctrl+Shift+N` (Chrome)
   - `Ctrl+Shift+P` (Firefox)

---

## 📦 Production Build

### Service Worker aktiviert
In Production (nicht localhost) wird der Service Worker **automatisch aktiviert**:
- App funktioniert offline
- Assets werden gecached
- Schnellere Ladezeiten

### Deployment Checklist
- [ ] Code funktioniert lokal ohne Fehler
- [ ] Browser Console zeigt keine Fehler
- [ ] Alle Features getestet
- [ ] Firebase Config korrekt
- [ ] Deploy zu Hosting-Provider (z.B. Netlify, Vercel)
- [ ] Service Worker funktioniert (Check in deployed URL)

---

## 🔧 Technische Details

### Implementierung der localhost-Erkennung

**File:** [js/app.js:252-254](js/app.js#L252-L254)

```javascript
const isLocalhost = window.location.hostname === 'localhost' ||
                    window.location.hostname === '127.0.0.1' ||
                    window.location.hostname === '';
```

### Cache-Control Headers

**File:** [dev-server.py:29-32](dev-server.py#L29-L32)

```python
self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
self.send_header('Pragma', 'no-cache')
self.send_header('Expires', '0')
```

---

## 💡 Best Practices

### ✅ DO
- Server vor jeder Dev-Session starten
- Browser einfach mit F5 refreshen
- Console auf Fehler prüfen
- Code commits vor größeren Änderungen

### ❌ DON'T
- Live Server Extension verwenden
- Mehrere Server gleichzeitig laufen lassen
- Service Worker manuell registrieren auf localhost
- Browser-Cache in DevTools aktivieren

---

## 🆘 Support

Bei Problemen:
1. Console Logs prüfen (Browser & Terminal)
2. Service Worker Status prüfen (Browser DevTools → Application)
3. Port-Konflikte auflösen
4. Browser Cache leeren

---

**Happy Coding! 💪🔥**
