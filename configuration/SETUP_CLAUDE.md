# VSCode Claude Extension - Setup Guide

## 🎯 Ziel

Claude Desktop App in VSCode integrieren, sodass Claude Zugriff auf dein Projekt hat und den Kontext aus unseren Chats kennt.

---

## 📋 Voraussetzungen

- Windows 11 (oder 10)
- VSCode installiert
- Node.js installiert (für Claude Desktop)
- PowerShell 7+ (optional, aber empfohlen)

---

## 🚀 Schritt 1: Claude Desktop App installieren

### Download
1. Geh zu: https://claude.ai/download
2. Download für Windows
3. Installiere die App

### Erste Einrichtung
1. Öffne Claude Desktop
2. Login mit deinem Anthropic-Account
3. **Wichtig:** Das ist NICHT automatisch mit claude.ai Web verbunden!

---

## 📁 Schritt 2: Projekt-Kontext-Dateien erstellen

Erstelle diese 3 Dateien im **Root** deines Projekts:

```
calisthenics-pro/
├── PROJECT_CONTEXT.md      ← Projekt-Übersicht
├── CLAUDE_INSTRUCTIONS.md  ← Anweisungen für Claude
├── SETUP.md               ← Diese Datei
├── index.html
├── css/
└── js/
```

### Inhalt der Dateien
Siehe die Artifacts - kopiere den Inhalt rein!

---

## 🔧 Schritt 3: Claude Desktop MCP aktivieren

### Was ist MCP?
**Model Context Protocol** - ermöglicht Claude Zugriff auf lokale Dateien.

### Aktivierung:
1. Öffne Claude Desktop
2. Geh zu **Settings** (⚙️ unten links)
3. Navigiere zu **Developer**
4. Schalte **"Enable MCP"** ein
5. Restart Claude Desktop

---

## 💻 Schritt 4: VSCode Integration (Optional)

### Option A: Claude Desktop parallel zu VSCode
- Einfachste Lösung
- Claude Desktop läuft nebenbei
- Du kopierst Code zwischen VSCode ↔ Claude

### Option B: Cline Extension (empfohlen)
Cline ist eine VSCode Extension die Claude integriert.

**Installation:**
1. Öffne VSCode
2. Extensions (Ctrl+Shift+X)
3. Suche nach **"Cline"**
4. Installiere
5. API Key eingeben (aus claude.ai Account)

**Vorteil:**
- Claude direkt in VSCode
- Kann Dateien direkt editieren
- Terminal-Zugriff

---

## 📝 Schritt 5: Claude den Kontext geben

### Beim ersten Start in Claude Desktop:

```
Hey Claude! Ich arbeite an einem Calisthenics-App-Projekt.

Bitte lies folgende Dateien um den Kontext zu verstehen:
1. PROJECT_CONTEXT.md
2. CLAUDE_INSTRUCTIONS.md

Danach können wir loslegen!
```

### Claude wird antworten:
"Ich habe die Dateien gelesen und verstehe jetzt:
- Dein Projekt-Setup
- Die Tech-Stack-Entscheidungen
- Was bereits implementiert ist
- Wie ich dir helfen soll"

---

## 🎯 Schritt 6: Workflow testen

### Test 1: Datei-Zugriff
```
Claude, zeige mir den Inhalt von js/exercises.js
```

Claude sollte die Datei lesen können.

### Test 2: Code-Änderung
```
Claude, füge eine Funktion hinzu die alle Übungen 
nach Name sortiert in js/exercises.js
```

Claude sollte die Funktion schreiben UND erklären.

### Test 3: Kontext-Verständnis
```
Claude, wir haben doch die Regel "Multi-User-ready" - 
gilt das auch für neue Features?
```

Claude sollte mit "Ja, alle neuen Features müssen userId berücksichtigen" antworten.

---

## 💡 Best Practices

### DO's ✅

**Bei neuen Sessions:**
```
Claude, ich arbeite weiter am Calisthenics-Projekt.
Bitte lies PROJECT_CONTEXT.md für Kontext.
```

**Bei Fragen:**
```
Claude, kannst du mir erklären wie die Firebase-Integration 
in js/firebase.js funktioniert?
```

**Bei Features:**
```
Claude, ich möchte Feature X hinzufügen.
Lies bitte die relevanten Dateien und schlage eine Lösung vor.
```

### DON'Ts ❌

**Nicht:**
```
Claude, schreib mir eine komplette React-App
```
(Wir nutzen Vanilla JS!)

**Nicht:**
```
Claude, bau alles neu
```
(Iterativ arbeiten!)

**Nicht:**
```
Fix this [ohne Kontext]
```
(Immer Kontext geben: "In js/exercises.js gibt es Fehler X...")

---

## 🔄 Kontext aktuell halten

### Wenn du große Änderungen machst:

**Update PROJECT_CONTEXT.md:**
```markdown
## 📋 Features - Aktueller Stand

### ✅ Neu implementiert (Januar 2026)
- Trainingspläne erstellen
- Plan-Scheduling im Kalender
```

**Sage Claude:**
```
Claude, ich habe PROJECT_CONTEXT.md aktualisiert.
Bitte lies die neuen Änderungen.
```

---

## 🐛 Troubleshooting

### Claude kann Dateien nicht lesen
**Problem:** MCP nicht aktiviert  
**Lösung:** Settings → Developer → Enable MCP → Restart

### Claude kennt Kontext nicht
**Problem:** Dateien nicht gelesen  
**Lösung:** 
```
Claude, lies bitte PROJECT_CONTEXT.md und CLAUDE_INSTRUCTIONS.md
```

### Claude antwortet auf Englisch
**Problem:** Hat CLAUDE_INSTRUCTIONS.md nicht gelesen  
**Lösung:**
```
Claude, bitte lies CLAUDE_INSTRUCTIONS.md - 
du sollst immer auf Deutsch antworten!
```

### Code funktioniert nicht
**Problem:** Claude hat alten Stand  
**Lösung:**
```
Claude, hier ist der aktuelle Code aus [Datei]:
[Code einfügen]

Das Problem ist: [Beschreibung]
```

---

## 📊 Vergleich: Web vs. Desktop

| Feature | claude.ai Web | Claude Desktop |
|---------|---------------|----------------|
| **Chat-History** | ✅ Permanent | ❌ Separate Sessions |
| **Datei-Zugriff** | ❌ | ✅ Alle Projekt-Dateien |
| **Code direkt editieren** | ❌ | ✅ Mit MCP |
| **Copy-Paste** | ✅ Nötig | ✅ Optional |
| **Kontext geben** | ✅ Manuell | ✅ Via Dateien |

---

## 🎯 Empfohlener Workflow

### Für größere Features:
1. **Planung in claude.ai Web** (hier haben wir die History!)
2. **Implementierung in Claude Desktop** (direkter Datei-Zugriff)
3. **Testing selbst in VSCode**
4. **Feedback zurück an Claude Desktop**

### Für schnelle Fixes:
- Direkt in Claude Desktop
- Claude liest Datei → Schlägt Fix vor → Du testest

### Für Lern-Fragen:
- claude.ai Web (unsere History bleibt erhalten)
- Oder Claude Desktop mit Kontext-Dateien

---

## 🚀 Los geht's!

**Dein erster Befehl in Claude Desktop:**

```
Hi Claude! 👋

Ich bin [dein Name] und arbeite am Calisthenics Pro Projekt.

Bitte lies diese Dateien:
1. PROJECT_CONTEXT.md - Projekt-Übersicht
2. CLAUDE_INSTRUCTIONS.md - Wie du mir helfen sollst

Danach lass mich wissen ob du alles verstanden hast 
und ob du Fragen hast!

Los geht's! 🚀
```

---

## 📞 Support

**Bei Problemen:**
1. Check CLAUDE_INSTRUCTIONS.md - steht da was hilfreiches?
2. Frag Claude Desktop: "Was brauchst du noch für Kontext?"
3. Falls gar nichts geht → claude.ai Web (unsere History ist da!)

**Bei großen Änderungen:**
- Update PROJECT_CONTEXT.md
- Sage Claude er soll es neu lesen

---

**Viel Erfolg! 💪**