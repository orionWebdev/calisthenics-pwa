// ========================================
// MAIN APP LOGIC
// ========================================

// Current active view
let currentView = 'exercises';

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
  
  // Update navigation buttons
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.classList.remove('active');
  });
  document.querySelector(`[data-view="${viewName}"]`).classList.add('active');
  
  currentView = viewName;
}

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
    
    // 3. Setup real-time listeners
    setupExercisesListener();
    
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
// ESC KEY TO CLOSE MODAL
// ========================================

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    closeExerciseModal();
  }
});

// ========================================
// START APP WHEN DOM IS READY
// ========================================

document.addEventListener('DOMContentLoaded', init);