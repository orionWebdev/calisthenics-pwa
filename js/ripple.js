// ========================================
// PRESSABLE RIPPLE - Touch Feedback Utility
// ========================================

/**
 * Creates a ripple effect at the pointer/touch location
 * @param {HTMLElement} element - The element to add ripple to
 * @param {PointerEvent|MouseEvent} event - The pointer event
 * @param {Object} options - Optional configuration
 */
function createRipple(element, event, options = {}) {
  const {
    color = 'rgba(255, 255, 255, 0.2)',
    duration = 500,
    scale = 2.2
  } = options;

  const rect = element.getBoundingClientRect();

  // Calculate ripple origin from pointer position
  const x = event.clientX - rect.left;
  const y = event.clientY - rect.top;

  // Ripple size: use max dimension * scale for full coverage
  const size = Math.max(rect.width, rect.height) * scale;

  // Create ripple element
  const ripple = document.createElement('span');
  ripple.className = 'ripple-effect';
  ripple.style.cssText = `
    position: absolute;
    left: ${x - size / 2}px;
    top: ${y - size / 2}px;
    width: ${size}px;
    height: ${size}px;
    background: ${color};
    border-radius: 50%;
    transform: scale(0);
    opacity: 1;
    pointer-events: none;
    animation: ripple-expand ${duration}ms cubic-bezier(0.4, 0, 0.2, 1) forwards;
  `;

  element.appendChild(ripple);

  // Remove ripple after animation
  setTimeout(() => {
    ripple.remove();
  }, duration);
}

/**
 * Makes an element pressable with ripple effect
 * @param {HTMLElement} element - The element to make pressable
 * @param {Object} options - Configuration options
 */
function makePressable(element, options = {}) {
  if (!element || element.dataset.pressable === 'true') return;

  // Skip elements inside modals to prevent unwanted click animations
  if (element.closest('.modal')) return;

  const {
    color = 'rgba(255, 255, 255, 0.15)',
    duration = 450,
    scale = 2.2
  } = options;

  // Ensure element has proper positioning for ripple
  const computedStyle = window.getComputedStyle(element);
  if (computedStyle.position === 'static') {
    element.style.position = 'relative';
  }
  element.style.overflow = 'hidden';

  // Add pointerdown listener for immediate feedback
  element.addEventListener('pointerdown', (event) => {
    // Don't create ripple if element is disabled
    if (element.disabled || element.classList.contains('disabled')) return;

    createRipple(element, event, { color, duration, scale });
  });

  // Mark as pressable to avoid duplicate listeners
  element.dataset.pressable = 'true';
}

/**
 * Initialize ripple effects on all matching elements
 */
function initRippleEffects() {
  // Desktop navigation buttons
  document.querySelectorAll('.nav-btn').forEach(btn => {
    makePressable(btn, { color: 'rgba(240, 34, 119, 0.2)' });
  });

  // Segmented control buttons (all types)
  document.querySelectorAll('.segmented-btn').forEach(btn => {
    makePressable(btn, { color: 'rgba(255, 255, 255, 0.15)' });
  });

  // Segmented control containers
  document.querySelectorAll('.segmented-control').forEach(control => {
    // Don't make container pressable, only buttons inside
  });

  // Metric toggle buttons
  document.querySelectorAll('.metric-btn').forEach(btn => {
    makePressable(btn, { color: 'rgba(255, 255, 255, 0.15)' });
  });

  // Period toggle buttons (progress period selector)
  document.querySelectorAll('.period-btn').forEach(btn => {
    makePressable(btn, { color: 'rgba(255, 255, 255, 0.15)' });
  });

  // Dashboard toggle buttons
  document.querySelectorAll('.dashboard-toggle-btn').forEach(btn => {
    makePressable(btn, { color: 'rgba(255, 255, 255, 0.15)' });
  });

  // Primary/CTA buttons - including gradient buttons in training view
  document.querySelectorAll('.btn-primary, .dashboard-primary-btn, .progress-cta-btn').forEach(btn => {
    makePressable(btn, { color: 'rgba(255, 255, 255, 0.2)' });
  });

  // Gradient action buttons (New Plan, New Exercise buttons)
  document.querySelectorAll('button[onclick*="openAddPlanModal"], button[onclick*="openAddExerciseModal"]').forEach(btn => {
    makePressable(btn, { color: 'rgba(255, 255, 255, 0.25)' });
  });

  // All buttons with gradient background
  document.querySelectorAll('.bg-gradient-to-r').forEach(btn => {
    if (btn.tagName === 'BUTTON') {
      makePressable(btn, { color: 'rgba(255, 255, 255, 0.2)' });
    }
  });

  // Secondary buttons
  document.querySelectorAll('.btn-secondary, .modal-cancel-btn').forEach(btn => {
    makePressable(btn, { color: 'rgba(255, 255, 255, 0.1)' });
  });

  // Floating add buttons
  document.querySelectorAll('.floating-add-btn').forEach(btn => {
    makePressable(btn, { color: 'rgba(255, 255, 255, 0.25)' });
  });

  // Picker items
  document.querySelectorAll('.picker-item').forEach(item => {
    makePressable(item, { color: 'rgba(255, 255, 255, 0.1)' });
  });

  // Activity day cells
  document.querySelectorAll('.activity-day:not(.other-month)').forEach(day => {
    makePressable(day, { color: 'rgba(255, 255, 255, 0.1)' });
  });

  // Dashboard session items
  document.querySelectorAll('.dashboard-session-item').forEach(item => {
    makePressable(item, { color: 'rgba(255, 255, 255, 0.08)' });
  });

  // Dashboard balance card
  document.querySelectorAll('.dashboard-balance-card').forEach(card => {
    makePressable(card, { color: 'rgba(255, 255, 255, 0.05)' });
  });

  // Filter chips
  document.querySelectorAll('.filter-chip').forEach(chip => {
    makePressable(chip, { color: 'rgba(255, 255, 255, 0.1)' });
  });

  // Difficulty buttons
  document.querySelectorAll('.difficulty-btn, .plan-difficulty-btn').forEach(btn => {
    makePressable(btn, { color: 'rgba(255, 255, 255, 0.15)' });
  });

  // Modal save/action buttons
  document.querySelectorAll('.modal-save-btn').forEach(btn => {
    makePressable(btn, { color: 'rgba(255, 255, 255, 0.2)' });
  });

  // Calendar navigation buttons
  document.querySelectorAll('.cal-nav-btn').forEach(btn => {
    makePressable(btn, { color: 'rgba(255, 255, 255, 0.1)' });
  });

  // Overview/Progress stat cards
  document.querySelectorAll('.overview-stat-card, .progress-stat-card').forEach(card => {
    makePressable(card, { color: 'rgba(255, 255, 255, 0.05)' });
  });

  // Activity picker button
  document.querySelectorAll('.activity-picker-btn, .exercise-picker-btn').forEach(btn => {
    makePressable(btn, { color: 'rgba(255, 255, 255, 0.1)' });
  });
}

/**
 * Re-initialize ripples on dynamically added content
 * Call this after rendering new content
 */
function refreshRippleEffects() {
  initRippleEffects();
}

// Initialize on DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initRippleEffects);
} else {
  initRippleEffects();
}

// Also initialize after view changes (MutationObserver for dynamic content)
const rippleObserver = new MutationObserver((mutations) => {
  let shouldRefresh = false;
  mutations.forEach((mutation) => {
    if (mutation.addedNodes.length > 0) {
      shouldRefresh = true;
    }
  });
  if (shouldRefresh) {
    // Debounce refresh
    clearTimeout(window.rippleRefreshTimer);
    window.rippleRefreshTimer = setTimeout(refreshRippleEffects, 100);
  }
});

// Start observing once DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    rippleObserver.observe(document.body, {
      childList: true,
      subtree: true
    });
  });
} else {
  rippleObserver.observe(document.body, {
    childList: true,
    subtree: true
  });
}

// Expose functions globally
window.createRipple = createRipple;
window.makePressable = makePressable;
window.refreshRippleEffects = refreshRippleEffects;

console.log('Ripple effects module loaded');
