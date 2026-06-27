// ========================================
// NUMBER PICKER SHEET - iOS-like Wheel Picker
// ========================================

/**
 * Configuration state for the number picker
 */
const numberPickerConfig = {
  isOpen: false,
  type: null,           // 'reps' | 'weight' | 'hold'
  currentValue: 0,
  onConfirm: null,
  onCancel: null,
  modeToggle: null      // { reps: <number>, hold: <number> } — enables the Wdh/Halten tab strip
};

// ---- Weight step mode (2.5 / 1.0 / 0.5 kg, persisted) ----------------------
// Three step modes for weight increment: cycles via double-tap on the weight
// value in the active set, or via the tab strip inside the number-picker sheet.
// Imperial mirrors with 5 / 2.5 / 1 lbs. Index is persisted; the actual step
// value is derived from the unit system at read time.

const WEIGHT_STEP_MODES_METRIC   = [2.5, 1.0, 0.5];
const WEIGHT_STEP_MODES_IMPERIAL = [5,   2.5, 1];
const WEIGHT_STEP_STORAGE_KEY = 'workout.weightStepModeIdx';

let _weightStepModeIdx = (() => {
  const raw = parseInt(localStorage.getItem(WEIGHT_STEP_STORAGE_KEY), 10);
  return (isNaN(raw) || raw < 0 || raw > 2) ? 0 : raw;
})();

function isImperialUnit() {
  return typeof userProfile !== 'undefined' && userProfile && userProfile.unitSystem === 'imperial';
}

function getWeightStepModes() {
  return isImperialUnit() ? WEIGHT_STEP_MODES_IMPERIAL : WEIGHT_STEP_MODES_METRIC;
}

function getWeightStepModeIdx() {
  return _weightStepModeIdx;
}

function getWeightStep() {
  const modes = getWeightStepModes();
  return modes[_weightStepModeIdx] ?? modes[0];
}

function setWeightStepModeIdx(idx) {
  if (idx < 0 || idx > 2) return;
  _weightStepModeIdx = idx;
  try { localStorage.setItem(WEIGHT_STEP_STORAGE_KEY, String(idx)); } catch (e) { /* ignore */ }
}

function cycleWeightStepMode() {
  setWeightStepModeIdx((_weightStepModeIdx + 1) % 3);
  return _weightStepModeIdx;
}

/** Format a step value for tab labels: `2,5` not `2.5`, drop trailing `.0`. */
function formatStepLabel(step) {
  if (step % 1 === 0) return String(Math.round(step));
  return String(step).replace('.', ',');
}

window.getWeightStep = getWeightStep;
window.getWeightStepModeIdx = getWeightStepModeIdx;
window.setWeightStepModeIdx = setWeightStepModeIdx;
window.cycleWeightStepMode = cycleWeightStepMode;
window.getWeightStepModes = getWeightStepModes;

/**
 * Picker type configurations
 */
const PICKER_CONFIGS = {
  reps: {
    min: 0,
    max: 100,
    step: 1,
    suffix: 'Wdh',
    titleKey: 'numberPicker.repsTitle',
    generateValues: () => Array.from({ length: 101 }, (_, i) => i)
  },
  get weight() {
    const isImperial = isImperialUnit();
    const max = isImperial ? 550 : 250;
    const step = getWeightStep();
    const count = Math.floor(max / step) + 1;
    return {
      min: 0,
      max,
      step,
      suffix: isImperial ? 'lbs' : 'kg',
      titleKey: 'numberPicker.weightTitle',
      generateValues: () => {
        const values = [];
        for (let i = 0; i < count; i++) {
          // Round to 1 decimal to dodge float-accumulation noise
          values.push(Math.round(i * step * 10) / 10);
        }
        return values;
      }
    };
  },
  hold: {
    min: 0,
    max: 600,
    step: 1,
    suffixKey: 'common.secondsShort',
    titleKey: 'numberPicker.holdTitle',
    generateValues: () => Array.from({ length: 601 }, (_, i) => i)
  },
  sets: {
    min: 1,
    max: 10,
    step: 1,
    suffixKey: 'workout.logging.set',
    titleKey: 'numberPicker.setsTitle',
    generateValues: () => Array.from({ length: 10 }, (_, i) => i + 1)
  },
  bodyWeightKg: {
    min: 30,
    max: 200,
    step: 0.5,
    suffix: 'kg',
    titleKey: 'profile.bodyWeight',
    generateValues: () => {
      const values = [];
      for (let i = 30; i <= 200; i += 0.5) values.push(i);
      return values;
    }
  },
  bodyWeightLbs: {
    min: 66,
    max: 440,
    step: 1,
    suffix: 'lbs',
    titleKey: 'profile.bodyWeight',
    generateValues: () => Array.from({ length: 375 }, (_, i) => i + 66)
  },
  bodyHeight: {
    min: 100,
    max: 220,
    step: 1,
    suffix: 'cm',
    titleKey: 'profile.bodyHeight',
    generateValues: () => Array.from({ length: 121 }, (_, i) => i + 100)
  },
  restTimer: {
    min: 10,
    max: 300,
    step: 5,
    suffix: 's',
    titleKey: 'settings.defaultRestTimer',
    generateValues: () => {
      const values = [];
      for (let i = 10; i <= 300; i += 5) values.push(i);
      return values;
    }
  },
  workoutDuration: {
    min: 1,
    max: 360,
    step: 1,
    suffix: 'min',
    titleKey: 'workout.postWorkout.editDuration',
    generateValues: () => Array.from({ length: 360 }, (_, i) => i + 1)
  }
};

/**
 * Opens the number picker sheet
 * @param {Object} config - Configuration object
 * @param {'reps'|'weight'} config.type - Picker type
 * @param {number} config.initialValue - Initial value to display
 * @param {Function} config.onConfirm - Callback when confirmed with value
 * @param {Function} [config.onCancel] - Callback when cancelled
 */
function openNumberPicker(config) {
  const typeConfig = PICKER_CONFIGS[config.type];
  if (!typeConfig) {
    console.error('Unknown picker type:', config.type);
    return;
  }

  // Clamp initial value to valid range
  let initialValue = config.initialValue ?? typeConfig.min;
  if (config.type === 'weight') {
    // Round to nearest step for weight
    initialValue = Math.round(initialValue / typeConfig.step) * typeConfig.step;
  }
  initialValue = Math.max(typeConfig.min, Math.min(typeConfig.max, initialValue));

  numberPickerConfig.isOpen = true;
  numberPickerConfig.type = config.type;
  numberPickerConfig.currentValue = initialValue;
  numberPickerConfig.onConfirm = config.onConfirm;
  numberPickerConfig.onCancel = config.onCancel;
  numberPickerConfig.modeToggle = config.modeToggle || null;

  renderNumberPickerSheet();
  showNumberPickerSheet();
}

/**
 * Closes the number picker sheet
 * @param {boolean} confirmed - Whether the selection was confirmed
 */
function closeNumberPicker(confirmed = false) {
  if (!numberPickerConfig.isOpen) return;

  if (confirmed && numberPickerConfig.onConfirm) {
    numberPickerConfig.onConfirm(numberPickerConfig.currentValue);
  } else if (!confirmed && numberPickerConfig.onCancel) {
    numberPickerConfig.onCancel();
  }

  hideNumberPickerSheet();
  numberPickerConfig.isOpen = false;
}

/**
 * Renders the number picker sheet DOM
 */
function renderNumberPickerSheet() {
  // Remove existing sheet
  const existing = document.getElementById('number-picker-overlay');
  if (existing) existing.remove();

  const typeConfig = PICKER_CONFIGS[numberPickerConfig.type];
  const values = typeConfig.generateValues();
  const title = typeof t === 'function' ? t(typeConfig.titleKey) : typeConfig.titleKey;
  const cancelText = typeof t === 'function' ? t('common.cancel') : 'Abbrechen';
  const suffix = typeConfig.suffixKey
    ? (typeof t === 'function' ? t(typeConfig.suffixKey, { n: '' }) : '')
    : (typeConfig.suffix || '');

  // Top tab strip: weight → step-mode tabs (2,5 / 1 / 0,5);
  // reps/hold with a modeToggle → set-type tabs (Wdh / Halten)
  const showStepTabs = numberPickerConfig.type === 'weight';
  const showModeTabs = !showStepTabs && !!numberPickerConfig.modeToggle;
  const stepTabsHTML = showStepTabs
    ? renderStepModeTabs()
    : (showModeTabs ? renderSetModeTabs() : '');

  const overlay = document.createElement('div');
  overlay.id = 'number-picker-overlay';
  overlay.className = 'number-picker-overlay';
  overlay.setAttribute('role', 'dialog');
  overlay.setAttribute('aria-modal', 'true');
  overlay.setAttribute('aria-labelledby', 'number-picker-title');

  overlay.innerHTML = `
    <div class="number-picker-sheet" id="number-picker-sheet">
      <!-- Drag Handle -->
      <div class="number-picker-drag-handle"></div>

      <!-- Header -->
      <div class="number-picker-header">
        <h3 id="number-picker-title" class="number-picker-title">${title}</h3>
      </div>

      ${stepTabsHTML}

      <!-- Wheel Content -->
      <div class="number-picker-content">
        <div class="number-picker-highlight" aria-hidden="true"></div>
        <div class="number-picker-wheel" id="number-picker-wheel">
          ${values.map(value => {
            const displayValue = numberPickerConfig.type === 'weight' && value % 1 !== 0
              ? value.toFixed(1).replace('.', ',')
              : value;
            return `
              <div
                class="number-picker-item ${value === numberPickerConfig.currentValue ? 'selected' : ''}"
                data-value="${value}"
                role="option"
                aria-selected="${value === numberPickerConfig.currentValue}"
              >
                <span class="number-picker-value">${displayValue}</span>
                <span class="number-picker-suffix">${suffix}</span>
              </div>
            `;
          }).join('')}
        </div>
      </div>

      <!-- Footer with Confirm Button -->
      <div class="number-picker-footer">
        <button
          type="button"
          class="number-picker-confirm"
          onclick="closeNumberPicker(true)"
          aria-label="${typeof t === 'function' ? t('common.done') : 'Fertig'}"
        >
          <span class="material-symbols-rounded">check</span>
        </button>
      </div>
    </div>
  `;

  document.body.appendChild(overlay);
  setupNumberPickerEvents(overlay);
}

/**
 * Sets up event listeners for the picker
 */
function setupNumberPickerEvents(overlay) {
  const wheel = document.getElementById('number-picker-wheel');
  const sheet = document.getElementById('number-picker-sheet');
  if (!wheel || !sheet) return;

  // Click outside to close
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) {
      closeNumberPicker(false);
    }
  });

  // Escape to close
  const handleEscape = (e) => {
    if (e.key === 'Escape') {
      closeNumberPicker(false);
      document.removeEventListener('keydown', handleEscape);
    }
  };
  document.addEventListener('keydown', handleEscape);

  // Swipe-to-close functionality
  let startY = 0;
  let currentY = 0;
  let isDragging = false;

  const dragHandle = sheet.querySelector('.number-picker-drag-handle');
  const header = sheet.querySelector('.number-picker-header');

  const handleTouchStart = (e) => {
    startY = e.touches[0].clientY;
    currentY = startY;
    isDragging = true;
    sheet.style.transition = 'none';
  };

  const handleTouchMove = (e) => {
    if (!isDragging) return;
    currentY = e.touches[0].clientY;
    const deltaY = currentY - startY;

    // Only allow dragging down
    if (deltaY > 0) {
      sheet.style.transform = `translateY(${deltaY}px)`;
    }
  };

  const handleTouchEnd = () => {
    if (!isDragging) return;
    isDragging = false;
    sheet.style.transition = '';

    const deltaY = currentY - startY;
    // Close if dragged more than 100px down
    if (deltaY > 100) {
      closeNumberPicker(false);
    } else {
      sheet.style.transform = '';
    }
  };

  if (dragHandle) {
    dragHandle.addEventListener('touchstart', handleTouchStart, { passive: true });
    dragHandle.addEventListener('touchmove', handleTouchMove, { passive: true });
    dragHandle.addEventListener('touchend', handleTouchEnd);
  }
  if (header) {
    header.addEventListener('touchstart', handleTouchStart, { passive: true });
    header.addEventListener('touchmove', handleTouchMove, { passive: true });
    header.addEventListener('touchend', handleTouchEnd);
  }

  // Scroll end handler with debounce
  let scrollTimeout;

  wheel.addEventListener('scroll', () => {
    clearTimeout(scrollTimeout);
    scrollTimeout = setTimeout(() => {
      handleWheelScrollEnd(wheel);
    }, 80);
  }, { passive: true });

  // Item click handler
  wheel.querySelectorAll('.number-picker-item').forEach(item => {
    item.addEventListener('click', () => {
      const value = parseFloat(item.dataset.value);
      selectPickerValue(value);
      scrollToValue(wheel, value, true);
      if (typeof triggerHapticFeedback === 'function') {
        triggerHapticFeedback('light');
      }
    });
  });

  // Initial scroll to current value (after animation frame)
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      scrollToValue(wheel, numberPickerConfig.currentValue, false);
    });
  });

  // Step-mode tabs (only present for type === 'weight')
  setupStepModeTabs(overlay);
  // Set-type tabs (Wdh / Halten — only present when a modeToggle was passed)
  setupSetModeTabs(overlay);
}

/** HTML for the set-type tab strip — toggles the picker between Wdh and Halten. */
function renderSetModeTabs() {
  const current = numberPickerConfig.type; // 'reps' | 'hold'
  const repsLabel = typeof t === 'function' ? t('numberPicker.modeReps') : 'Wdh.';
  const holdLabel = typeof t === 'function' ? t('numberPicker.modeHold') : 'Halten';
  const modes = [
    { key: 'reps', label: repsLabel },
    { key: 'hold', label: holdLabel },
  ];
  return `
    <div class="number-picker-mode-tabs" role="tablist" aria-label="Satz-Typ">
      ${modes.map(m => `
        <button
          type="button"
          class="np-mode-tab${m.key === current ? ' active' : ''}"
          data-set-mode="${m.key}"
          role="tab"
          aria-selected="${m.key === current}"
        >${m.label}</button>
      `).join('')}
    </div>
  `;
}

/** Wire up the set-type tab strip — switches the picker between reps and hold. */
function setupSetModeTabs(overlay) {
  const tabs = overlay.querySelectorAll('[data-set-mode]');
  if (!tabs.length) return;

  tabs.forEach((btn) => {
    btn.addEventListener('click', () => {
      const mode = btn.dataset.setMode; // 'reps' | 'hold'
      if (mode === numberPickerConfig.type) return;
      switchPickerMode(mode);
      tabs.forEach((b) => {
        const isActive = b.dataset.setMode === mode;
        b.classList.toggle('active', isActive);
        b.setAttribute('aria-selected', isActive ? 'true' : 'false');
      });
      if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('selection');
    });
  });
}

/** Switch the picker between reps and hold in-place (rebuilds the wheel + title). */
function switchPickerMode(mode) {
  const typeConfig = PICKER_CONFIGS[mode];
  if (!typeConfig) return;

  numberPickerConfig.type = mode;

  // Seed the new mode's value from the modeToggle config
  const mt = numberPickerConfig.modeToggle || {};
  let initial = mode === 'hold' ? (mt.hold || 0) : (mt.reps || 0);
  initial = Math.max(typeConfig.min, Math.min(typeConfig.max, initial));
  numberPickerConfig.currentValue = initial;

  const titleEl = document.getElementById('number-picker-title');
  if (titleEl) {
    titleEl.textContent = typeof t === 'function' ? t(typeConfig.titleKey) : typeConfig.titleKey;
  }

  rebuildPickerWheel();
}

/** HTML for the step-mode tab strip — three buttons (2,5 / 1 / 0,5 kg). */
function renderStepModeTabs() {
  const modes = getWeightStepModes();
  const activeIdx = getWeightStepModeIdx();
  const unit = isImperialUnit() ? 'lbs' : 'kg';
  return `
    <div class="number-picker-mode-tabs" role="tablist" aria-label="Schritt">
      ${modes.map((step, idx) => `
        <button
          type="button"
          class="np-mode-tab${idx === activeIdx ? ' active' : ''}"
          data-step-idx="${idx}"
          role="tab"
          aria-selected="${idx === activeIdx}"
        >
          ${formatStepLabel(step)} ${unit}
        </button>
      `).join('')}
    </div>
  `;
}

/** Wire up the step-mode tab strip — re-renders the wheel on mode change. */
function setupStepModeTabs(overlay) {
  const tabs = overlay.querySelectorAll('.np-mode-tab');
  if (!tabs.length) return;

  tabs.forEach((btn) => {
    btn.addEventListener('click', () => {
      const idx = parseInt(btn.dataset.stepIdx, 10);
      if (isNaN(idx) || idx === getWeightStepModeIdx()) return;
      setWeightStepModeIdx(idx);
      // Update tab visuals
      tabs.forEach((b, i) => {
        const isActive = i === idx;
        b.classList.toggle('active', isActive);
        b.setAttribute('aria-selected', isActive ? 'true' : 'false');
      });
      // Rebuild the wheel for the new step size
      rebuildPickerWheel();
      if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('selection');
    });
  });
}

/** Rebuild the wheel items in-place after the step size changed. */
function rebuildPickerWheel() {
  const wheel = document.getElementById('number-picker-wheel');
  if (!wheel) return;

  const typeConfig = PICKER_CONFIGS[numberPickerConfig.type];
  const values = typeConfig.generateValues();

  // Snap currentValue to the nearest available value in the new step grid
  let nearest = values[0];
  let bestDelta = Math.abs(numberPickerConfig.currentValue - nearest);
  for (const v of values) {
    const delta = Math.abs(numberPickerConfig.currentValue - v);
    if (delta < bestDelta) {
      bestDelta = delta;
      nearest = v;
    }
  }
  numberPickerConfig.currentValue = nearest;

  const suffix = typeConfig.suffixKey
    ? (typeof t === 'function' ? t(typeConfig.suffixKey, { n: '' }) : '')
    : (typeConfig.suffix || '');
  wheel.innerHTML = values.map(value => {
    const displayValue = numberPickerConfig.type === 'weight' && value % 1 !== 0
      ? value.toFixed(1).replace('.', ',')
      : value;
    return `
      <div
        class="number-picker-item ${value === numberPickerConfig.currentValue ? 'selected' : ''}"
        data-value="${value}"
        role="option"
        aria-selected="${value === numberPickerConfig.currentValue}"
      >
        <span class="number-picker-value">${displayValue}</span>
        <span class="number-picker-suffix">${suffix}</span>
      </div>
    `;
  }).join('');

  // Reattach click listeners on the new items
  wheel.querySelectorAll('.number-picker-item').forEach(item => {
    item.addEventListener('click', () => {
      const value = parseFloat(item.dataset.value);
      selectPickerValue(value);
      scrollToValue(wheel, value, true);
      if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('light');
    });
  });

  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      scrollToValue(wheel, numberPickerConfig.currentValue, false);
    });
  });
}

/**
 * Handles scroll end - snaps to nearest value
 */
function handleWheelScrollEnd(wheel) {
  const itemHeight = 56;
  const scrollTop = wheel.scrollTop;

  // With border-box and padding-top matching centerOffset,
  // scrollTop directly maps to item index (scroll-snap centers items)
  const nearestIndex = Math.round(scrollTop / itemHeight);

  const items = wheel.querySelectorAll('.number-picker-item');
  const clampedIndex = Math.max(0, Math.min(items.length - 1, nearestIndex));

  if (clampedIndex >= 0 && clampedIndex < items.length) {
    const newValue = parseFloat(items[clampedIndex].dataset.value);

    // Only update if value changed
    if (newValue !== numberPickerConfig.currentValue) {
      selectPickerValue(newValue);
      if (typeof triggerHapticFeedback === 'function') {
        triggerHapticFeedback('selection');
      }
    }
  }
}

/**
 * Scrolls the wheel to a specific value
 */
function scrollToValue(wheel, value, smooth = true) {
  const items = wheel.querySelectorAll('.number-picker-item');
  const itemHeight = 56;

  let targetIndex = 0;
  items.forEach((item, index) => {
    if (parseFloat(item.dataset.value) === value) {
      targetIndex = index;
    }
  });

  // scrollTop = index * itemHeight centers the item in the highlight
  // (padding-top ensures the first item can be scrolled to center)
  const targetScroll = targetIndex * itemHeight;

  if (smooth) {
    wheel.scrollTo({
      top: Math.max(0, targetScroll),
      behavior: 'smooth'
    });
  } else {
    wheel.scrollTop = Math.max(0, targetScroll);
  }
}

/**
 * Updates the selected value and visual state
 */
function selectPickerValue(value) {
  numberPickerConfig.currentValue = value;

  // Update visual selection
  document.querySelectorAll('.number-picker-item').forEach(item => {
    const isSelected = parseFloat(item.dataset.value) === value;
    item.classList.toggle('selected', isSelected);
    item.setAttribute('aria-selected', isSelected.toString());
  });
}

/**
 * Shows the picker sheet with animation
 */
function showNumberPickerSheet() {
  const overlay = document.getElementById('number-picker-overlay');
  if (!overlay) return;

  // Prevent body scroll
  document.body.style.overflow = 'hidden';

  // Trigger animation
  requestAnimationFrame(() => {
    overlay.classList.add('active');
  });

  if (typeof triggerHapticFeedback === 'function') {
    triggerHapticFeedback('light');
  }
}

/**
 * Hides the picker sheet with animation
 */
function hideNumberPickerSheet() {
  const overlay = document.getElementById('number-picker-overlay');
  if (!overlay) return;

  overlay.classList.remove('active');

  // Remove after animation
  setTimeout(() => {
    overlay.remove();
    document.body.style.overflow = '';
  }, 300);
}

// Export for global access
window.openNumberPicker = openNumberPicker;
window.closeNumberPicker = closeNumberPicker;
