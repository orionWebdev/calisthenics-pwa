# Firebase Authentication & Allowlist Setup

Dieses Dokument beschreibt, wie du Firebase Authentication mit Google Sign-In und das Allowlist-System einrichtest.

## 📋 Übersicht

Die App verwendet ein **Allowlist-basiertes Authentifizierungssystem**:

1. **Google Sign-In** via Firebase Authentication
2. **Allowlist-Check** nach erfolgreichem Login
3. **Firestore Security Rules** erzwingen Allowlist auf Datenbankebene
4. Nur Nutzer in der `allowedUsers` Collection mit `enabled: true` haben Zugriff

---

## 🔧 Setup Schritte

### 1. Firebase Authentication aktivieren

1. Öffne die [Firebase Console](https://console.firebase.google.com/)
2. Wähle dein Projekt: **calisthenics-pro-57d6d**
3. Gehe zu **Authentication** → **Sign-in method**
4. Aktiviere **Google** als Sign-in Provider
5. Konfiguriere die **autorisierten Domains**:
   - `localhost` (für Entwicklung)
   - Deine Vercel-Domain (z.B. `calisthenics-pro.vercel.app`)

### 2. Firestore Security Rules deployen

Die Security Rules befinden sich in der Datei `firestore.rules`.

**Option A: Manuell via Firebase Console**

1. Öffne die [Firebase Console](https://console.firebase.google.com/)
2. Gehe zu **Firestore Database** → **Rules**
3. Kopiere den Inhalt von `firestore.rules`
4. Füge ihn in den Rules-Editor ein
5. Klicke auf **Publish**

**Option B: Via Firebase CLI**

```bash
# Firebase CLI installieren (falls noch nicht installiert)
npm install -g firebase-tools

# Anmelden
firebase login

# Projekt initialisieren (nur einmalig)
firebase init firestore

# Rules deployen
firebase deploy --only firestore:rules
```

### 3. Allowlist Collection erstellen

Du musst die `allowedUsers` Collection in Firestore manuell erstellen und erlaubte Benutzer hinzufügen.

**Struktur der Collection:**

```
allowedUsers (collection)
├── {user-uid-1} (document)
│   ├── email: "user1@example.com"
│   ├── enabled: true
│   ├── displayName: "Max Mustermann" (optional)
│   └── addedAt: timestamp
│
├── {user-uid-2} (document)
│   ├── email: "user2@example.com"
│   ├── enabled: true
│   ├── displayName: "Anna Schmidt" (optional)
│   └── addedAt: timestamp
```

**Benutzer hinzufügen:**

1. Öffne **Firestore Database** in der Firebase Console
2. Erstelle Collection `allowedUsers`
3. Füge ein Dokument hinzu:
   - **Document ID:** Die Firebase UID des Benutzers (oder verwende email als ID)
   - **Felder:**
     - `email` (string): Email-Adresse des Benutzers
     - `enabled` (boolean): `true` für aktiviert, `false` für deaktiviert
     - `displayName` (string, optional): Name des Benutzers
     - `addedAt` (timestamp): Zeitstempel wann hinzugefügt

**Wichtig:** Du musst die Benutzer **vor** dem ersten Login hinzufügen!

### 4. Vercel Umgebungsvariablen (optional)

Falls du API-Keys nicht im Code haben möchtest:

1. Gehe zu deinem Vercel-Projekt
2. Settings → Environment Variables
3. Füge Firebase Config als Variablen hinzu:
   - `VITE_FIREBASE_API_KEY`
   - `VITE_FIREBASE_AUTH_DOMAIN`
   - etc.

---

## 🧪 Testing

### Lokales Testing

1. **Entwicklungsserver starten:**
   ```bash
   python server.py
   ```

2. **Im Browser öffnen:**
   ```
   http://localhost:8000
   ```

3. **Login testen:**
   - Klicke auf "Mit Google anmelden"
   - Melde dich mit einem erlaubten Google-Account an
   - Bei erfolgreicher Allowlist-Prüfung: App wird geladen
   - Bei fehlender Berechtigung: "Kein Zugriff" Error

### User Scenarios testen

**✅ Erfolgreicher Login (User in Allowlist):**
- User klickt "Mit Google anmelden"
- Google Auth Popup öffnet sich
- User wählt Account
- Allowlist-Check: ✅ Success
- App wird geladen

**❌ Zugriff verweigert (User nicht in Allowlist):**
- User klickt "Mit Google anmelden"
- Google Auth Popup öffnet sich
- User wählt Account
- Allowlist-Check: ❌ Failed
- Firebase Sign-Out wird automatisch ausgeführt
- Error Toast: "Dein Account hat keinen Zugriff auf diese App."

**🔒 Firestore Access verweigert:**
- User versucht direkt über Firebase SDK auf Daten zuzugreifen
- Security Rules blockieren alle Zugriffe für nicht-erlaubte User
- Error: "permission-denied"

---

## 📁 Dateistruktur

```
/js
├── auth.js              # Authentication Logic & Allowlist Check
├── firebase.js          # Firebase Config & Initialization
└── app.js               # App Initialization mit Auth Guard

/css
└── style.css            # Login UI Styles (am Ende der Datei)

/
├── firestore.rules      # Firestore Security Rules
├── index.html           # Login Screen + App Container
└── AUTH_SETUP.md        # Diese Datei
```

---

## 🔐 Security Rules Erklärung

Die `firestore.rules` implementieren folgende Sicherheitskonzepte:

### Helper Functions

```javascript
isAuthenticated()  // Prüft ob User eingeloggt ist
isAllowed()        // Prüft ob User in Allowlist (UID oder Email)
isOwner(userId)    // Prüft ob User Besitzer einer Ressource ist
```

### Collection Rules

**allowedUsers:**
- ✅ Read: Nur eigenes Dokument
- ❌ Write: Kein Zugriff (nur Admin via Console)

**exercises, plans, workouts, schedule:**
- ✅ Read/Write: Nur erlaubte User (via `isAllowed()`)
- ✅ Validation: Pflichtfelder werden geprüft
- ✅ Type-Checking: Datentypen werden validiert

### Default Deny
- Alle anderen Zugriffe werden standardmäßig blockiert

---

## 🚀 Deployment nach Vercel

1. **Code pushen:**
   ```bash
   git add .
   git commit -m "Add Firebase Authentication with Allowlist"
   git push origin main
   ```

2. **Vercel deployed automatisch**

3. **Domain in Firebase autorisieren:**
   - Firebase Console → Authentication → Settings → Authorized domains
   - Deine Vercel-Domain hinzufügen

4. **Testing auf Production:**
   - Öffne deine Vercel-URL
   - Teste Login mit erlaubtem Account
   - Verifiziere dass nicht-erlaubte Accounts blockiert werden

---

## 🐛 Troubleshooting

### Problem: "Popup blocked" Error

**Lösung:**
- Popups für die Domain erlauben
- Oder verwende `signInWithRedirect()` statt `signInWithPopup()`

### Problem: "permission-denied" in Firestore

**Lösung:**
- Überprüfe ob User in `allowedUsers` Collection existiert
- Überprüfe ob `enabled: true` gesetzt ist
- Überprüfe ob Security Rules deployed sind
- Check Browser Console für detaillierte Fehler

### Problem: User kann sich nicht anmelden

**Checkliste:**
1. ✅ Google Sign-In in Firebase aktiviert?
2. ✅ Domain in Firebase autorisiert?
3. ✅ User in `allowedUsers` Collection?
4. ✅ `enabled: true` gesetzt?
5. ✅ Firebase Auth SDK geladen? (Check Network Tab)
6. ✅ CORS-Fehler? (Check Console)

### Problem: Login funktioniert, aber keine Daten sichtbar

**Lösung:**
- Security Rules überprüfen
- Firebase Console → Firestore → Rules Tab
- Teste Rules mit dem Rules Playground
- Überprüfe Browser Console auf "permission-denied" Errors

---

## 📝 User Management

### Neuen User zur Allowlist hinzufügen

1. **User muss sich einmal versuchen anzumelden** (wird abgelehnt)
2. **Firebase Console öffnen** → Authentication → Users
3. **User UID kopieren**
4. **Firestore Database öffnen** → `allowedUsers` Collection
5. **Neues Dokument erstellen:**
   - Document ID: Die kopierte UID
   - Felder: `email`, `enabled: true`, `addedAt`
6. **User kann sich jetzt anmelden**

### User deaktivieren (ohne zu löschen)

1. Öffne `allowedUsers/{userId}` Dokument
2. Setze `enabled: false`
3. User wird beim nächsten Login automatisch abgemeldet

### User komplett entfernen

1. Lösche Dokument aus `allowedUsers` Collection
2. Optional: Lösche User aus Firebase Authentication

---

## 💡 Best Practices

1. **UIDs statt Emails als Document IDs verwenden**
   - UIDs ändern sich nicht
   - Emails können sich ändern

2. **Enabled-Flag verwenden statt Löschen**
   - User kann temporär deaktiviert werden
   - Audit Trail bleibt erhalten

3. **Timestamps hinzufügen**
   - `addedAt`: Wann wurde User hinzugefügt
   - `disabledAt`: Wann wurde User deaktiviert

4. **Security Rules regelmäßig testen**
   - Verwende den Rules Playground in Firebase Console
   - Teste verschiedene Szenarien

---

## 📞 Support

Bei Fragen oder Problemen:
1. Check Firebase Console → Authentication → Users
2. Check Firestore → allowedUsers Collection
3. Check Browser Console für Fehler
4. Check Firestore Rules für Syntax-Fehler

---

**Status:** ✅ Implementierung abgeschlossen
**Letzte Aktualisierung:** 2026-01-20
