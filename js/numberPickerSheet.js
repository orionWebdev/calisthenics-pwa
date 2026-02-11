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
  onCancel: null
};

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
  weight: {
    min: 0,
    max: 250,
    step: 2.5,
    suffix: 'kg',
    titleKey: 'numberPicker.weightTitle',
    generateValues: () => {
      const values = [];
      for (let i = 0; i <= 250; i += 2.5) {
        values.push(i);
      }
      return values;
    }
  },
  hold: {
    min: 0,
    max: 600,
    step: 1,
    suffixKey: 'common.secondsShort',
    titleKey: 'numberPicker.holdTitle',
    generateValues: () => Array.from({ length: 601 }, (_, i) => i)
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
