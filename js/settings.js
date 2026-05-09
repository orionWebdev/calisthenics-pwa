// ========================================
// SETTINGS & PROFILE MODULE
// ========================================

const DEFAULT_PROFILE = {
  displayName: '',
  email: '',
  photoURL: '',
  bodyWeight: null,
  bodyHeight: null,
  trainingStyle: 'bodyweight',
  language: 'de',
  unitSystem: 'metric',
  defaultRestTimer: 60,
  hapticsEnabled: true,
  defaultProgressPeriod: '30D',
  theme: 'dark',
  onboardingCompleted: false,
  integrations: {
    garmin: { connected: false },
    appleHealth: { connected: false },
    googleFit: { connected: false }
  }
};

let userProfile = { ...DEFAULT_PROFILE };
let profileLoaded = false;
let saveDebounceTimer = null;

// ========================================
// LOAD & SAVE
// ========================================

function loadUserProfileFromCache() {
  try {
    const cached = localStorage.getItem('userProfile');
    if (cached) {
      const parsed = JSON.parse(cached);
      userProfile = { ...DEFAULT_PROFILE, ...parsed };
      return true;
    }
  } catch (e) {
    console.warn('Failed to load cached profile:', e);
  }
  return false;
}

function saveUserProfileToCache() {
  try {
    localStorage.setItem('userProfile', JSON.stringify(userProfile));
    localStorage.setItem('userProfileSyncedAt', new Date().toISOString());
  } catch (e) {
    console.warn('Failed to cache profile:', e);
  }
}

async function loadUserProfileFromFirestore() {
  const user = getCurrentUser();
  if (!user) return false;

  try {
    const doc = await userProfilesCollection.doc(user.uid).get();
    if (doc.exists) {
      const data = doc.data();
      userProfile = { ...DEFAULT_PROFILE, ...data };
      saveUserProfileToCache();
      return true;
    }
    return false;
  } catch (e) {
    console.warn('Failed to load profile from Firestore:', e);
    return false;
  }
}

async function createDefaultProfile() {
  const user = getCurrentUser();
  if (!user) return;

  const existingPeriod = localStorage.getItem('progressPeriodKey');

  userProfile = {
    ...DEFAULT_PROFILE,
    displayName: user.displayName || '',
    email: user.email || '',
    photoURL: user.photoURL || '',
    defaultProgressPeriod: existingPeriod || '30D'
  };

  try {
    const payload = sanitizeFirestorePayload({
      ...userProfile,
      createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    await userProfilesCollection.doc(user.uid).set(payload);
    saveUserProfileToCache();
  } catch (e) {
    console.error('Failed to create default profile:', e);
  }
}

function updateProfileField(field, value) {
  userProfile[field] = value;
  saveUserProfileToCache();

  if (field === 'language') {
    setLocale(value);
    renderProfileView();
    if (typeof updateBottomNavLabels === 'function') updateBottomNavLabels();
  }

  debouncedSaveToFirestore();
}

function debouncedSaveToFirestore() {
  clearTimeout(saveDebounceTimer);
  saveDebounceTimer = setTimeout(async () => {
    const user = getCurrentUser();
    if (!user) return;

    try {
      const payload = sanitizeFirestorePayload({
        ...userProfile,
        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
      });
      await userProfilesCollection.doc(user.uid).set(payload, { merge: true });
    } catch (e) {
      console.error('Failed to save profile to Firestore:', e);
    }
  }, 300);
}

// ========================================
// THEME
// ========================================

function applyTheme(theme) {
  document.documentElement.setAttribute('data-theme', theme);

  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.content = theme === 'light' ? '#F2F2F7' : '#000000';
}

// Apply theme early from cache (before full profile init)
(function() {
  try {
    const cached = localStorage.getItem('userProfile');
    if (cached) {
      const theme = JSON.parse(cached).theme || 'dark';
      applyTheme(theme);
    }
  } catch (e) { /* fallback to dark */ }
})();

// ========================================
// INIT
// ========================================

async function initProfileView() {
  const hadCache = loadUserProfileFromCache();

  // Sync auth data into profile
  const user = getCurrentUser();
  if (user) {
    userProfile.email = user.email || userProfile.email;
    if (!userProfile.photoURL) userProfile.photoURL = user.photoURL || '';
  }

  renderProfileView();

  // Load from Firestore in background
  const firestoreLoaded = await loadUserProfileFromFirestore();
  if (!firestoreLoaded && !hadCache) {
    await createDefaultProfile();
  }

  // Apply language setting
  if (userProfile.language && userProfile.language !== currentLocale) {
    setLocale(userProfile.language);
    if (typeof updateBottomNavLabels === 'function') updateBottomNavLabels();
  }

  renderProfileView();
  profileLoaded = true;
}

// ========================================
// GETTERS (for other modules)
// ========================================

function getUserProfile() {
  return userProfile;
}

function getSettingValue(key) {
  if (!profileLoaded) loadUserProfileFromCache();
  return userProfile[key] !== undefined ? userProfile[key] : DEFAULT_PROFILE[key];
}

// ========================================
// RENDER
// ========================================

function renderProfileView() {
  const container = document.getElementById('settings-container');
  if (!container) return;

  const user = getCurrentUser();
  const isMetric = userProfile.unitSystem === 'metric';

  container.innerHTML = `
    ${renderProfileCard(user, isMetric)}

    ${renderSection(t('settings.general'), renderGeneralSettings())}

    ${renderSection(t('settings.workout'), renderWorkoutSettings())}

    ${renderSection(t('settings.progress'), renderProgressSettings())}

    ${renderSection(t('settings.integrations'), renderIntegrationsSettings())}

    ${renderSection(t('settings.legal'), renderLegalSettings())}

    ${renderSection(t('settings.account'), renderAccountSettings(user))}

    <div class="settings-app-info">
      ${t('settings.version')}: 1.0.0 &middot; ${t('settings.build')}: PWA
    </div>
  `;
}

function renderSection(title, content) {
  return `
    <div>
      <div class="settings-section-header">${title}</div>
      <div class="settings-card">${content}</div>
    </div>
  `;
}

// ========================================
// PROFILE CARD
// ========================================

function renderProfileCard(user, isMetric) {
  const name = userProfile.displayName || user?.displayName || 'Benutzer';
  const email = userProfile.email || user?.email || '';
  const photoURL = userProfile.photoURL || user?.photoURL || '';

  const avatarContent = photoURL
    ? `<img src="${photoURL}" alt="" referrerpolicy="no-referrer">`
    : `<span class="material-symbols-rounded profile-avatar-fallback">account_circle</span>`;

  const weightDisplay = getWeightDisplay(userProfile.bodyWeight, isMetric);
  const heightDisplay = getHeightDisplay(userProfile.bodyHeight);

  const styles = [
    { value: 'gym', label: t('profile.gym') },
    { value: 'bodyweight', label: t('profile.bodyweight') },
    { value: 'hybrid', label: t('profile.hybrid') }
  ];
  const currentStyle = styles.find(s => s.value === userProfile.trainingStyle) || styles[1];

  return `
    <div class="profile-hero">
      <div class="profile-header">
        <div class="profile-avatar">${avatarContent}</div>
        <div style="flex:1;min-width:0">
          <div class="profile-name" id="profile-name-display" onclick="startNameEdit()">${escapeHTML(name)}</div>
          <div class="profile-email">${escapeHTML(email)}</div>
        </div>
      </div>

      <div class="settings-card" style="margin-top:0.25rem">
        <div class="settings-row" onclick="openBodyWeightPicker()">
          <span class="material-symbols-rounded settings-row-icon">monitor_weight</span>
          <span class="settings-row-label">${t('profile.bodyWeight')}</span>
          <span class="settings-row-value">${weightDisplay} <span class="material-symbols-rounded">chevron_right</span></span>
        </div>
        <div class="settings-row" onclick="openBodyHeightPicker()">
          <span class="material-symbols-rounded settings-row-icon">height</span>
          <span class="settings-row-label">${t('profile.bodyHeight')}</span>
          <span class="settings-row-value">${heightDisplay} <span class="material-symbols-rounded">chevron_right</span></span>
        </div>
        <div class="settings-row" onclick="openTrainingStylePicker()">
          <span class="material-symbols-rounded settings-row-icon">fitness_center</span>
          <span class="settings-row-label">${t('profile.trainingStyle')}</span>
          <span class="settings-row-value">${currentStyle.label} <span class="material-symbols-rounded">chevron_right</span></span>
        </div>
      </div>
    </div>
  `;
}

// ========================================
// GENERAL SETTINGS
// ========================================

function renderGeneralSettings() {
  return `
    <div class="settings-row">
      <span class="material-symbols-rounded settings-row-icon">dark_mode</span>
      <span class="settings-row-label">${t('settings.theme')}</span>
      ${renderSegmented('theme', [
        { value: 'dark', label: t('settings.themeDark') },
        { value: 'light', label: t('settings.themeLight') }
      ], userProfile.theme || 'dark')}
    </div>
    <div class="settings-row">
      <span class="material-symbols-rounded settings-row-icon">translate</span>
      <span class="settings-row-label">${t('settings.language')}</span>
      ${renderSegmented('language', [
        { value: 'de', label: t('settings.langDe') },
        { value: 'en', label: t('settings.langEn') }
      ], userProfile.language)}
    </div>
    <div class="settings-row">
      <span class="material-symbols-rounded settings-row-icon">straighten</span>
      <span class="settings-row-label">${t('settings.unitSystem')}</span>
      ${renderSegmented('unitSystem', [
        { value: 'metric', label: t('settings.metric') },
        { value: 'imperial', label: t('settings.imperial') }
      ], userProfile.unitSystem)}
    </div>
  `;
}

// ========================================
// WORKOUT SETTINGS
// ========================================

function renderWorkoutSettings() {
  const timerValue = userProfile.defaultRestTimer || 60;
  return `
    <div class="settings-row" onclick="openRestTimerPicker()">
      <span class="material-symbols-rounded settings-row-icon">timer</span>
      <span class="settings-row-label">${t('settings.defaultRestTimer')}</span>
      <span class="settings-row-value">${timerValue}s <span class="material-symbols-rounded">chevron_right</span></span>
    </div>
    <div class="settings-row">
      <span class="material-symbols-rounded settings-row-icon">vibration</span>
      <span class="settings-row-label">${t('settings.haptics')}</span>
      ${renderToggle('hapticsEnabled', userProfile.hapticsEnabled)}
    </div>
  `;
}

// ========================================
// PROGRESS SETTINGS
// ========================================

function renderProgressSettings() {
  return `
    <div class="settings-row">
      <span class="material-symbols-rounded settings-row-icon">date_range</span>
      <span class="settings-row-label">${t('settings.defaultPeriod')}</span>
      ${renderSegmented('defaultProgressPeriod', [
        { value: '7D', label: '7D' },
        { value: '30D', label: '30D' },
        { value: '6M', label: '6M' },
        { value: '1Y', label: '1Y' }
      ], userProfile.defaultProgressPeriod)}
    </div>
  `;
}

// ========================================
// INTEGRATIONS SETTINGS
// ========================================

function renderIntegrationsSettings() {
  const integrations = [
    { key: 'garmin', icon: 'watch', label: 'Garmin Connect' },
    { key: 'appleHealth', icon: 'favorite', label: 'Apple Health' },
    { key: 'googleFit', icon: 'monitoring', label: 'Google Fit' }
  ];
  return integrations.map(item => `
    <div class="settings-row">
      <span class="material-symbols-rounded settings-row-icon">${item.icon}</span>
      <span class="settings-row-label">${item.label}</span>
      <span class="settings-badge-soon">${t('settings.comingSoon')}</span>
    </div>
  `).join('');
}

// ========================================
// ACCOUNT SETTINGS
// ========================================

function renderAccountSettings(user) {
  const email = userProfile.email || user?.email || '';
  return `
    <div class="settings-row">
      <span class="material-symbols-rounded settings-row-icon">email</span>
      <span class="settings-row-label">${t('settings.email')}</span>
      <span class="settings-row-value">${escapeHTML(email)}</span>
    </div>
    <div class="settings-row settings-row-danger" onclick="handleSignOut()">
      <span class="material-symbols-rounded settings-row-icon">logout</span>
      <span class="settings-row-label">${t('settings.signOut')}</span>
    </div>
    <div class="settings-row settings-row-danger" onclick="confirmDeleteAccount()">
      <span class="material-symbols-rounded settings-row-icon">delete_forever</span>
      <span class="settings-row-label">${t('settings.deleteAccount')}</span>
    </div>
  `;
}

// ========================================
// LEGAL & PRIVACY
// ========================================

function renderLegalSettings() {
  return `
    <div class="settings-row" onclick="openPrivacyPolicy()">
      <span class="material-symbols-rounded settings-row-icon">shield</span>
      <span class="settings-row-label">${t('settings.privacy')}</span>
      <span class="settings-row-value"><span class="material-symbols-rounded">chevron_right</span></span>
    </div>
    <div class="settings-row" onclick="openTermsOfUse()">
      <span class="material-symbols-rounded settings-row-icon">gavel</span>
      <span class="settings-row-label">${t('settings.terms')}</span>
      <span class="settings-row-value"><span class="material-symbols-rounded">chevron_right</span></span>
    </div>
    <div class="settings-row" onclick="openImprint()">
      <span class="material-symbols-rounded settings-row-icon">info</span>
      <span class="settings-row-label">${t('settings.imprint')}</span>
      <span class="settings-row-value"><span class="material-symbols-rounded">chevron_right</span></span>
    </div>
    <div class="settings-row" onclick="openAcknowledgments()">
      <span class="material-symbols-rounded settings-row-icon">favorite</span>
      <span class="settings-row-label">${t('settings.acknowledgments')}</span>
      <span class="settings-row-value"><span class="material-symbols-rounded">chevron_right</span></span>
    </div>
    <div class="settings-row" onclick="restartOnboarding()">
      <span class="material-symbols-rounded settings-row-icon">play_circle</span>
      <span class="settings-row-label">${t('settings.replayOnboarding')}</span>
      <span class="settings-row-value"><span class="material-symbols-rounded">chevron_right</span></span>
    </div>
  `;
}

const LEGAL_LAST_UPDATED = '2026-05-08';

function legalMeta() {
  return `<p class="legal-modal-meta">${t('settings.lastUpdated', { date: LEGAL_LAST_UPDATED })}</p>`;
}

function legalCloseBtn() {
  const label = (typeof t === 'function' && t('common.close')) || 'Schließen';
  return `<button type="button" class="legal-modal-close-btn" onclick="closeGenericModal()">${label}</button>`;
}

function _legalWrap(bodyHTML, includeMeta) {
  return `<div class="legal-modal-body">${bodyHTML}${includeMeta ? legalMeta() : ''}${legalCloseBtn()}</div>`;
}

function openPrivacyPolicy() {
  if (typeof openGenericModal !== 'function') return;
  const isDe = (userProfile.language || 'de') !== 'en';
  const html = isDe ? privacyPolicyHtmlDe() : privacyPolicyHtmlEn();
  openGenericModal(t('settings.privacy'), _legalWrap(html, true));
}

function openTermsOfUse() {
  if (typeof openGenericModal !== 'function') return;
  const isDe = (userProfile.language || 'de') !== 'en';
  const html = isDe ? termsHtmlDe() : termsHtmlEn();
  openGenericModal(t('settings.terms'), _legalWrap(html, true));
}

function openImprint() {
  if (typeof openGenericModal !== 'function') return;
  const isDe = (userProfile.language || 'de') !== 'en';
  const html = isDe ? imprintHtmlDe() : imprintHtmlEn();
  openGenericModal(t('settings.imprint'), _legalWrap(html, false));
}

function openAcknowledgments() {
  if (typeof openGenericModal !== 'function') return;
  openGenericModal(t('settings.acknowledgments'), _legalWrap(acknowledgmentsHtml(), false));
}

// ----- Texte (Templates — bitte vor Veröffentlichung rechtlich prüfen lassen) -----

function privacyPolicyHtmlDe() {
  return `
    <p><strong>Diese Datenschutzerklärung ist ein Template und sollte vor der Veröffentlichung rechtlich geprüft werden (z. B. mit einem Generator wie e-recht24 oder durch einen Anwalt).</strong></p>

    <h4>1. Verantwortlicher</h4>
    <p>[Vor- und Nachname]<br>
    [Straße + Hausnummer]<br>
    [PLZ Ort]<br>
    [Land]<br>
    E-Mail: [deine-mail@beispiel.de]</p>

    <h4>2. Welche Daten werden erhoben?</h4>
    <ul>
      <li><strong>Konto-Daten:</strong> E-Mail-Adresse, optional Name und Profilbild — werden über Google Sign-In bzw. E-Mail-Anmeldung an Firebase Authentication übermittelt.</li>
      <li><strong>Trainings-Daten:</strong> selbst erstellte Pläne, Übungen, Workouts, Sätze und Kalender-Einträge — werden in Cloud Firestore gespeichert.</li>
      <li><strong>Gesundheits-/Körperdaten (optional, besonders sensibel):</strong> Körpergewicht und Körpergröße, sofern du sie selbst einträgst. Diese Daten sind nach Art. 9 DSGVO besonders schützenswert und werden ausschließlich in deinem privaten Firestore-Bereich gespeichert. Du kannst sie jederzeit ändern, leer lassen oder über „Account löschen" vollständig entfernen.</li>
      <li><strong>Technische Daten:</strong> Geräteinformationen und Fehlerprotokolle, die der Browser oder die App-Hülle automatisch an Firebase übermittelt.</li>
    </ul>

    <h4>3. Zweck der Verarbeitung</h4>
    <p>Die Daten werden <strong>ausschließlich zur Bereitstellung der Trainingsfunktionen</strong> verwendet — insbesondere zur Synchronisation deiner Trainings-Daten zwischen mehreren Geräten, zum Speichern deiner Sessions und zur Berechnung deiner persönlichen Auswertungen (Trainingsrhythmus, Form-Index, Aktivitätskalender).</p>
    <p><strong>Keine Weitergabe an Dritte:</strong> Wir geben deine Daten <em>nicht</em> an Dritte weiter — abgesehen von den unter Punkt 5 genannten technischen Dienstleistern, die zwingend zur Bereitstellung der App notwendig sind.</p>
    <p><strong>Kein Werbetracking:</strong> ATEM Hybrid setzt keine Tracking- oder Werbe-Cookies ein, betreibt kein verhaltensbasiertes Tracking und ist in keine Werbe-Netzwerke eingebunden. Es findet keinerlei Profilbildung zu Werbezwecken statt.</p>

    <h4>4. Rechtsgrundlage</h4>
    <p>Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung — Bereitstellung des angefragten Dienstes) sowie Art. 6 Abs. 1 lit. f DSGVO (berechtigtes Interesse an stabilem Betrieb der App). Für freiwillig angegebene Gesundheitsdaten (Körpergewicht/Größe) zusätzlich Art. 9 Abs. 2 lit. a DSGVO (ausdrückliche Einwilligung durch aktive Eingabe in der App).</p>

    <h4>5. Drittanbieter</h4>
    <p>Wir nutzen folgende Dienste der Google Ireland Limited / Google LLC:</p>
    <ul>
      <li><strong>Firebase Authentication</strong> — Konto-Verwaltung</li>
      <li><strong>Cloud Firestore</strong> — Speicherung deiner Trainings-Daten</li>
      <li><strong>Firebase Hosting</strong> — Auslieferung der Web-App (sofern verwendet)</li>
    </ul>
    <p>Bei der Verarbeitung können Daten in die USA übertragen werden. Google ist nach dem EU-US Data Privacy Framework zertifiziert.</p>

    <h4>6. Speicherdauer</h4>
    <p>Deine Daten werden gespeichert, solange dein Account aktiv ist. Bei Account-Löschung werden alle persönlichen Daten und Trainings-Daten gelöscht. Backup-Kopien können bis zu 30 Tage erhalten bleiben, bevor sie endgültig entfernt werden.</p>

    <h4>7. Deine Rechte</h4>
    <p>Du hast jederzeit das Recht auf:</p>
    <ul>
      <li>Auskunft (Art. 15 DSGVO)</li>
      <li>Berichtigung (Art. 16 DSGVO)</li>
      <li>Löschung (Art. 17 DSGVO) — direkt in der App über „Account löschen"</li>
      <li>Einschränkung der Verarbeitung (Art. 18 DSGVO)</li>
      <li>Datenübertragbarkeit (Art. 20 DSGVO)</li>
      <li>Widerspruch (Art. 21 DSGVO)</li>
      <li>Beschwerde bei einer Aufsichtsbehörde (Art. 77 DSGVO)</li>
    </ul>
    <p>Für Anfragen kontaktiere uns unter [deine-mail@beispiel.de].</p>

    <h4>8. Cookies / Lokale Speicherung</h4>
    <p>Die App speichert Einstellungen und Cache-Daten ausschließlich lokal auf deinem Gerät (localStorage, IndexedDB, Service Worker Cache). Es werden keine Tracking- oder Werbe-Cookies eingesetzt.</p>

    <h4>9. Änderungen</h4>
    <p>Diese Datenschutzerklärung kann angepasst werden. Wesentliche Änderungen werden in der App angekündigt.</p>
  `;
}

function privacyPolicyHtmlEn() {
  return `
    <p><strong>This privacy policy is a template and should be legally reviewed before publishing.</strong></p>

    <h4>1. Controller</h4>
    <p>[Full name]<br>
    [Street + No.]<br>
    [Postal code, City]<br>
    [Country]<br>
    Email: [your-email@example.com]</p>

    <h4>2. What data is collected?</h4>
    <ul>
      <li><strong>Account data:</strong> email address, optionally name and profile picture, transmitted via Google Sign-In or email sign-up to Firebase Authentication.</li>
      <li><strong>Training data:</strong> your own plans, exercises, workouts, sets and calendar entries — stored in Cloud Firestore.</li>
      <li><strong>Health / body data (optional, particularly sensitive):</strong> body weight and height, only if you enter them yourself. These data are subject to special protection under Art. 9 GDPR and are stored exclusively in your private Firestore area. You can edit, leave them blank, or fully delete them at any time via "Delete account".</li>
      <li><strong>Technical data:</strong> device information and error logs that the browser or app shell sends automatically to Firebase.</li>
    </ul>

    <h4>3. Purpose</h4>
    <p>Data is processed <strong>exclusively to provide the training functionality</strong> — in particular cross-device synchronization, saving your sessions, and computing your personal insights (training rhythm, form index, activity calendar).</p>
    <p><strong>No sharing with third parties:</strong> We do <em>not</em> share your data with third parties — apart from the technical service providers listed under section 5, which are strictly necessary to operate the app.</p>
    <p><strong>No ad tracking:</strong> ATEM Hybrid does not use any tracking or advertising cookies, no behavioral tracking, and is not connected to any advertising networks. There is no profiling for advertising purposes whatsoever.</p>

    <h4>4. Legal basis</h4>
    <p>Art. 6(1)(b) GDPR (contract performance — providing the service requested) and Art. 6(1)(f) GDPR (legitimate interest in stable operation of the app). For voluntarily provided health data (body weight/height) additionally Art. 9(2)(a) GDPR (explicit consent through active input in the app).</p>

    <h4>5. Third-party services</h4>
    <p>We use the following Google Ireland Limited / Google LLC services:</p>
    <ul>
      <li><strong>Firebase Authentication</strong> — account management</li>
      <li><strong>Cloud Firestore</strong> — storage of your training data</li>
      <li><strong>Firebase Hosting</strong> — web-app delivery (if applicable)</li>
    </ul>
    <p>Data may be transferred to the US. Google is certified under the EU-US Data Privacy Framework.</p>

    <h4>6. Retention</h4>
    <p>Your data is kept as long as your account is active. On account deletion, all personal and training data is removed. Backups may persist up to 30 days before final deletion.</p>

    <h4>7. Your rights</h4>
    <p>You have the right to:</p>
    <ul>
      <li>access (Art. 15 GDPR)</li>
      <li>rectification (Art. 16 GDPR)</li>
      <li>erasure (Art. 17 GDPR) — directly via "Delete account"</li>
      <li>restriction (Art. 18 GDPR)</li>
      <li>data portability (Art. 20 GDPR)</li>
      <li>objection (Art. 21 GDPR)</li>
      <li>complaint with a supervisory authority (Art. 77 GDPR)</li>
    </ul>
    <p>For requests contact us at [your-email@example.com].</p>

    <h4>8. Local storage</h4>
    <p>The app stores settings and cache data exclusively on your device (localStorage, IndexedDB, Service Worker Cache). No tracking or advertising cookies are used.</p>

    <h4>9. Changes</h4>
    <p>This policy may be updated. Material changes will be announced in the app.</p>
  `;
}

function termsHtmlDe() {
  return `
    <p><strong>Hinweis: Diese Nutzungsbedingungen sind ein Template. Vor Veröffentlichung rechtlich prüfen lassen.</strong></p>

    <h4>1. Geltungsbereich</h4>
    <p>Diese Bedingungen regeln die Nutzung der App „ATEM Hybrid" (nachfolgend „die App").</p>

    <h4>2. Account</h4>
    <p>Für die Nutzung wird ein Account benötigt. Du bist verpflichtet, deine Zugangsdaten geheim zu halten und korrekte Angaben zu machen.</p>

    <h4>3. Kein medizinischer Rat</h4>
    <p>Die App stellt Trainings- und Fitness-Tools bereit. Sie ersetzt keine medizinische Beratung. Bei gesundheitlichen Bedenken konsultiere bitte einen Arzt oder qualifizierten Trainer. Die Ausführung von Übungen erfolgt auf eigene Verantwortung.</p>

    <h4>4. Verfügbarkeit</h4>
    <p>Wir bemühen uns um stabilen Betrieb, garantieren aber keine ununterbrochene Verfügbarkeit.</p>

    <h4>5. Haftung</h4>
    <p>Eine Haftung für leichte Fahrlässigkeit ist ausgeschlossen, soweit nicht zwingende gesetzliche Vorschriften (insbesondere für Leben, Körper und Gesundheit) entgegenstehen.</p>

    <h4>6. Datenschutz</h4>
    <p>Es gelten die Bestimmungen unserer Datenschutzerklärung.</p>

    <h4>7. Änderungen</h4>
    <p>Wir behalten uns vor, diese Bedingungen anzupassen. Wesentliche Änderungen werden in der App angekündigt.</p>
  `;
}

function termsHtmlEn() {
  return `
    <p><strong>Note: These terms are a template. Have them legally reviewed before publishing.</strong></p>

    <h4>1. Scope</h4>
    <p>These terms govern the use of the "ATEM Hybrid" app ("the App").</p>

    <h4>2. Account</h4>
    <p>An account is required to use the App. You are responsible for keeping your credentials secret and providing accurate information.</p>

    <h4>3. No medical advice</h4>
    <p>The App provides training and fitness tools. It does not replace medical advice. Consult a doctor or qualified trainer if you have health concerns. You perform exercises at your own risk.</p>

    <h4>4. Availability</h4>
    <p>We strive for stable operation but do not guarantee uninterrupted availability.</p>

    <h4>5. Liability</h4>
    <p>Liability for light negligence is excluded as far as legally permitted (in particular for life, body and health).</p>

    <h4>6. Privacy</h4>
    <p>Our Privacy Policy applies.</p>

    <h4>7. Changes</h4>
    <p>We reserve the right to amend these terms. Material changes will be announced in the app.</p>
  `;
}

function imprintHtmlDe() {
  return `
    <p>Angaben gemäß § 5 TMG / § 18 MStV:</p>
    <p>
      [Vor- und Nachname]<br>
      [Straße + Hausnummer]<br>
      [PLZ Ort]<br>
      [Land]
    </p>
    <p><strong>Kontakt:</strong><br>
      E-Mail: [deine-mail@beispiel.de]
    </p>
    <p><strong>Verantwortlich für den Inhalt nach § 18 Abs. 2 MStV:</strong><br>
      [Vor- und Nachname], [Adresse]
    </p>
    <h4>Haftungsausschluss</h4>
    <p>Trotz sorgfältiger inhaltlicher Kontrolle übernehmen wir keine Haftung für die Inhalte externer Links. Für den Inhalt der verlinkten Seiten sind ausschließlich deren Betreiber verantwortlich.</p>
  `;
}

function imprintHtmlEn() {
  return `
    <p>Information according to § 5 TMG / § 18 MStV (German law):</p>
    <p>
      [Full name]<br>
      [Street + No.]<br>
      [Postal code, City]<br>
      [Country]
    </p>
    <p><strong>Contact:</strong><br>
      Email: [your-email@example.com]
    </p>
    <p><strong>Responsible for content per § 18 (2) MStV:</strong><br>
      [Full name], [Address]
    </p>
    <h4>Disclaimer</h4>
    <p>Despite careful content checks, we do not assume liability for the content of external links. The operators of linked pages are solely responsible for their content.</p>
  `;
}

function acknowledgmentsHtml() {
  return `
    <p>ATEM Hybrid nutzt folgende Open-Source-Software und Ressourcen:</p>
    <ul class="legal-list">
      <li><strong>Material Symbols</strong> — Apache License 2.0 (Google)</li>
      <li><strong>Tailwind CSS</strong> — MIT License (Tailwind Labs)</li>
      <li><strong>Chart.js</strong> + <strong>chartjs-plugin-annotation</strong> — MIT License</li>
      <li><strong>Firebase JS SDK</strong> — Apache License 2.0 (Google)</li>
      <li><strong>Zalando Sans Expanded</strong> — SIL Open Font License 1.1 (Zalando)</li>
    </ul>
    <p>Alle Lizenztexte sind über die jeweiligen Projekt-Repositorien verfügbar. Vielen Dank an die Maintainer dieser Projekte.</p>
  `;
}

window.openPrivacyPolicy = openPrivacyPolicy;
window.openTermsOfUse = openTermsOfUse;
window.openImprint = openImprint;
window.openAcknowledgments = openAcknowledgments;

// ========================================
// REUSABLE CONTROLS
// ========================================

function renderSegmented(field, options, currentValue) {
  const buttons = options.map(opt => {
    const active = opt.value === currentValue ? ' active' : '';
    return `<button class="settings-segmented-btn${active}" onclick="handleSegmentedChange('${field}', '${opt.value}')">${opt.label}</button>`;
  }).join('');
  return `<div class="settings-segmented">${buttons}</div>`;
}

function renderToggle(field, isActive) {
  const active = isActive !== false ? ' active' : '';
  return `<button class="settings-toggle${active}" onclick="handleToggleChange('${field}', this)"></button>`;
}

// ========================================
// EVENT HANDLERS
// ========================================

function handleSegmentedChange(field, value) {
  updateProfileField(field, value);

  if (field === 'theme') {
    applyTheme(value);
  }

  if (field === 'defaultProgressPeriod') {
    localStorage.setItem('progressPeriodKey', value);
  }

  renderProfileView();
  showEdgeFeedback('success', t('settings.saved'));
}

function handleToggleChange(field, el) {
  const newValue = !userProfile[field];
  updateProfileField(field, newValue);
  el.classList.toggle('active', newValue);
  showEdgeFeedback('success', t('settings.saved'));
}

// ========================================
// NAME EDITING
// ========================================

function startNameEdit() {
  const display = document.getElementById('profile-name-display');
  if (!display) return;

  const currentName = userProfile.displayName || '';
  display.outerHTML = `<input type="text" class="profile-name-input" id="profile-name-input"
    value="${escapeHTML(currentName)}" autofocus
    onblur="finishNameEdit()" onkeydown="if(event.key==='Enter')this.blur()">`;

  const input = document.getElementById('profile-name-input');
  if (input) {
    input.focus();
    input.select();
  }
}

function finishNameEdit() {
  const input = document.getElementById('profile-name-input');
  if (!input) return;

  const newName = input.value.trim();
  if (newName && newName !== userProfile.displayName) {
    updateProfileField('displayName', newName);
    showEdgeFeedback('success', t('profile.nameUpdated'));
  }
  renderProfileView();
}

// ========================================
// NUMBER PICKERS
// ========================================

function openBodyWeightPicker() {
  const isMetric = userProfile.unitSystem === 'metric';
  const currentKg = userProfile.bodyWeight || 70;
  const displayValue = isMetric ? currentKg : kgToLbs(currentKg);

  openNumberPicker({
    type: isMetric ? 'bodyWeightKg' : 'bodyWeightLbs',
    initialValue: displayValue,
    onConfirm: (value) => {
      const kg = isMetric ? value : lbsToKg(value);
      updateProfileField('bodyWeight', Math.round(kg * 10) / 10);
      renderProfileView();
      showEdgeFeedback('success', t('settings.saved'));
    }
  });
}

function openBodyHeightPicker() {
  openNumberPicker({
    type: 'bodyHeight',
    initialValue: userProfile.bodyHeight || 170,
    onConfirm: (value) => {
      updateProfileField('bodyHeight', value);
      renderProfileView();
      showEdgeFeedback('success', t('settings.saved'));
    }
  });
}

function openRestTimerPicker() {
  openNumberPicker({
    type: 'restTimer',
    initialValue: userProfile.defaultRestTimer || 60,
    onConfirm: (value) => {
      updateProfileField('defaultRestTimer', value);
      renderProfileView();
      showEdgeFeedback('success', t('settings.saved'));
    }
  });
}

// ========================================
// TRAINING STYLE PICKER
// ========================================

function openTrainingStylePicker() {
  const styles = [
    { value: 'gym', label: t('profile.gym') },
    { value: 'bodyweight', label: t('profile.bodyweight') },
    { value: 'hybrid', label: t('profile.hybrid') }
  ];

  const bodyHTML = styles.map(style => {
    const isActive = userProfile.trainingStyle === style.value;
    return `
      <div class="settings-row${isActive ? '' : ''}" onclick="selectTrainingStyle('${style.value}')" style="cursor:pointer">
        <span class="settings-row-label">${style.label}</span>
        ${isActive ? '<span class="material-symbols-rounded" style="color:var(--color-primary)">check</span>' : ''}
      </div>
    `;
  }).join('');

  openGenericModal(t('profile.trainingStyle'), `<div class="settings-card">${bodyHTML}</div>`);
}

function selectTrainingStyle(value) {
  updateProfileField('trainingStyle', value);
  renderProfileView();
  showEdgeFeedback('success', t('settings.saved'));
}

// ========================================
// DELETE ACCOUNT
// ========================================

function confirmDeleteAccount() {
  const bodyHTML = `
    <div class="settings-delete-modal">
      <h3>${t('settings.deleteAccountConfirm')}</h3>
      <p>${t('settings.deleteAccountConfirmText')}</p>
      <button class="btn-danger" id="settings-delete-confirm-btn" onclick="executeDeleteAccount()">${t('settings.deleteAccountButton')}</button>
    </div>
  `;
  openGenericModal(t('settings.deleteAccount'), bodyHTML);
}

/**
 * Delete all user-scoped Firestore data. Must run while the user is still
 * authenticated, since security rules reject reads/writes without auth.
 */
async function deleteAllUserFirestoreData(uid) {
  if (!uid) return;
  const userScopedCollections = [
    sessionsCollection,
    plansCollection,
    progressCollection,
    scheduleCollection,
    exercisesCollection,
    workoutsCollection,
    db.collection('sessionTemplates')
  ];

  for (const coll of userScopedCollections) {
    try {
      const snap = await coll.where('userId', '==', uid).get();
      if (snap.empty) continue;
      const docs = snap.docs;
      for (let i = 0; i < docs.length; i += 500) {
        const batch = db.batch();
        docs.slice(i, i + 500).forEach(d => batch.delete(d.ref));
        await batch.commit();
      }
      console.log(`🗑️  Deleted ${docs.length} docs from ${coll.id}`);
    } catch (e) {
      console.warn(`Could not clean ${coll.id}:`, e);
    }
  }

  try {
    await userProfilesCollection.doc(uid).delete();
  } catch (e) {
    console.warn('Could not delete user profile:', e);
  }
}

function clearLocalUserCache() {
  const keys = [
    'userProfile',
    'userProfileSyncedAt',
    'userId_backfill_done',
    'onboarding_completed',
    'onboarding_seen',
    'theme',
    'dailyMetrics',
    'lastWorkout'
  ];
  keys.forEach(k => {
    try { localStorage.removeItem(k); } catch (e) { /* ignore */ }
  });
}

async function executeDeleteAccount(passwordOverride) {
  const user = firebase.auth().currentUser;
  if (!user) {
    showEdgeFeedback('error', t('errors.deleteFailed'));
    return;
  }

  const confirmBtn = document.getElementById('settings-delete-confirm-btn');
  if (confirmBtn) {
    confirmBtn.disabled = true;
    confirmBtn.textContent = t('common.loading');
  }

  const uid = user.uid;

  try {
    // 1. Delete all Firestore data (while auth is still valid)
    await deleteAllUserFirestoreData(uid);

    // 2. Clear local cache
    clearLocalUserCache();

    // 3. Delete the Firebase Auth account
    await user.delete();

    // 4. Reload to a clean state
    closeGenericModal();
    if (typeof showLoginScreen === 'function') showLoginScreen();
    setTimeout(() => window.location.reload(), 250);
  } catch (e) {
    console.error('Failed to delete account:', e);

    if (e && e.code === 'auth/requires-recent-login') {
      // Show re-auth UI
      promptReauthForDelete();
      return;
    }

    if (confirmBtn) {
      confirmBtn.disabled = false;
      confirmBtn.textContent = t('settings.deleteAccountButton');
    }
    showEdgeFeedback('error', (typeof getAuthErrorMessage === 'function' && e && e.code) ? getAuthErrorMessage(e.code) : t('errors.deleteFailed'));
  }
}

/**
 * Show re-auth UI inside the delete-account modal. After successful re-auth
 * we automatically retry the delete flow.
 */
function promptReauthForDelete() {
  const user = firebase.auth().currentUser;
  if (!user) return;

  const providerId = (user.providerData[0] && user.providerData[0].providerId) || '';
  const isGoogle = providerId === 'google.com';

  const bodyHTML = `
    <div class="settings-delete-modal">
      <h3>${t('settings.deleteAccountConfirm')}</h3>
      <p>${t('settings.reauthRequired')}</p>
      ${isGoogle ? `
        <p class="reauth-hint">${t('settings.reauthGoogleHint')}</p>
        <button class="btn-danger" id="reauth-confirm-btn" onclick="handleReauthAndDelete()">${t('settings.reauthConfirm')}</button>
      ` : `
        <p class="reauth-hint">${t('settings.reauthPasswordHint')}</p>
        <div class="reauth-field">
          <label class="email-form-label" for="reauth-password-input">${t('settings.currentPassword')}</label>
          <input id="reauth-password-input" type="password" class="email-form-input" autocomplete="current-password" />
        </div>
        <button class="btn-danger" id="reauth-confirm-btn" onclick="handleReauthAndDelete()">${t('settings.deleteAccountButton')}</button>
      `}
    </div>
  `;
  openGenericModal(t('settings.deleteAccount'), bodyHTML);
}

async function handleReauthAndDelete() {
  const passwordInput = document.getElementById('reauth-password-input');
  const password = passwordInput ? passwordInput.value : undefined;
  const confirmBtn = document.getElementById('reauth-confirm-btn');

  if (confirmBtn) {
    confirmBtn.disabled = true;
    confirmBtn.textContent = t('common.loading');
  }

  const result = await reauthenticateCurrentUser(password);
  if (!result.success) {
    if (confirmBtn) {
      confirmBtn.disabled = false;
      confirmBtn.textContent = t('settings.deleteAccountButton');
    }
    showEdgeFeedback('error', result.message || t('errors.deleteFailed'));
    return;
  }

  // Re-auth succeeded — retry deletion
  await executeDeleteAccount();
}

// ========================================
// UNIT CONVERSION HELPERS
// ========================================

function kgToLbs(kg) {
  return Math.round(kg * 2.20462 * 10) / 10;
}

function lbsToKg(lbs) {
  return Math.round(lbs / 2.20462 * 10) / 10;
}

function getWeightDisplay(kg, isMetric) {
  if (kg === null || kg === undefined) return '-';
  if (isMetric) return `${kg} kg`;
  return `${kgToLbs(kg)} lbs`;
}

function getHeightDisplay(cm) {
  if (cm === null || cm === undefined) return '-';
  return `${cm} cm`;
}

function escapeHTML(str) {
  if (!str) return '';
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

console.log('Settings module loaded');
