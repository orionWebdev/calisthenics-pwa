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
      <button class="btn-danger" onclick="executeDeleteAccount()">${t('settings.deleteAccountButton')}</button>
    </div>
  `;
  openGenericModal(t('settings.deleteAccount'), bodyHTML);
}

async function executeDeleteAccount() {
  const user = getCurrentUser();
  if (!user) return;

  try {
    // Delete Firestore profile
    await userProfilesCollection.doc(user.uid).delete();

    // Clear local cache
    localStorage.removeItem('userProfile');
    localStorage.removeItem('userProfileSyncedAt');

    // Delete Firebase Auth account
    await user.delete();

    if (typeof showLoginScreen === 'function') showLoginScreen();
  } catch (e) {
    console.error('Failed to delete account:', e);
    showEdgeFeedback('error', t('errors.deleteFailed'));
  }
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
