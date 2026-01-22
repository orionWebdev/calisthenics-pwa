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
  calendar: 'Kalender',
  plans: 'Trainingspläne',
  exercises: 'Übungen',
  workout: 'Workout',
  profile: 'Profil'
};

// View icons for FAB
const viewIcons = {
  dashboard: 'home',
  progress: 'trending_up',
  calendar: 'calendar_month',
  plans: 'assignment',
  exercises: 'fitness_center',
  workout: 'fitness_center',
  profile: 'account_circle'
};

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

  // Update mobile header title and icon
  const mobileTitle = document.getElementById('mobile-view-title');
  const mobileIcon = document.getElementById('mobile-view-icon');
  if (mobileTitle) {
    mobileTitle.textContent = viewTitles[viewName] || viewName;
  }
  if (mobileIcon) {
    mobileIcon.textContent = viewIcons[viewName] || 'fitness_center';
  }

  // Update FAB icon based on current view
  updateFabIcon(viewName);

  // Load view-specific data
  if (viewName === 'calendar' && typeof loadSchedule === 'function') {
    loadSchedule();
  }

  // Initialize progress page when first opened
  if (viewName === 'progress') {
    if (typeof initProgressV2 === 'function') {
      initProgressV2();
    } else if (typeof initProgress === 'function') {
      initProgress();
    }
  }

  if (viewName === 'workout' && typeof renderWorkoutScreen === 'function') {
    renderWorkoutScreen();
  }

  currentView = viewName;
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

  fabMain.classList.add('active');
  document.getElementById('radial-menu').classList.add('active');
  document.getElementById('radial-overlay').classList.add('active');
  document.body.style.overflow = 'hidden';

  // Change FAB icon to close (add)
  if (fabIcon) {
    fabIcon.textContent = 'add';
  }

  // Haptic feedback (if available)
  if ('vibrate' in navigator) {
    navigator.vibrate(10);
  }
}

function closeRadialMenu() {
  radialMenuOpen = false;
  const fabMain = document.getElementById('fab-main');

  fabMain.classList.remove('active');
  document.getElementById('radial-menu').classList.remove('active');
  document.getElementById('radial-overlay').classList.remove('active');
  document.body.style.overflow = '';

  // Restore FAB icon to current view icon
  updateFabIcon(currentView);

  // Haptic feedback (if available)
  if ('vibrate' in navigator) {
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

  const nameElement = document.getElementById('profile-user-name');
  const emailElement = document.getElementById('profile-user-email');

  if (nameElement) {
    nameElement.textContent = user.displayName || 'Benutzer';
  }

  if (emailElement) {
    emailElement.textContent = user.email || '';
  }
}

// ========================================
// INITIALIZATION
// ========================================

async function initApp() {
  console.log('🚀 Initializing Calisthenics Pro...');

  try {
    // 1. Initialize default exercises if needed
    console.log('📦 Initializing default exercises...');
    await initializeDefaultExercises();

    // 2. Load exercises
    console.log('💪 Loading exercises...');
    await loadExercises();

    // 3. Load plans
    console.log('📋 Loading plans...');
    if (typeof loadPlans === 'function') {
      await loadPlans();
    } else {
      console.warn('⚠️ loadPlans function not found');
    }

    // 4. Load calendar schedule
    console.log('📅 Loading schedule...');
    if (typeof loadSchedule === 'function') {
      await loadSchedule();
    } else {
      console.warn('⚠️ loadSchedule function not found');
    }

    // 5. Setup real-time listeners
    console.log('🔄 Setting up real-time listeners...');
    if (typeof setupExercisesListener === 'function') {
      setupExercisesListener();
    }
    if (typeof setupPlansListener === 'function') {
      setupPlansListener();
    }
    if (typeof setupScheduleListener === 'function') {
      setupScheduleListener();
    }

    if (typeof checkActiveWorkout === 'function') {
      checkActiveWorkout();
    }

    console.log('✅ App initialized successfully!');
  } catch (error) {
    console.error('❌ Error initializing app:', error);
    console.error('Error details:', error.message, error.stack);
    alert('Fehler beim Laden der App. Bitte Seite neu laden.\n\nDetails: ' + error.message);
  }
}

/**
 * Initialize authentication and app
 */
async function init() {
  console.log('🔐 Initializing authentication...');

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
  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('/sw.js')
      .then((registration) => {
        console.log('✅ Service Worker registered successfully:', registration.scope);
      })
      .catch((error) => {
        console.error('❌ Service Worker registration failed:', error);
      });
  });
} else if (isLocalhost) {
  console.log('🔧 Development mode: Service Worker registration skipped');
}

// ========================================
// START APP WHEN DOM IS READY
// ========================================

document.addEventListener('DOMContentLoaded', init);
