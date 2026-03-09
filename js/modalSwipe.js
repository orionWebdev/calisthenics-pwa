// ==================== Modal Swipe-to-Close for Mobile ====================

/**
 * Adds swipe-to-close functionality to all modals on mobile devices
 * Works similarly to the Bottom Sheet swipe-to-close behavior
 */

let modalTouchStartY = 0;
let modalTouchCurrentY = 0;
let isModalDragging = false;
let modalDragStartTime = 0;
let activeModal = null;
let activeModalContent = null;

function updateBodyScrollLock() {
  const anyModalOpen = document.querySelector('.modal.active');
  if (anyModalOpen) {
    document.body.style.overflow = 'hidden';
  } else {
    document.body.style.overflow = '';
  }
}

function initModalSwipeToClose() {
  // Find all modals and add touch event listeners
  const modals = document.querySelectorAll('.modal');

  modals.forEach(modal => {
    const modalContent = modal.querySelector('.modal-content');
    if (!modalContent) return;

    // Only enable swipe on mobile (touch devices)
    if ('ontouchstart' in window) {
      modalContent.addEventListener('touchstart', handleModalDragStart, { passive: true });
      modalContent.addEventListener('touchmove', handleModalDragMove, { passive: false });
      modalContent.addEventListener('touchend', handleModalDragEnd, { passive: true });
    }

    // Click outside to close (existing behavior, now with animation)
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        closeModalWithAnimation(modal, modalContent);
      }
    });

    // Watch for active class changes to lock/unlock body scroll
    const observer = new MutationObserver(() => {
      updateBodyScrollLock();
    });
    observer.observe(modal, { attributes: true, attributeFilter: ['class'] });
  });

  // Escape key to close (existing behavior, now with animation)
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      const openModal = document.querySelector('.modal.active');
      if (openModal) {
        const modalContent = openModal.querySelector('.modal-content');
        closeModalWithAnimation(openModal, modalContent);
      }
    }
  });
}

function handleModalDragStart(e) {
  // Only allow dragging from top area (first 80px)
  const rect = e.currentTarget.getBoundingClientRect();
  const touchY = e.touches[0].clientY;
  const relativeY = touchY - rect.top;

  // Only start drag if touching near the top (drag handle area)
  if (relativeY > 80) {
    return;
  }

  // Check if modal content is scrolled
  const scrollTop = e.currentTarget.scrollTop;
  if (scrollTop > 5) {
    // Don't interfere with scrolling
    return;
  }

  modalTouchStartY = e.touches[0].clientY;
  modalDragStartTime = Date.now();
  isModalDragging = true;
  activeModal = e.currentTarget.closest('.modal');
  activeModalContent = e.currentTarget;

  // Disable transition during drag
  activeModalContent.style.transition = 'none';
}

function handleModalDragMove(e) {
  if (!isModalDragging || !activeModalContent) return;

  modalTouchCurrentY = e.touches[0].clientY;
  const deltaY = modalTouchCurrentY - modalTouchStartY;

  // Only allow dragging down
  if (deltaY > 0) {
    e.preventDefault(); // Prevent scrolling while dragging

    // Apply resistance effect
    const resistance = 1 - (deltaY / window.innerHeight) * 0.5;
    const dragDistance = deltaY * resistance;

    activeModalContent.style.transform = `translateY(${dragDistance}px)`;

    // Fade out overlay proportionally
    if (activeModal) {
      const fadeRatio = Math.min(deltaY / 200, 0.5);
      activeModal.style.opacity = 1 - fadeRatio;
    }

    // Haptic feedback on significant drag
    if (deltaY > 150 && typeof triggerHapticFeedback === 'function') {
      triggerHapticFeedback('light');
    }
  }
}

function handleModalDragEnd() {
  if (!isModalDragging || !activeModalContent) return;

  const deltaY = modalTouchCurrentY - modalTouchStartY;
  const dragDuration = Date.now() - modalDragStartTime;
  const velocity = deltaY / dragDuration; // px per ms

  // Re-enable transition
  activeModalContent.style.transition = '';
  if (activeModal) {
    activeModal.style.opacity = '';
  }

  // Close conditions:
  // 1. Dragged more than 150px
  // 2. Fast swipe (velocity > 0.5 px/ms) with at least 50px distance
  if (deltaY > 150 || (velocity > 0.5 && deltaY > 50)) {
    // Close modal with animation
    closeModalWithAnimation(activeModal, activeModalContent);
  } else {
    // Snap back to original position
    activeModalContent.style.transform = '';
  }

  // Reset
  isModalDragging = false;
  modalTouchStartY = 0;
  modalTouchCurrentY = 0;
  modalDragStartTime = 0;
  activeModal = null;
  activeModalContent = null;
}

function closeModalWithAnimation(modal, modalContent) {
  if (!modal || !modalContent) return;

  // Trigger haptic feedback
  if (typeof triggerHapticFeedback === 'function') {
    triggerHapticFeedback('light');
  }

  // Animate close
  modalContent.style.transform = 'translateY(100%)';
  modal.style.opacity = '0';

  setTimeout(() => {
    modal.classList.remove('active');
    modalContent.style.transform = ''; // Reset for next open
    modal.style.opacity = '';

    // Restore body scroll (handled by MutationObserver via updateBodyScrollLock)
    updateBodyScrollLock();
  }, 300);
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initModalSwipeToClose);
} else {
  initModalSwipeToClose();
}
