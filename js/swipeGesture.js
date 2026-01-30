// ==================== Horizontal Swipe Gesture for Tab Navigation ====================

/**
 * Enables horizontal swipe gestures for tab/segmented control navigation
 * - Works on touch devices (mobile Safari optimized)
 * - Does not interfere with vertical scrolling
 * - Threshold-based to avoid accidental triggers
 * - Calm, subtle animation
 */

const SWIPE_THRESHOLD = 50; // Minimum horizontal distance to trigger
const SWIPE_ANGLE_THRESHOLD = 30; // Max angle from horizontal (degrees)
const SWIPE_VELOCITY_THRESHOLD = 0.3; // Min velocity (px/ms) for quick swipes

// Track active swipe handlers to prevent duplicates
const swipeHandlers = new Map();

/**
 * Calculates angle from horizontal axis
 * @param {number} deltaX
 * @param {number} deltaY
 * @returns {number} Angle in degrees (0 = horizontal, 90 = vertical)
 */
function getSwipeAngle(deltaX, deltaY) {
  return Math.abs(Math.atan2(Math.abs(deltaY), Math.abs(deltaX)) * (180 / Math.PI));
}

/**
 * Initialize swipe gesture for a container with tabs
 * @param {Object} config
 * @param {string} config.containerId - ID of the swipeable content area
 * @param {string[]} config.tabs - Array of tab identifiers in order
 * @param {Function} config.getCurrentTab - Function that returns current tab ID
 * @param {Function} config.onSwipe - Callback(newTabId) when swipe completes
 * @param {string} [config.direction='horizontal'] - 'horizontal' or 'both'
 */
function initSwipeGesture(config) {
  const { containerId, tabs, getCurrentTab, onSwipe, direction = 'horizontal' } = config;

  const container = document.getElementById(containerId);
  if (!container) {
    console.warn(`[SwipeGesture] Container #${containerId} not found`);
    return null;
  }

  // Clean up existing handler if present
  if (swipeHandlers.has(containerId)) {
    destroySwipeGesture(containerId);
  }

  let touchStartX = 0;
  let touchStartY = 0;
  let touchCurrentX = 0;
  let touchCurrentY = 0;
  let touchStartTime = 0;
  let isTracking = false;
  let isHorizontalSwipe = null; // null = undecided, true/false = locked

  function handleTouchStart(e) {
    if (e.touches.length !== 1) return;

    touchStartX = e.touches[0].clientX;
    touchStartY = e.touches[0].clientY;
    touchCurrentX = touchStartX;
    touchCurrentY = touchStartY;
    touchStartTime = Date.now();
    isTracking = true;
    isHorizontalSwipe = null;
  }

  function handleTouchMove(e) {
    if (!isTracking || e.touches.length !== 1) return;

    touchCurrentX = e.touches[0].clientX;
    touchCurrentY = e.touches[0].clientY;

    const deltaX = touchCurrentX - touchStartX;
    const deltaY = touchCurrentY - touchStartY;

    // Lock direction once movement exceeds 10px
    if (isHorizontalSwipe === null && (Math.abs(deltaX) > 10 || Math.abs(deltaY) > 10)) {
      const angle = getSwipeAngle(deltaX, deltaY);
      isHorizontalSwipe = angle < SWIPE_ANGLE_THRESHOLD;
    }

    // If horizontal swipe, prevent vertical scroll
    if (isHorizontalSwipe === true) {
      e.preventDefault();

      // Apply subtle visual feedback (transform)
      const dampedDelta = deltaX * 0.15;
      const maxDelta = 30;
      const clampedDelta = Math.max(-maxDelta, Math.min(maxDelta, dampedDelta));
      container.style.transform = `translateX(${clampedDelta}px)`;
      container.style.transition = 'none';
    }
  }

  function handleTouchEnd() {
    if (!isTracking) return;

    const deltaX = touchCurrentX - touchStartX;
    const deltaY = touchCurrentY - touchStartY;
    const duration = Date.now() - touchStartTime;
    const velocity = Math.abs(deltaX) / duration;

    // Reset visual state with smooth transition
    container.style.transition = 'transform 0.2s ease-out';
    container.style.transform = '';

    // Check if valid horizontal swipe
    if (isHorizontalSwipe === true) {
      const currentTab = getCurrentTab();
      const currentIndex = tabs.indexOf(currentTab);

      // Determine if swipe is significant enough
      const isSignificant = Math.abs(deltaX) >= SWIPE_THRESHOLD ||
                           (velocity >= SWIPE_VELOCITY_THRESHOLD && Math.abs(deltaX) >= 30);

      if (isSignificant && currentIndex !== -1) {
        let newIndex;

        if (deltaX < 0) {
          // Swipe left -> next tab
          newIndex = Math.min(currentIndex + 1, tabs.length - 1);
        } else {
          // Swipe right -> previous tab
          newIndex = Math.max(currentIndex - 1, 0);
        }

        if (newIndex !== currentIndex) {
          const newTab = tabs[newIndex];
          onSwipe(newTab);
        }
      }
    }

    // Reset tracking
    isTracking = false;
    isHorizontalSwipe = null;
    touchStartX = 0;
    touchStartY = 0;
    touchCurrentX = 0;
    touchCurrentY = 0;

    // Clear transition after animation completes
    setTimeout(() => {
      container.style.transition = '';
    }, 200);
  }

  function handleTouchCancel() {
    container.style.transition = 'transform 0.2s ease-out';
    container.style.transform = '';
    isTracking = false;
    isHorizontalSwipe = null;

    setTimeout(() => {
      container.style.transition = '';
    }, 200);
  }

  // Attach listeners
  container.addEventListener('touchstart', handleTouchStart, { passive: true });
  container.addEventListener('touchmove', handleTouchMove, { passive: false });
  container.addEventListener('touchend', handleTouchEnd, { passive: true });
  container.addEventListener('touchcancel', handleTouchCancel, { passive: true });

  // Store handler reference for cleanup
  const handler = {
    container,
    handleTouchStart,
    handleTouchMove,
    handleTouchEnd,
    handleTouchCancel
  };
  swipeHandlers.set(containerId, handler);

  console.log(`[SwipeGesture] Initialized for #${containerId} with tabs:`, tabs);
  return handler;
}

/**
 * Destroy swipe gesture handler
 * @param {string} containerId
 */
function destroySwipeGesture(containerId) {
  const handler = swipeHandlers.get(containerId);
  if (!handler) return;

  const { container, handleTouchStart, handleTouchMove, handleTouchEnd, handleTouchCancel } = handler;

  container.removeEventListener('touchstart', handleTouchStart);
  container.removeEventListener('touchmove', handleTouchMove);
  container.removeEventListener('touchend', handleTouchEnd);
  container.removeEventListener('touchcancel', handleTouchCancel);

  container.style.transform = '';
  container.style.transition = '';

  swipeHandlers.delete(containerId);
  console.log(`[SwipeGesture] Destroyed for #${containerId}`);
}

/**
 * Initialize swipe for Progress tabs
 */
function initProgressSwipe() {
  initSwipeGesture({
    containerId: 'progress-tab-content',
    tabs: ['overview', 'strength', 'cardio'],
    getCurrentTab: () => currentProgressTab || 'overview',
    onSwipe: (newTab) => {
      if (typeof switchProgressTab === 'function') {
        switchProgressTab(newTab);
      }
    }
  });
}

/**
 * Initialize swipe for Training tabs (Plans/Exercises)
 */
function initTrainingSwipe() {
  initSwipeGesture({
    containerId: 'view-training',
    tabs: ['plans', 'exercises'],
    getCurrentTab: () => {
      // Determine current tab from DOM state
      const plansTab = document.querySelector('#training-segmented-control .segmented-btn[data-tab="plans"]');
      return plansTab && plansTab.classList.contains('active') ? 'plans' : 'exercises';
    },
    onSwipe: (newTab) => {
      if (typeof switchTrainingTab === 'function') {
        switchTrainingTab(newTab);
      }
    }
  });
}

/**
 * Initialize swipe for Calendar tabs (Month/Week)
 */
function initCalendarSwipe() {
  initSwipeGesture({
    containerId: 'view-calendar',
    tabs: ['month', 'week'],
    getCurrentTab: () => {
      const monthView = document.getElementById('calendar-month-view');
      return monthView && monthView.classList.contains('active') ? 'month' : 'week';
    },
    onSwipe: (newTab) => {
      if (typeof setCalendarView === 'function') {
        setCalendarView(newTab);
      }
    }
  });
}

/**
 * Initialize all swipe gestures when appropriate views are shown
 */
function initAllSwipeGestures() {
  // Progress view swipe
  if (document.getElementById('progress-tab-content')) {
    initProgressSwipe();
  }

  // Training view swipe
  if (document.getElementById('view-training')) {
    initTrainingSwipe();
  }

  // Calendar view swipe
  if (document.getElementById('view-calendar')) {
    initCalendarSwipe();
  }
}

// Auto-init when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    // Delay init to ensure views are rendered
    setTimeout(initAllSwipeGestures, 500);
  });
} else {
  setTimeout(initAllSwipeGestures, 500);
}

// Re-init on view changes (hook into showView if available)
const originalShowView = window.showView;
if (typeof originalShowView === 'function') {
  window.showView = function(viewName) {
    originalShowView(viewName);
    // Re-init swipes after view transition
    setTimeout(() => {
      if (viewName === 'progress') initProgressSwipe();
      if (viewName === 'training') initTrainingSwipe();
      if (viewName === 'calendar') initCalendarSwipe();
    }, 100);
  };
}

// Expose functions globally
window.initSwipeGesture = initSwipeGesture;
window.destroySwipeGesture = destroySwipeGesture;
window.initProgressSwipe = initProgressSwipe;
window.initTrainingSwipe = initTrainingSwipe;
window.initCalendarSwipe = initCalendarSwipe;
window.initAllSwipeGestures = initAllSwipeGestures;

console.log('👆 SwipeGesture module loaded');
