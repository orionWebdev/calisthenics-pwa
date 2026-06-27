// ========================================
// MAIN APP LOGIC
// ========================================

// Current active view
let currentView = 'dashboard';
let radialMenuOpen = false;

// View titles for mobile
const viewTitles = {
  dashboard: 'Dashboard',
  progress: 'Progress',
  training: 'Training',
  workout: 'Workout',
  profile: 'Profil',
};

// View icons for FAB
const viewIcons = {
  dashboard: 'home',
  progress: 'trending_up',
  training: 'fitness_center',
  workout: 'fitness_center',
  profile: 'account_circle'
};

// Training tab state
let currentTrainingTab = 'plans';

function loadTrainingTab() {
  const stored = localStorage.getItem('trainingTab');
  return stored === 'exercises' ? 'exercises' : 'plans';
}

function saveTrainingTab(tab) {
  localStorage.setItem('trainingTab', tab);
}

function switchTrainingTab(tab) {
  const order = ['plans', 'exercises'];
  const nextTab = order.includes(tab) ? tab : 'plans';
  currentTrainingTab = nextTab;
  saveTrainingTab(nextTab);

  // Slide-Underline wie auf der Fortschritt-Seite (kein clunky Hintergrund).
  const control = document.querySelector('#training-segmented-control .pv3-segmented-control');
  if (control) control.style.setProperty('--active-idx', order.indexOf(nextTab));
  document.querySelectorAll('#training-segmented-control .pv3-seg-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.tab === nextTab);
  });

  const plansTab = document.getElementById('training-tab-plans');
  const exercisesTab = document.getElementById('training-tab-exercises');
  if (plansTab) plansTab.classList.toggle('active', nextTab === 'plans');
  if (exercisesTab) exercisesTab.classList.toggle('active', nextTab === 'exercises');
}

function showTrainingTab(tab) {
  showView('training');
  switchTrainingTab(tab || currentTrainingTab);
}

// ========================================
// NAVIGATION
// ========================================

function showView(viewName) {
  // Hide all views
  document.querySelectorAll('.view').forEach(view => {
    view.classList.remove('active');
  });

  // Show selected view
  document.getElementById(`view-${viewName}`).classList.add('active');

  // Update desktop navigation buttons
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.classList.remove('active');
  });
  const desktopBtn = document.querySelector(`.desktop-nav [data-view="${viewName}"]`);
  if (desktopBtn) desktopBtn.classList.add('active');

  // Update bottom navigation buttons (mobile)
  document.querySelectorAll('.bottom-nav-item').forEach(btn => {
    btn.classList.remove('active');
  });
  const bottomNavBtn = document.querySelector(`.bottom-nav [data-view="${viewName}"]`);
  if (bottomNavBtn) bottomNavBtn.classList.add('active');
  scheduleBottomNavIndicatorUpdate();

  // Update settings icon button
  const settingsBtn = document.getElementById('settings-btn');
  if (settingsBtn) {
    if (viewName === 'profile') {
      settingsBtn.classList.add('active');
    } else {
      settingsBtn.classList.remove('active');
    }
  }

  // (Mobile header is now a static brand bar — no per-view title/icon to update.)

  // Update FAB icon based on current view
  updateFabIcon(viewName);

  // Load view-specific data
  if (viewName === 'training') {
    switchTrainingTab(loadTrainingTab());
  }

  // Initialize progress page when first opened
  if (viewName === 'progress') {
    if (typeof initProgressV3 === 'function') {
      initProgressV3();
    } else if (typeof initProgressV2 === 'function') {
      initProgressV2();
    } else if (typeof initProgress === 'function') {
      initProgress();
    }
  }

  if (viewName === 'dashboard' && typeof refreshDashboard === 'function') {
    refreshDashboard();
  }

  if (viewName === 'profile' && typeof initProfileView === 'function') {
    initProfileView();
  }

  // Toggle fullscreen mode for workout view
  if (viewName === 'workout') {
    document.body.classList.add('workout-fullscreen');
    if (typeof renderWorkoutScreen === 'function') {
      renderWorkoutScreen();
    }
  } else {
    document.body.classList.remove('workout-fullscreen');
  }

  if (viewName !== 'workout' && typeof ensureActiveWorkoutBanner === 'function') {
    ensureActiveWorkoutBanner();
  }

  if (viewName !== 'progress' && typeof closeAllPickerSheets === 'function') {
    closeAllPickerSheets();
  }

  currentView = viewName;
}

let bottomNavIndicatorRaf = null;
let bottomNavIndicatorTimer = null;
let bottomNavResizeObserver = null;
let bottomNavObservedEl = null;

function updateBottomNavLabels() {
  if (typeof t !== 'function') return;
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.dataset.i18n;
    if (key) el.textContent = t(key);
  });
  document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
    const key = el.dataset.i18nPlaceholder;
    if (key) el.placeholder = t(key);
  });
}

function updateBottomNavIndicator() {
  const nav = document.querySelector('.bottom-nav');
  if (!nav) return;
  if (getComputedStyle(nav).display === 'none') return;
  const indicator = nav.querySelector('.bottom-nav-indicator');
  const activeItem = nav.querySelector('.bottom-nav-item.active');
  if (!indicator || !activeItem) return;

  const content = activeItem.querySelector('.bottom-nav-item-content') || activeItem;
  if ('ResizeObserver' in window) {
    if (!bottomNavResizeObserver) {
      bottomNavResizeObserver = new ResizeObserver(() => scheduleBottomNavIndicatorUpdate());
    }
    if (bottomNavObservedEl !== content) {
      if (bottomNavObservedEl) bottomNavResizeObserver.unobserve(bottomNavObservedEl);
      bottomNavResizeObserver.observe(content);
      bottomNavObservedEl = content;
    }
  }
  const navRect = nav.getBoundingClientRect();
  const itemRect = activeItem.getBoundingClientRect();
  const contentRect = content.getBoundingClientRect();
  const navStyles = getComputedStyle(nav);
  const pillPadding = parseFloat(navStyles.getPropertyValue('--bottom-nav-pill-padding')) || 10;
  const pillInset = parseFloat(navStyles.getPropertyValue('--bottom-nav-pill-inset')) || 4;
  const pillTighten = parseFloat(navStyles.getPropertyValue('--bottom-nav-pill-tighten')) || 0;
  const paddingLeft = parseFloat(navStyles.paddingLeft) || 0;
  const paddingRight = parseFloat(navStyles.paddingRight) || 0;

  const contentWidth = Math.max(content.scrollWidth, contentRect.width);
  const navWidth = nav.clientWidth;
  const innerWidth = Math.max(0, navWidth - paddingLeft - paddingRight);
  const maxWidth = Math.max(48, innerWidth);
  let width = Math.max(40, contentWidth + pillPadding * 2 - pillTighten);
  width = Math.min(width, maxWidth);

  const centerX = contentRect.left - (navRect.left + paddingLeft) + contentRect.width / 2;
  let x = Math.round(centerX - width / 2);
  const minX = pillInset;
  const maxX = Math.max(minX, Math.round(innerWidth - width - pillInset));
  x = Math.min(Math.max(x, minX), maxX);

  nav.style.setProperty('--bottom-nav-indicator-x', `${x}px`);
  nav.style.setProperty('--bottom-nav-indicator-width', `${Math.round(width)}px`);
  nav.classList.add('bottom-nav--ready');
}

function scheduleBottomNavIndicatorUpdate() {
  if (bottomNavIndicatorRaf) cancelAnimationFrame(bottomNavIndicatorRaf);
  bottomNavIndicatorRaf = requestAnimationFrame(updateBottomNavIndicator);
  clearTimeout(bottomNavIndicatorTimer);
  bottomNavIndicatorTimer = setTimeout(updateBottomNavIndicator, 360);
}

function initBottomNav() {
  updateBottomNavLabels();
  scheduleBottomNavIndicatorUpdate();
  window.addEventListener('resize', scheduleBottomNavIndicatorUpdate);
  window.addEventListener('orientationchange', scheduleBottomNavIndicatorUpdate);
}

function updateFabIcon(viewName) {
  const fabIcon = document.getElementById('fab-icon');
  if (fabIcon && !radialMenuOpen) {
    const icon = viewIcons[viewName] || 'fitness_center';
    fabIcon.textContent = icon;
  }
}

function showViewFromRadial(viewName) {
  showView(viewName);
  closeRadialMenu();
}

// ========================================
// RADIAL MENU (MOBILE)
// ========================================

function toggleRadialMenu() {
  if (radialMenuOpen) {
    closeRadialMenu();
  } else {
    openRadialMenu();
  }
}

function openRadialMenu() {
  radialMenuOpen = true;
  const fabMain = document.getElementById('fab-main');
  const fabIcon = document.getElementById('fab-icon');
  if (!fabMain) return; // Radial-FAB durch Bottom-Nav-FAB ersetzt

  fabMain.classList.add('active');
  document.getElementById('radial-menu').classList.add('active');
  document.getElementById('radial-overlay').classList.add('active');
  document.body.style.overflow = 'hidden';

  // Change FAB icon to close (add)
  if (fabIcon) {
    fabIcon.textContent = 'add';
  }

  // Haptic feedback (only after a user gesture — avoids Chrome intervention warning)
  if ('vibrate' in navigator && (!navigator.userActivation || navigator.userActivation.hasBeenActive)) {
    navigator.vibrate(10);
  }
}

function closeRadialMenu() {
  radialMenuOpen = false;
  const fabMain = document.getElementById('fab-main');
  if (!fabMain) return; // Radial-FAB durch Bottom-Nav-FAB ersetzt

  fabMain.classList.remove('active');
  document.getElementById('radial-menu').classList.remove('active');
  document.getElementById('radial-overlay').classList.remove('active');
  document.body.style.overflow = '';

  // Restore FAB icon to current view icon
  updateFabIcon(currentView);

  // Haptic feedback (only after a user gesture — avoids Chrome intervention warning)
  if ('vibrate' in navigator && (!navigator.userActivation || navigator.userActivation.hasBeenActive)) {
    navigator.vibrate(10);
  }
}

// Close radial menu on escape
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    closeRadialMenu();
    closeExerciseModal();
  }
});

// ========================================
// SCROLL BEHAVIOR FOR FLOATING NAV
// ========================================

let lastScrollY = 0;
let scrollTimeout;

function handleNavScroll() {
  const desktopNav = document.getElementById('desktop-nav');
  if (!desktopNav) return;

  const currentScrollY = window.scrollY;

  // Scroll down - hide nav
  if (currentScrollY > lastScrollY && currentScrollY > 100) {
    desktopNav.classList.add('nav-hidden');
  }
  // Scroll up - show nav
  else if (currentScrollY < lastScrollY) {
    desktopNav.classList.remove('nav-hidden');
  }

  lastScrollY = currentScrollY;
}

// Throttle scroll events for performance
window.addEventListener('scroll', () => {
  if (scrollTimeout) {
    window.cancelAnimationFrame(scrollTimeout);
  }
  scrollTimeout = window.requestAnimationFrame(() => {
    handleNavScroll();
  });
});

// ========================================
// PROFILE
// ========================================

/**
 * Update profile information with user data
 */
function updateProfileInfo(user) {
  if (!user) return;
  // Profile is now rendered by settings.js via initProfileView()
  if (currentView === 'profile' && typeof initProfileView === 'function') {
    initProfileView();
  }
}

// ========================================
// INITIALIZATION
// ========================================

async function initApp() {
  const setProgress = window.authModule?.setLoadingProgress;
  const hideLoading = window.authModule?.hideLoadingState;
  if (typeof setProgress === 'function') {
    setProgress(15);
  }

  try {
    // 0a. One-time migration: backfill userId on existing docs
    if (typeof runUserIdBackfillIfNeeded === 'function') {
      await runUserIdBackfillIfNeeded();
    }

    // 0b. Load user profile (needed for session load calculations)
    if (typeof loadUserProfileFromFirestore === 'function') {
      await loadUserProfileFromFirestore();
    } else if (typeof loadUserProfileFromCache === 'function') {
      loadUserProfileFromCache();
    }

    // Apply saved language setting immediately
    if (typeof setLocale === 'function' && typeof getUserProfile === 'function') {
      const lang = getUserProfile().language;
      if (lang) setLocale(lang);
      // Re-localize the statically-rendered plan UI (e.g. the "New plan" button):
      // applyPlanI18n() ran once at module load with the default locale.
      if (typeof applyPlanI18n === 'function') applyPlanI18n();
    }

    // 1. Initialize default exercises if needed
    await initializeDefaultExercises();
    if (typeof setProgress === 'function') setProgress(30);

    // 2. Load exercises
    await loadExercises();
    if (typeof setProgress === 'function') setProgress(45);

    // 3. Load plans
    if (typeof loadPlans === 'function') {
      await loadPlans();
    } else {
      console.warn('⚠️ loadPlans function not found');
    }
    if (typeof setProgress === 'function') setProgress(60);

    // 4. Load calendar schedule
    if (typeof loadSchedule === 'function') {
      await loadSchedule();
    } else {
      console.warn('⚠️ loadSchedule function not found');
    }
    if (typeof setProgress === 'function') setProgress(70);

    // 5. Load session templates
    if (typeof loadSessionTemplates === 'function') {
      await loadSessionTemplates();
    }
    if (typeof setProgress === 'function') setProgress(80);

    // 6. Setup real-time listeners
    if (typeof setupExercisesListener === 'function') {
      setupExercisesListener();
    }
    if (typeof setupPlansListener === 'function') {
      setupPlansListener();
    }
    if (typeof setupScheduleListener === 'function') {
      setupScheduleListener();
    }
    if (typeof setupSessionTemplatesListener === 'function') {
      setupSessionTemplatesListener();
    }
    if (typeof setProgress === 'function') setProgress(90);

    if (typeof checkActiveWorkout === 'function') {
      checkActiveWorkout();
    }

    if (typeof setProgress === 'function') setProgress(100);
    if (typeof hideLoading === 'function') {
      setTimeout(() => hideLoading(), 200);
    }

    // Show onboarding for first-time / never-seen users
    if (typeof tryShowOnboardingAfterInit === 'function') {
      tryShowOnboardingAfterInit();
    }
  } catch (error) {
    console.error('❌ Error initializing app:', error);
    console.error('Error details:', error.message, error.stack);
  if (typeof showEdgeFeedback === 'function') {
    showEdgeFeedback('error', t('errors.appLoadFailed') + '\n\nDetails: ' + error.message);
  }
    if (typeof setProgress === 'function') setProgress(100);
    if (typeof hideLoading === 'function') {
      setTimeout(() => hideLoading(), 200);
    }
  }
}

/**
 * Initialize authentication and app
 */
async function init() {
  console.log('🔐 Initializing authentication...');
  initBottomNav();

  try {
    // Initialize auth listener
    await window.authModule.initAuth();

    // Subscribe to auth state changes
    window.authModule.onAuthStateChange((user, state) => {
      console.log('🔐 Auth state changed:', state, user?.email);

      if (state === window.authModule.AUTH_STATES.LOGGED_IN) {
        // User is authenticated and allowed - show app
        window.authModule.showMainApp();
        updateProfileInfo(user);
        initApp(); // Initialize app data
      } else if (state === window.authModule.AUTH_STATES.LOGGED_OUT ||
                 state === window.authModule.AUTH_STATES.ACCESS_DENIED) {
        // User is not authenticated or not allowed - show login
        window.authModule.showLoginScreen();
      }
    });

    console.log('✅ Auth initialized successfully!');
  } catch (error) {
    console.error('❌ Error initializing auth:', error);
    // Show login screen on error
    window.authModule.showLoginScreen();
  }
}

// ========================================
// CLOSE MODAL ON OUTSIDE CLICK
// ========================================

document.addEventListener('click', (e) => {
  const modal = document.getElementById('exercise-modal');
  if (e.target === modal) {
    closeExerciseModal();
  }
});

// ========================================
// SERVICE WORKER REGISTRATION
// ========================================

// Only register Service Worker in production (not on localhost/127.0.0.1)
const isLocalhost = window.location.hostname === 'localhost' ||
                    window.location.hostname === '127.0.0.1' ||
                    window.location.hostname === '';

if ('serviceWorker' in navigator && !isLocalhost) {
  let _hasReloadedForUpdate = false;
  let _initialControllerSet = !!navigator.serviceWorker.controller;

  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('/sw.js')
      .then((registration) => {
        console.log('✅ Service Worker registered:', registration.scope);

        // Detect a new SW becoming available (after a code deploy)
        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing;
          if (!newWorker) return;
          newWorker.addEventListener('statechange', () => {
            if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
              // A previous SW exists AND a new one is now installed → tell it to take over
              console.log('🔄 New Service Worker installed, activating…');
              newWorker.postMessage('SKIP_WAITING');
            }
          });
        });

        // Periodically poll for updates while the app is open (every 30 minutes)
        setInterval(() => registration.update().catch(() => {}), 30 * 60 * 1000);
      })
      .catch((error) => {
        console.error('❌ Service Worker registration failed:', error);
      });

    // When the new SW takes control, reload once to pick up the fresh assets
    navigator.serviceWorker.addEventListener('controllerchange', () => {
      if (_hasReloadedForUpdate) return;
      // Skip the initial controllerchange that fires the very first time the SW
      // takes control of an uncontrolled page (no reload needed there).
      if (!_initialControllerSet) {
        _initialControllerSet = true;
        return;
      }
      _hasReloadedForUpdate = true;
      console.log('🚀 New Service Worker activated — reloading with fresh assets');
      window.location.reload();
    });
  });
} else if (isLocalhost) {
  console.log('🔧 Development mode: Service Worker registration skipped');
}

// ========================================
// VISIBILITY-BASED RECALCULATION
// ========================================

let lastVisibleDateKey = new Date().toISOString().slice(0, 10);

document.addEventListener('visibilitychange', () => {
  if (document.visibilityState !== 'visible') return;

  const today = new Date().toISOString().slice(0, 10);
  if (today === lastVisibleDateKey) return;

  lastVisibleDateKey = today;
  console.log('📅 Day changed since last visit, refreshing dashboard...');

  if (typeof refreshDashboard === 'function') {
    refreshDashboard();
  }
  if (typeof renderProgressV3 === 'function') {
    renderProgressV3();
  }
});

// ========================================
// VERSION CHECK (PWA Update Detection)
// ========================================

function checkAppVersion() {
  fetch('/version.json', { cache: 'no-store' })
    .then((response) => response.json())
    .then((data) => {
      const serverVersion = data.version;
      const localVersion = localStorage.getItem('app_version');

      if (!localVersion) {
        // Erster Besuch — Version speichern, kein Reload
        console.log('📦 App Version gespeichert:', serverVersion);
        localStorage.setItem('app_version', serverVersion);
        return;
      }

      if (localVersion !== serverVersion) {
        console.log('🔄 Version Mismatch! Lokal:', localVersion, '→ Server:', serverVersion);
        localStorage.setItem('app_version', serverVersion);

        // Service Worker Cache löschen
        if ('caches' in window) {
          caches.keys().then((names) => {
            return Promise.all(names.map((name) => caches.delete(name)));
          }).then(() => {
            console.log('🗑️ Cache gelöscht, lade neu...');
            window.location.reload(true);
          });
        } else {
          window.location.reload(true);
        }
      } else {
        console.log('✅ App ist aktuell (Version ' + serverVersion + ')');
      }
    })
    .catch((error) => {
      console.warn('⚠️ Version-Check fehlgeschlagen:', error);
    });
}

checkAppVersion();

// ========================================
// START APP WHEN DOM IS READY
// ========================================

document.addEventListener('DOMContentLoaded', init);

// ========================================
// DEV TOOLS (optional, nicht in Produktion geladen)
// ========================================
// Demo-Seeder & Debug-Helfer liegen unter js/dev/ und werden NUR geladen,
// wenn die App mit ?dev=1 aufgerufen wird oder localStorage.atemDevTools === '1'.
// Aktivieren:   ?dev=1  (wird gemerkt)   |   Deaktivieren:  ?dev=0
// Verfuegbare Konsolen-Helfer danach: createDemoSessions(), createDemoProgressData(),
// deleteAllSessions(), deleteAllProgressData(), checkMyAllowlistStatus('mail@x.de')
(function loadDevTools() {
  const params = new URLSearchParams(window.location.search);
  if (params.has('dev')) {
    if (params.get('dev') === '0') localStorage.removeItem('atemDevTools');
    else localStorage.setItem('atemDevTools', '1');
  }
  if (localStorage.getItem('atemDevTools') !== '1') return;

  const devScripts = [
    'js/dev/checkAllowlist.js',
    'js/dev/createDemoProgress.js',
    'js/dev/createDemoSessions.js',
  ];
  devScripts.forEach((src) => {
    const s = document.createElement('script');
    s.src = src;
    s.defer = true;
    document.head.appendChild(s);
  });
  console.log('🛠️ ATEM Dev-Tools geladen (deaktivieren mit ?dev=0).');
})();
