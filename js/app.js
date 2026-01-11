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
  
  currentView = viewName;
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
  document.getElementById('fab-main').classList.add('active');
  document.getElementById('radial-menu').classList.add('active');
  document.getElementById('radial-overlay').classList.add('active');
  document.body.style.overflow = 'hidden';
}

function closeRadialMenu() {
  radialMenuOpen = false;
  document.getElementById('fab-main').classList.remove('active');
  document.getElementById('radial-menu').classList.remove('active');
  document.getElementById('radial-overlay').classList.remove('active');
  document.body.style.overflow = '';
}

// Close radial menu on escape
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    closeRadialMenu();
    closeExerciseModal();
  }
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