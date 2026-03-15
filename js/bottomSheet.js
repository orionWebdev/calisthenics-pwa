// ==================== Multi-Select Bottom Sheet Component ====================

let bottomSheetConfig = {
  isOpen: false,
  currentField: null,
  options: [],
  selectedValues: [],
  onConfirm: null,
  enableSearch: false,
  title: 'Auswählen',
  searchPlaceholder: 'Suchen...',
  searchDebounceTimer: null
};

/**
 * Opens the bottom sheet with multi-select options
 * @param {Object} config Configuration object
 * @param {string} config.title - Title of the bottom sheet
 * @param {Array} config.options - Array of options {value, label, description?}
 * @param {Array} config.selectedValues - Array of currently selected values
 * @param {Function} config.onConfirm - Callback when user confirms selection
 * @param {boolean} config.enableSearch - Whether to show search input
 * @param {string} config.searchPlaceholder - Placeholder for search input
 * @param {string} config.fieldId - ID of the input field triggering this sheet
 */
function openBottomSheet(config) {
  bottomSheetConfig = {
    isOpen: true,
    currentField: config.fieldId || null,
    options: config.options || [],
    selectedValues: [...(config.selectedValues || [])],
    onConfirm: config.onConfirm || null,
    enableSearch: config.enableSearch !== false, // Default true
    title: config.title || 'Auswählen',
    searchPlaceholder: config.searchPlaceholder || 'Suchen...',
    searchDebounceTimer: null
  };

  // Update UI elements
  document.getElementById('bottom-sheet-title').textContent = bottomSheetConfig.title;

  // Configure search
  const searchContainer = document.getElementById('bottom-sheet-search');
  const searchInput = document.getElementById('bottom-sheet-search-input');

  if (bottomSheetConfig.enableSearch) {
    searchContainer.style.display = 'block';
    searchInput.placeholder = bottomSheetConfig.searchPlaceholder;
    searchInput.value = '';

    // Add search input listener
    searchInput.removeEventListener('input', handleBottomSheetSearch);
    searchInput.addEventListener('input', handleBottomSheetSearch);
  } else {
    searchContainer.style.display = 'none';
  }

  // Render options
  renderBottomSheetOptions();

  // Mark input field as active
  if (bottomSheetConfig.currentField) {
    const inputField = document.getElementById(bottomSheetConfig.currentField);
    if (inputField) {
      inputField.classList.add('active');
    }
  }

  // Show bottom sheet with animation
  const overlay = document.getElementById('bottom-sheet-overlay');
  overlay.classList.add('active');

  // Prevent body scroll
  document.body.style.overflow = 'hidden';

  // Focus search if enabled
  setTimeout(() => {
    if (bottomSheetConfig.enableSearch) {
      searchInput.focus();
    }
  }, 300);
}

/**
 * Closes the bottom sheet
 */
function closeBottomSheet() {
  const overlay = document.getElementById('bottom-sheet-overlay');
  overlay.classList.remove('active');

  // Remove active state from input field
  if (bottomSheetConfig.currentField) {
    const inputField = document.getElementById(bottomSheetConfig.currentField);
    if (inputField) {
      inputField.classList.remove('active');
    }
  }

  // Restore body scroll
  document.body.style.overflow = '';

  // Clear search
  document.getElementById('bottom-sheet-search-input').value = '';
  document.getElementById('bottom-sheet-search-clear').style.display = 'none';

  bottomSheetConfig.isOpen = false;
}

/**
 * Handles search input with debouncing
 */
function handleBottomSheetSearch(e) {
  const searchValue = e.target.value;
  const clearBtn = document.getElementById('bottom-sheet-search-clear');

  // Show/hide clear button
  clearBtn.style.display = searchValue ? 'flex' : 'none';

  // Debounce search
  if (bottomSheetConfig.searchDebounceTimer) {
    clearTimeout(bottomSheetConfig.searchDebounceTimer);
  }

  bottomSheetConfig.searchDebounceTimer = setTimeout(() => {
    filterBottomSheetOptions(searchValue);
  }, 300);
}

/**
 * Clears the search input
 */
function clearBottomSheetSearch() {
  const searchInput = document.getElementById('bottom-sheet-search-input');
  searchInput.value = '';
  searchInput.focus();
  document.getElementById('bottom-sheet-search-clear').style.display = 'none';
  renderBottomSheetOptions();
}

/**
 * Filters and renders options based on search term
 */
function filterBottomSheetOptions(searchTerm) {
  const normalizedSearch = searchTerm.toLowerCase().trim();

  if (!normalizedSearch) {
    renderBottomSheetOptions();
    return;
  }

  const filteredOptions = bottomSheetConfig.options.filter(option => {
    const labelMatch = option.label.toLowerCase().includes(normalizedSearch);
    const descMatch = option.description && option.description.toLowerCase().includes(normalizedSearch);
    return labelMatch || descMatch;
  });

  renderBottomSheetOptions(filteredOptions);
}

/**
 * Renders the options list in the bottom sheet
 */
function renderBottomSheetOptions(optionsToRender = null) {
  const content = document.getElementById('bottom-sheet-content');
  const options = optionsToRender || bottomSheetConfig.options;

  if (options.length === 0) {
    content.innerHTML = `
      <div class="bottom-sheet-empty">
        <span class="material-symbols-rounded">search_off</span>
        <p>Keine Optionen gefunden</p>
      </div>
    `;
    return;
  }

  content.innerHTML = options.map(option => {
    const isSelected = bottomSheetConfig.selectedValues.includes(option.value);
    const ariaLabel = `${option.label}${option.description ? ', ' + option.description : ''}${isSelected ? ', ausgewählt' : ''}`;
    const iconHtml = option.icon
      ? `<span class="bottom-sheet-option-icon"><img src="${option.icon}" alt="" /></span>`
      : '';
    return `
      <button
        type="button"
        class="bottom-sheet-option ${isSelected ? 'selected' : ''}"
        onclick="toggleBottomSheetOption('${option.value}')"
        role="listitem"
        aria-label="${ariaLabel}"
        aria-checked="${isSelected}"
      >
        ${iconHtml}
        <div class="bottom-sheet-option-content">
          <div class="bottom-sheet-option-label">${option.label}</div>
          ${option.description ? `<div class="bottom-sheet-option-description">${option.description}</div>` : ''}
        </div>
        <div class="bottom-sheet-option-checkbox" aria-hidden="true">
          <span class="material-symbols-rounded">check</span>
        </div>
      </button>
    `;
  }).join('');
}

/**
 * Toggles selection of an option
 */
function toggleBottomSheetOption(value) {
  const index = bottomSheetConfig.selectedValues.indexOf(value);

  if (index > -1) {
    // Deselect
    bottomSheetConfig.selectedValues.splice(index, 1);
    triggerHapticFeedback('light');
  } else {
    // Select
    bottomSheetConfig.selectedValues.push(value);
    triggerHapticFeedback('selection');
  }

  // Re-render options to update checkmarks
  const searchInput = document.getElementById('bottom-sheet-search-input');
  const searchValue = searchInput.value.trim();

  if (searchValue) {
    filterBottomSheetOptions(searchValue);
  } else {
    renderBottomSheetOptions();
  }
}

/**
 * Confirms selection and closes the bottom sheet
 */
function confirmBottomSheetSelection() {
  // Trigger success haptic feedback
  triggerHapticFeedback('success');

  if (bottomSheetConfig.onConfirm && typeof bottomSheetConfig.onConfirm === 'function') {
    bottomSheetConfig.onConfirm(bottomSheetConfig.selectedValues);
  }

  closeBottomSheet();
}

// Click outside to close
document.addEventListener('click', (e) => {
  const overlay = document.getElementById('bottom-sheet-overlay');
  if (e.target === overlay && bottomSheetConfig.isOpen) {
    closeBottomSheet();
  }
});

// Escape key to close
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && bottomSheetConfig.isOpen) {
    closeBottomSheet();
  }
});

// ==================== Haptic Feedback Utility ====================

/**
 * Triggers haptic feedback on supported devices
 * @param {string} type - Type of haptic feedback: 'light', 'medium', 'heavy', 'selection', 'success', 'warning', 'error'
 */
function triggerHapticFeedback(type = 'selection') {
  // Vibration API (Android & some iOS versions)
  if ('vibrate' in navigator) {
    const patterns = {
      light: 10,
      selection: 10,
      medium: 20,
      heavy: 50,
      success: [10, 50, 10],
      warning: [20, 100, 20],
      error: [50, 100, 50]
    };
    navigator.vibrate(patterns[type] || patterns.selection);
  }

  // iOS Haptic Engine (newer devices)
  if (window.Haptics) {
    try {
      switch (type) {
        case 'light':
          window.Haptics.impact({ style: 'light' });
          break;
        case 'medium':
          window.Haptics.impact({ style: 'medium' });
          break;
        case 'heavy':
          window.Haptics.impact({ style: 'heavy' });
          break;
        case 'selection':
          window.Haptics.selection();
          break;
        case 'success':
          window.Haptics.notification({ type: 'success' });
          break;
        case 'warning':
          window.Haptics.notification({ type: 'warning' });
          break;
        case 'error':
          window.Haptics.notification({ type: 'error' });
          break;
      }
    } catch (e) {
      // Fallback to vibration
      if ('vibrate' in navigator) {
        navigator.vibrate(10);
      }
    }
  }
}

// ==================== Enhanced Swipe-to-Close ====================

let touchStartY = 0;
let touchCurrentY = 0;
let isDragging = false;
let dragStartTime = 0;

const bottomSheet = document.getElementById('bottom-sheet');
const dragHandle = bottomSheet.querySelector('.bottom-sheet-drag-handle');
const overlay = document.getElementById('bottom-sheet-overlay');

// Allow dragging from entire sheet header, not just handle
const sheetHeader = bottomSheet.querySelector('.bottom-sheet-header');

function initDragToClose() {
  sheetHeader.addEventListener('touchstart', handleDragStart, { passive: true });
  sheetHeader.addEventListener('touchmove', handleDragMove, { passive: false });
  sheetHeader.addEventListener('touchend', handleDragEnd, { passive: true });
}

function handleDragStart(e) {
  touchStartY = e.touches[0].clientY;
  dragStartTime = Date.now();
  isDragging = true;
  bottomSheet.style.transition = 'none'; // Disable transition during drag
}

function handleDragMove(e) {
  if (!isDragging) return;

  touchCurrentY = e.touches[0].clientY;
  const deltaY = touchCurrentY - touchStartY;

  // Only allow dragging down
  if (deltaY > 0) {
    e.preventDefault(); // Prevent scrolling while dragging

    // Apply resistance effect (harder to drag further down)
    const resistance = 1 - (deltaY / window.innerHeight) * 0.5;
    const dragDistance = deltaY * resistance;

    bottomSheet.style.transform = `translateY(${dragDistance}px)`;

    // Fade out overlay proportionally
    const fadeRatio = Math.min(deltaY / 200, 1);
    overlay.style.opacity = 1 - fadeRatio;
  }
}

function handleDragEnd() {
  if (!isDragging) return;

  const deltaY = touchCurrentY - touchStartY;
  const dragDuration = Date.now() - dragStartTime;
  const velocity = deltaY / dragDuration; // px per ms

  // Re-enable transition
  bottomSheet.style.transition = '';
  overlay.style.opacity = '';

  // Close conditions:
  // 1. Dragged more than 150px
  // 2. Fast swipe (velocity > 0.5 px/ms) with at least 50px distance
  if (deltaY > 150 || (velocity > 0.5 && deltaY > 50)) {
    // Trigger haptic feedback
    triggerHapticFeedback('light');

    // Animate close
    bottomSheet.style.transform = 'translateY(100%)';
    setTimeout(() => {
      closeBottomSheet();
      bottomSheet.style.transform = ''; // Reset for next open
    }, 300);
  } else {
    // Snap back to original position
    bottomSheet.style.transform = '';
  }

  // Reset
  isDragging = false;
  touchStartY = 0;
  touchCurrentY = 0;
  dragStartTime = 0;
}

// Initialize drag functionality
initDragToClose();

// ==================== Multi-Select Input Field Helper ====================

/**
 * Creates a multi-select input field with chips
 * @param {string} containerId - ID of the container element
 * @param {Object} config - Configuration object
 * @param {string} config.icon - Material icon name
 * @param {string} config.placeholder - Placeholder text
 * @param {Array} config.selectedValues - Array of selected values
 * @param {Object} config.valueLabels - Object mapping values to labels
 */
function renderMultiSelectInput(containerId, config) {
  const container = document.getElementById(containerId);
  if (!container) return;

  const selectedValues = config.selectedValues || [];
  const valueLabels = config.valueLabels || {};
  const icon = config.icon || 'check_box';
  const placeholder = config.placeholder || 'Auswählen...';

  const hasSelection = selectedValues.length > 0;

  let chipsHTML = '';
  if (hasSelection) {
    chipsHTML = selectedValues.map(value => {
      const label = valueLabels[value] || value;
      return `
        <div class="multi-select-chip">
          <span>${label}</span>
          <button
            type="button"
            class="multi-select-chip-remove"
            onclick="removeMultiSelectChip('${containerId}', '${value}')"
          >
            <span class="material-symbols-rounded">close</span>
          </button>
        </div>
      `;
    }).join('');
  }

  container.innerHTML = `
    <div class="multi-select-input" id="${containerId}-input">
      ${hasSelection ? `<div class="multi-select-chips">${chipsHTML}</div>` : `<span class="multi-select-placeholder">${placeholder}</span>`}
    </div>
    <span class="material-symbols-rounded multi-select-arrow">expand_more</span>
  `;
}

/**
 * Removes a chip from multi-select input
 */
function removeMultiSelectChip(containerId, value) {
  // This function should be implemented by the calling context
  // as it needs to update the specific form state
  console.log('Remove chip:', containerId, value);
}
