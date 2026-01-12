// ========================================
// MAIN APP LOGIC
// ========================================

// Current active view
let currentView = 'exercises';
let radialMenuOpen = false;

// View titles for mobile
const viewTitles = {
  exercises: 'Übungen',
  plans: 'Pläne',
  calendar: 'Kalender',
  progress: 'Progress'
};

// View icons for FAB
const viewIcons = {
  exercises: 'fitness_center',
  plans: 'assignment',
  calendar: 'calendar_month',
  progress: 'trending_up'
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

  // Update mobile title
  const mobileTitle = document.getElementById('mobile-view-title');
  if (mobileTitle) {
    mobileTitle.textContent = viewTitles[viewName] || viewName;
  }

  // Update FAB icon based on current view
  updateFabIcon(viewName);

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
// INITIALIZATION
// ========================================

async function init() {
  console.log('🚀 Initializing Calisthenics Pro...');
  
  try {
    // 1. Initialize default exercises if needed
    await initializeDefaultExercises();
    
    // 2. Load exercises
    await loadExercises();
    
    // 3. Load calendar schedule
    await loadSchedule();
    
    // 4. Setup real-time listeners
    setupExercisesListener();
    setupScheduleListener();
    
    console.log('✅ App initialized successfully!');
  } catch (error) {
    console.error('❌ Error initializing app:', error);
    alert('Fehler beim Laden der App. Bitte Seite neu laden.');
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
// START APP WHEN DOM IS READY
// ========================================

document.addEventListener('DOMContentLoaded', init);