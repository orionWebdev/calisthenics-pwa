// ==================== AUTHENTICATION & AUTHORIZATION ====================

/**
 * Authentication State Management
 * - Google Sign-In via Firebase Auth
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
    showLoadingState('Anmeldung läuft...');

    const result = await auth.signInWithPopup(googleProvider);
    const user = result.user;

    // Check allowlist
    showLoadingState('Zugriff wird überprüft...');
    const isAllowed = await checkAllowlist(user.uid, user.email);

    if (!isAllowed) {
      // User not in allowlist - sign out immediately
      await auth.signOut();
      setAuthState(AUTH_STATES.ACCESS_DENIED);
      hideLoadingState();
      return {
        success: false,
        error: 'access_denied',
        message: 'Dein Account hat keinen Zugriff auf diese App.'
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

    let errorMessage = 'Ein Fehler ist aufgetreten. Bitte versuche es erneut.';

    if (error.code === 'auth/popup-closed-by-user') {
      errorMessage = 'Anmeldung wurde abgebrochen.';
    } else if (error.code === 'auth/popup-blocked') {
      errorMessage = 'Popup wurde blockiert. Bitte erlaube Popups für diese Seite.';
    } else if (error.code === 'auth/network-request-failed') {
      errorMessage = 'Netzwerkfehler. Bitte überprüfe deine Internetverbindung.';
    }

    setAuthState(AUTH_STATES.ERROR);

    return {
      success: false,
      error: error.code,
      message: errorMessage
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
      message: 'Fehler beim Abmelden.'
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
          showLoadingState('Zugriff wird überprüft...');
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
function showLoadingState(message = 'Lädt...') {
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
  signOut,
  onAuthStateChange,
  handleGoogleSignIn,
  handleSignOut,
  showLoadingState,
  hideLoadingState,
  setLoadingProgress,
  showLoginScreen,
  showMainApp,
  AUTH_STATES
};
