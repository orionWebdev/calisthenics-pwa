// ==================== AUTHENTICATION & AUTHORIZATION ====================

// Safe translation accessor — i18n.js may load after auth.js, so guard `t`.
const tAuth = (key) => (typeof t === 'function' ? t(key) : key);

/**
 * Authentication State Management
 * - Google Sign-In via Firebase Auth
 * - Email/Password Sign-In and Sign-Up via Firebase Auth
 * - Allowlist check against Firestore "allowedUsers" collection
 * - Auth guards for app access
 * - Persistent session handling
 */

// Auth State
let currentUser = null;
let isAuthReady = false;
let isAllowlistChecked = false;
let authStateListeners = [];

// UI State
const AUTH_STATES = {
  LOADING: 'loading',
  LOGGED_OUT: 'logged_out',
  LOGGED_IN: 'logged_in',
  ACCESS_DENIED: 'access_denied',
  ERROR: 'error'
};

let currentAuthState = AUTH_STATES.LOADING;
let authErrorTimeout = null;

// Firebase Auth instance
const auth = firebase.auth();
const allowedUsersCollection = db.collection('allowedUsers');

// Google Auth Provider
const googleProvider = new firebase.auth.GoogleAuthProvider();
googleProvider.setCustomParameters({
  prompt: 'select_account'
});

// ==================== AUTH STATE MANAGEMENT ====================

/**
 * Subscribe to auth state changes
 * @param {Function} callback - Called with (user, state)
 */
function onAuthStateChange(callback) {
  authStateListeners.push(callback);
  // Immediately call with current state if auth is ready
  if (isAuthReady) {
    callback(currentUser, currentAuthState);
  }
  return () => {
    authStateListeners = authStateListeners.filter(cb => cb !== callback);
  };
}

/**
 * Notify all listeners of auth state change
 */
function notifyAuthStateChange() {
  authStateListeners.forEach(callback => {
    callback(currentUser, currentAuthState);
  });
}

/**
 * Update auth state and notify listeners
 */
function setAuthState(state, user = null) {
  currentAuthState = state;
  currentUser = user;
  notifyAuthStateChange();
}

// ==================== ALLOWLIST CHECK ====================

/**
 * Check if user is in allowlist
 * @param {string} uid - User ID
 * @param {string} email - User email
 * @returns {Promise<boolean>} - True if user is allowed
 */
async function checkAllowlist(uid, email) {
  try {
    // Check by UID first (primary)
    const uidDoc = await allowedUsersCollection.doc(uid).get();
    if (uidDoc.exists) {
      const data = uidDoc.data();
      return data.enabled === true;
    }

    // Fallback: Check by email document id
    if (email) {
      const emailDoc = await allowedUsersCollection.doc(email).get();
      if (emailDoc.exists) {
        const data = emailDoc.data();
        return data.enabled === true;
      }
    }

    // Fallback: Check by email field
    const emailQuery = await allowedUsersCollection
      .where('email', '==', email)
      .where('enabled', '==', true)
      .limit(1)
      .get();

    return !emailQuery.empty;
  } catch (error) {
    console.error('❌ Allowlist check failed:', error);
    throw error;
  }
}

// ==================== SIGN IN / SIGN OUT ====================

/**
 * Sign in with Google
 * @returns {Promise<Object>} - User object or error
 */
async function signInWithGoogle() {
  try {
    showLoadingState(tAuth('recent.auth.signingIn'));

    const result = await auth.signInWithPopup(googleProvider);
    const user = result.user;

    // Check allowlist
    showLoadingState(tAuth('recent.auth.checkingAccess'));
    const isAllowed = await checkAllowlist(user.uid, user.email);

    if (!isAllowed) {
      // User not in allowlist - sign out immediately
      await auth.signOut();
      setAuthState(AUTH_STATES.ACCESS_DENIED);
      hideLoadingState();
      return {
        success: false,
        error: 'access_denied',
        message: tAuth('recent.auth.noAccess')
      };
    }

    // Success - user is allowed
    setAuthState(AUTH_STATES.LOGGED_IN, user);
    hideLoadingState();

    // Haptic feedback on success
    if (typeof triggerHapticFeedback === 'function') {
      triggerHapticFeedback('success');
    }

    return {
      success: true,
      user: user
    };

  } catch (error) {
    console.error('❌ Sign-in error:', error);
    hideLoadingState();

    setAuthState(AUTH_STATES.ERROR);

    return {
      success: false,
      error: error.code,
      message: getAuthErrorMessage(error.code)
    };
  }
}

/**
 * Map Firebase auth errors to user-friendly i18n messages
 */
function getAuthErrorMessage(errorCode) {
  const tt = (typeof t === 'function') ? t : (key) => key;
  const map = {
    'auth/popup-closed-by-user': tt('auth.errors.popupClosed'),
    'auth/popup-blocked': tt('auth.errors.popupBlocked'),
    'auth/network-request-failed': tt('auth.errors.network'),
    'auth/invalid-email': tt('auth.errors.invalidEmail'),
    'auth/user-disabled': tt('auth.errors.userDisabled'),
    'auth/user-not-found': tt('auth.errors.userNotFound'),
    'auth/wrong-password': tt('auth.errors.wrongPassword'),
    'auth/invalid-credential': tt('auth.errors.invalidCredential'),
    'auth/email-already-in-use': tt('auth.errors.emailInUse'),
    'auth/weak-password': tt('auth.errors.weakPassword'),
    'auth/too-many-requests': tt('auth.errors.tooManyRequests'),
    'auth/requires-recent-login': tt('auth.errors.requiresRecentLogin'),
    'auth/missing-password': tt('auth.errors.missingPassword')
  };
  return map[errorCode] || tt('auth.errors.generic');
}

/**
 * Validate email format (simple RFC-ish check)
 */
function isValidEmail(email) {
  if (!email || typeof email !== 'string') return false;
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

/**
 * Sign in with Email & Password
 */
async function signInWithEmail(email, password) {
  try {
    showLoadingState(tAuth('recent.auth.signingIn'));

    const result = await auth.signInWithEmailAndPassword(email.trim(), password);
    const user = result.user;

    showLoadingState(tAuth('recent.auth.checkingAccess'));
    const isAllowed = await checkAllowlist(user.uid, user.email);

    if (!isAllowed) {
      await auth.signOut();
      setAuthState(AUTH_STATES.ACCESS_DENIED);
      hideLoadingState();
      return {
        success: false,
        error: 'access_denied',
        message: tAuth('recent.auth.noAccess')
      };
    }

    setAuthState(AUTH_STATES.LOGGED_IN, user);
    hideLoadingState();

    if (typeof triggerHapticFeedback === 'function') {
      triggerHapticFeedback('success');
    }

    return { success: true, user };
  } catch (error) {
    console.error('❌ Email sign-in error:', error);
    hideLoadingState();
    setAuthState(AUTH_STATES.ERROR);
    return {
      success: false,
      error: error.code,
      message: getAuthErrorMessage(error.code)
    };
  }
}

/**
 * Register a new user with Email & Password
 */
async function signUpWithEmail(email, password, displayName) {
  try {
    showLoadingState(tAuth('recent.auth.creatingAccount'));

    const result = await auth.createUserWithEmailAndPassword(email.trim(), password);
    const user = result.user;

    if (displayName && typeof displayName === 'string' && displayName.trim()) {
      try {
        await user.updateProfile({ displayName: displayName.trim() });
      } catch (e) {
        console.warn('Could not set displayName:', e);
      }
    }

    try {
      await user.sendEmailVerification();
    } catch (e) {
      console.warn('Could not send verification email:', e);
    }

    showLoadingState(tAuth('recent.auth.checkingAccess'));
    const isAllowed = await checkAllowlist(user.uid, user.email);

    if (!isAllowed) {
      await auth.signOut();
      setAuthState(AUTH_STATES.ACCESS_DENIED);
      hideLoadingState();
      return {
        success: false,
        error: 'access_denied',
        message: tAuth('recent.auth.noAccess')
      };
    }

    setAuthState(AUTH_STATES.LOGGED_IN, user);
    hideLoadingState();

    if (typeof triggerHapticFeedback === 'function') {
      triggerHapticFeedback('success');
    }

    return { success: true, user };
  } catch (error) {
    console.error('❌ Email sign-up error:', error);
    hideLoadingState();
    setAuthState(AUTH_STATES.ERROR);
    return {
      success: false,
      error: error.code,
      message: getAuthErrorMessage(error.code)
    };
  }
}

/**
 * Send password reset email
 */
async function sendPasswordResetEmail(email) {
  try {
    await auth.sendPasswordResetEmail(email.trim());
    return { success: true };
  } catch (error) {
    console.error('❌ Password reset error:', error);
    return {
      success: false,
      error: error.code,
      message: getAuthErrorMessage(error.code)
    };
  }
}

/**
 * Re-authenticate the current user. Required by Firebase before sensitive
 * operations like account deletion when the last login is older than ~5 min.
 *
 * For Google users: re-runs the Google popup.
 * For email/password users: requires the current password.
 *
 * @param {string} [password] - Required when the user signed in with email/password.
 * @returns {Promise<{success: boolean, error?: string, message?: string}>}
 */
async function reauthenticateCurrentUser(password) {
  const user = auth.currentUser;
  if (!user) {
    return { success: false, error: 'no_user', message: 'Keine aktive Sitzung.' };
  }

  const providerId = (user.providerData[0] && user.providerData[0].providerId) || '';

  try {
    if (providerId === 'google.com') {
      await user.reauthenticateWithPopup(googleProvider);
      return { success: true };
    }
    if (providerId === 'password') {
      if (!password) {
        return { success: false, error: 'auth/missing-password', message: getAuthErrorMessage('auth/missing-password') };
      }
      const credential = firebase.auth.EmailAuthProvider.credential(user.email, password);
      await user.reauthenticateWithCredential(credential);
      return { success: true };
    }
    return { success: false, error: 'unsupported_provider', message: tAuth('recent.auth.unsupportedProvider') };
  } catch (error) {
    console.error('❌ Re-authentication error:', error);
    return {
      success: false,
      error: error.code,
      message: getAuthErrorMessage(error.code)
    };
  }
}

/**
 * Sign out current user
 */
async function signOut() {
  try {
    await auth.signOut();
    currentUser = null;
    isAllowlistChecked = false;
    setAuthState(AUTH_STATES.LOGGED_OUT);

    // Haptic feedback
    if (typeof triggerHapticFeedback === 'function') {
      triggerHapticFeedback('light');
    }

    // Reload to clear all in-memory data from previous user
    window.location.reload();

    return { success: true };
  } catch (error) {
    console.error('❌ Sign-out error:', error);
    return {
      success: false,
      error: error.code,
      message: tAuth('recent.auth.signOutError')
    };
  }
}

// ==================== AUTH INITIALIZATION ====================

/**
 * Initialize auth listener
 * This runs once on app startup
 */
function initAuth() {
  return new Promise((resolve) => {
    auth.onAuthStateChanged(async (user) => {
      if (user && !isAllowlistChecked) {
        // User is signed in - check allowlist
        try {
          showLoadingState(tAuth('recent.auth.checkingAccess'));
          const isAllowed = await checkAllowlist(user.uid, user.email);
          isAllowlistChecked = true;

          if (isAllowed) {
            currentUser = user;
            setAuthState(AUTH_STATES.LOGGED_IN, user);
            console.log('✅ User authenticated:', user.email);
          } else {
            // Not in allowlist - sign out
            await auth.signOut();
            currentUser = null;
            setAuthState(AUTH_STATES.ACCESS_DENIED);
            console.log('❌ User not in allowlist:', user.email);
          }

          hideLoadingState();
        } catch (error) {
          console.error('❌ Auth initialization error:', error);
          await auth.signOut();
          setAuthState(AUTH_STATES.ERROR);
          hideLoadingState();
        }
      } else if (!user) {
        // User is signed out
        currentUser = null;
        isAllowlistChecked = false;
        setAuthState(AUTH_STATES.LOGGED_OUT);
        hideLoadingState();
      }

      if (!isAuthReady) {
        isAuthReady = true;
        resolve();
      }
    });
  });
}

// ==================== AUTH GUARDS ====================

/**
 * Check if user is authenticated and allowed
 * @returns {boolean}
 */
function isAuthenticated() {
  return currentAuthState === AUTH_STATES.LOGGED_IN && currentUser !== null;
}

/**
 * Require authentication - redirect to login if not authenticated
 * Call this at the start of protected views
 */
function requireAuth() {
  if (!isAuthenticated()) {
    showLoginScreen();
    return false;
  }
  return true;
}

/**
 * Get current user
 * @returns {Object|null} - Current user or null
 */
function getCurrentUser() {
  return currentUser;
}

/**
 * Get current auth state
 * @returns {string} - Current auth state
 */
function getAuthState() {
  return currentAuthState;
}

// ==================== UI HELPERS ====================

/**
 * Show loading state with message
 */
function showLoadingState(message) {
  if (!message) message = tAuth('recent.auth.loading');
  const splash = document.getElementById('auth-splash');
  setLoadingProgress(10);

  if (splash) {
    splash.classList.add('active');
    document.body.style.overflow = 'hidden';
  }
}

/**
 * Hide loading state
 */
function hideLoadingState() {
  const splash = document.getElementById('auth-splash');

  if (splash) {
    // Delay hiding splash for smooth transition
    setTimeout(() => {
      splash.classList.remove('active');
      document.body.style.overflow = '';
    }, 300);
  }
}

/**
 * Update splash progress bar (0-100)
 */
function setLoadingProgress(percent) {
  const splash = document.getElementById('auth-splash');
  const progress = document.querySelector('.splash-progress');
  const bar = document.querySelector('.splash-progress-bar');
  if (!progress || !bar) return;

  const safeValue = Math.max(0, Math.min(100, Number(percent) || 0));
  bar.style.width = `${safeValue}%`;
  progress.setAttribute('aria-valuenow', String(safeValue));

  if (splash && !splash.classList.contains('active')) {
    splash.classList.add('active');
  }
}

/**
 * Show login screen
 */
function showLoginScreen() {
  const loginScreen = document.getElementById('login-screen');
  const mainApp = document.getElementById('app-container');

  if (loginScreen) {
    loginScreen.classList.add('active');
  }

  if (mainApp) {
    mainApp.style.display = 'none';
  }

  // Apply i18n if i18n is loaded
  if (typeof t === 'function' && loginScreen) {
    loginScreen.querySelectorAll('[data-i18n]').forEach(el => {
      const key = el.dataset.i18n;
      if (key) el.textContent = t(key);
    });
    loginScreen.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
      const key = el.dataset.i18nPlaceholder;
      if (key) el.placeholder = t(key);
    });
  }

  // Reset email auth form to sign-in mode whenever login screen is shown
  if (typeof setLoginFormMode === 'function') {
    try { setLoginFormMode('signin'); } catch (e) { /* i18n not ready yet */ }
  }
  const passwordInput = document.getElementById('password-input');
  if (passwordInput) passwordInput.value = '';

  hideAuthError();
  hideLoadingState();
}

/**
 * Show main app (hide login)
 */
function showMainApp() {
  const loginScreen = document.getElementById('login-screen');
  const mainApp = document.getElementById('app-container');

  if (loginScreen) {
    loginScreen.classList.remove('active');
  }

  if (mainApp) {
    mainApp.style.display = 'block';
  }

  hideAuthError();
}

/**
 * Show error toast
 */
function showAuthError(message) {
  const errorContainer = document.getElementById('auth-error');
  const errorMessage = document.getElementById('auth-error-message');

  if (errorContainer && errorMessage) {
    if (authErrorTimeout) {
      clearTimeout(authErrorTimeout);
      authErrorTimeout = null;
    }

    errorMessage.textContent = message;
    errorContainer.classList.add('active');

    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', message);
    }

    // Haptic feedback
    if (typeof triggerHapticFeedback === 'function') {
      triggerHapticFeedback('error');
    }

    // Auto-hide after 5 seconds
    authErrorTimeout = setTimeout(() => {
      errorContainer.classList.remove('active');
      authErrorTimeout = null;
    }, 5000);
  }
}

/**
 * Hide error toast
 */
function hideAuthError() {
  const errorContainer = document.getElementById('auth-error');
  if (errorContainer) {
    errorContainer.classList.remove('active');
  }
  if (authErrorTimeout) {
    clearTimeout(authErrorTimeout);
    authErrorTimeout = null;
  }
}

// ==================== EVENT HANDLERS ====================

/**
 * Handle Google Sign-In button click
 */
async function handleGoogleSignIn() {
  const signInButton = document.getElementById('google-signin-btn');
  const buttonText = document.getElementById('signin-btn-text');
  const buttonSpinner = document.getElementById('signin-btn-spinner');

  // Show button loading state
  if (signInButton) {
    signInButton.disabled = true;
  }
  if (buttonText) {
    buttonText.style.display = 'none';
  }
  if (buttonSpinner) {
    buttonSpinner.style.display = 'block';
  }

  // Attempt sign in
  const result = await signInWithGoogle();

  // Reset button state
  if (signInButton) {
    signInButton.disabled = false;
  }
  if (buttonText) {
    buttonText.style.display = 'flex';
  }
  if (buttonSpinner) {
    buttonSpinner.style.display = 'none';
  }

  // Handle result
  if (result.success) {
    showMainApp();
  } else if (result.error === 'access_denied') {
    showAuthError(result.message);
  } else if (result.error !== 'auth/popup-closed-by-user') {
    // Don't show error for user-cancelled popup
    showAuthError(result.message);
  }
}

/**
 * Toggle login form mode (sign-in / sign-up / reset)
 */
function setLoginFormMode(mode) {
  const root = document.getElementById('login-screen');
  if (!root) return;
  root.dataset.mode = mode;

  const titleEl = document.getElementById('login-card-title');
  const subtitleEl = document.getElementById('login-card-subtitle');
  const submitBtnText = document.getElementById('email-submit-btn-text');
  const switchModeText = document.getElementById('login-switch-mode-text');
  const switchModeBtn = document.getElementById('login-switch-mode-btn');
  const nameField = document.getElementById('email-name-field');
  const passwordField = document.getElementById('email-password-field');
  const forgotBtn = document.getElementById('login-forgot-btn');
  const dividerEl = document.getElementById('login-divider');
  const googleBtn = document.getElementById('google-signin-btn');
  const resetHintEl = document.getElementById('login-reset-hint');

  if (typeof t !== 'function') return;

  hideAuthError();

  if (mode === 'signup') {
    if (titleEl) titleEl.textContent = t('auth.signUpTitle');
    if (subtitleEl) subtitleEl.textContent = t('auth.signUpSubtitle');
    if (submitBtnText) submitBtnText.textContent = t('auth.signUpButton');
    if (switchModeText) switchModeText.textContent = t('auth.alreadyHaveAccount');
    if (switchModeBtn) switchModeBtn.textContent = t('auth.signIn');
    if (nameField) nameField.style.display = '';
    if (passwordField) passwordField.style.display = '';
    if (forgotBtn) forgotBtn.style.display = 'none';
    if (dividerEl) dividerEl.style.display = '';
    if (googleBtn) googleBtn.style.display = '';
    if (resetHintEl) resetHintEl.style.display = 'none';
  } else if (mode === 'reset') {
    if (titleEl) titleEl.textContent = t('auth.resetTitle');
    if (subtitleEl) subtitleEl.textContent = t('auth.resetSubtitle');
    if (submitBtnText) submitBtnText.textContent = t('auth.resetButton');
    if (switchModeText) switchModeText.textContent = t('auth.backToSignIn');
    if (switchModeBtn) switchModeBtn.textContent = t('auth.signIn');
    if (nameField) nameField.style.display = 'none';
    if (passwordField) passwordField.style.display = 'none';
    if (forgotBtn) forgotBtn.style.display = 'none';
    if (dividerEl) dividerEl.style.display = 'none';
    if (googleBtn) googleBtn.style.display = 'none';
    if (resetHintEl) resetHintEl.style.display = '';
  } else {
    // signin (default)
    if (titleEl) titleEl.textContent = t('auth.signInTitle');
    if (subtitleEl) subtitleEl.textContent = t('auth.signInSubtitle');
    if (submitBtnText) submitBtnText.textContent = t('auth.signInButton');
    if (switchModeText) switchModeText.textContent = t('auth.noAccountYet');
    if (switchModeBtn) switchModeBtn.textContent = t('auth.signUp');
    if (nameField) nameField.style.display = 'none';
    if (passwordField) passwordField.style.display = '';
    if (forgotBtn) forgotBtn.style.display = '';
    if (dividerEl) dividerEl.style.display = '';
    if (googleBtn) googleBtn.style.display = '';
    if (resetHintEl) resetHintEl.style.display = 'none';
  }
}

function toggleLoginMode() {
  const root = document.getElementById('login-screen');
  const current = (root && root.dataset.mode) || 'signin';
  setLoginFormMode(current === 'signin' ? 'signup' : 'signin');
}

function showForgotPassword() {
  setLoginFormMode('reset');
}

/**
 * Submit handler for the email auth form (sign-in / sign-up / reset)
 */
async function handleEmailAuthSubmit(event) {
  if (event && typeof event.preventDefault === 'function') {
    event.preventDefault();
  }

  const root = document.getElementById('login-screen');
  const mode = (root && root.dataset.mode) || 'signin';

  const emailInput = document.getElementById('email-input');
  const passwordInput = document.getElementById('password-input');
  const nameInput = document.getElementById('name-input');
  const submitBtn = document.getElementById('email-submit-btn');
  const submitBtnText = document.getElementById('email-submit-btn-text');
  const submitBtnSpinner = document.getElementById('email-submit-btn-spinner');

  const email = (emailInput && emailInput.value || '').trim();
  const password = (passwordInput && passwordInput.value) || '';
  const name = (nameInput && nameInput.value || '').trim();

  if (!isValidEmail(email)) {
    showAuthError(t('auth.errors.invalidEmail'));
    return;
  }

  if (mode !== 'reset' && (!password || password.length < 6)) {
    showAuthError(t('auth.errors.weakPassword'));
    return;
  }

  if (submitBtn) submitBtn.disabled = true;
  if (submitBtnText) submitBtnText.style.display = 'none';
  if (submitBtnSpinner) submitBtnSpinner.style.display = 'flex';

  try {
    let result;
    if (mode === 'signup') {
      result = await signUpWithEmail(email, password, name);
    } else if (mode === 'reset') {
      result = await sendPasswordResetEmail(email);
      if (result.success) {
        if (typeof showEdgeFeedback === 'function') {
          showEdgeFeedback('success', t('auth.resetSent'));
        }
        setLoginFormMode('signin');
      } else {
        showAuthError(result.message);
      }
      return;
    } else {
      result = await signInWithEmail(email, password);
    }

    if (result.success) {
      showMainApp();
    } else if (result.error === 'access_denied') {
      showAuthError(result.message);
    } else {
      showAuthError(result.message);
    }
  } finally {
    if (submitBtn) submitBtn.disabled = false;
    if (submitBtnText) submitBtnText.style.display = '';
    if (submitBtnSpinner) submitBtnSpinner.style.display = 'none';
  }
}

/**
 * Handle Sign Out button click
 */
async function handleSignOut() {
  const result = await signOut();

  if (result.success) {
    showLoginScreen();
  } else {
    showAuthError(result.message);
  }
}

// ==================== INITIALIZATION ====================

console.log('🔐 Auth module loaded');

// Export functions for global use
window.authModule = {
  initAuth,
  isAuthenticated,
  requireAuth,
  getCurrentUser,
  getAuthState,
  signInWithGoogle,
  signInWithEmail,
  signUpWithEmail,
  sendPasswordResetEmail,
  reauthenticateCurrentUser,
  signOut,
  onAuthStateChange,
  handleGoogleSignIn,
  handleEmailAuthSubmit,
  handleSignOut,
  setLoginFormMode,
  toggleLoginMode,
  showForgotPassword,
  showLoadingState,
  hideLoadingState,
  setLoadingProgress,
  showLoginScreen,
  showMainApp,
  AUTH_STATES
};
