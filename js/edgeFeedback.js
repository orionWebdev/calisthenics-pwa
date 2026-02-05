// ========================================
// EDGE FEEDBACK - SUCCESS/ERROR CONFIRMATION
// ========================================

const EDGE_FEEDBACK_MIN_INTERVAL = 400;
const EDGE_FEEDBACK_DEFAULT_DURATION = 2000;
const EDGE_FEEDBACK_QUEUE_LIMIT = 6;

let edgeFeedbackQueue = [];
let edgeFeedbackActive = false;
let lastEdgeFeedback = { type: null, time: 0 };

function getEdgeFeedbackTarget() {
  const bottomNav = document.querySelector('.bottom-nav');
  if (bottomNav && getComputedStyle(bottomNav).display !== 'none') return bottomNav;
  const desktopNav = document.querySelector('.desktop-nav');
  if (desktopNav && getComputedStyle(desktopNav).display !== 'none') return desktopNav;
  return null;
}

function showEdgeFeedback(type = 'success', message = '', options = {}) {
  const normalizedType = type === 'error' ? 'error' : 'success';
  const now = Date.now();

  if (now - lastEdgeFeedback.time < EDGE_FEEDBACK_MIN_INTERVAL &&
      lastEdgeFeedback.type === normalizedType) {
    updateEdgeFeedbackMessage(message);
    return;
  }

  const duration = options.duration || EDGE_FEEDBACK_DEFAULT_DURATION;
  edgeFeedbackQueue.push({ type: normalizedType, message, duration });
  if (edgeFeedbackQueue.length > EDGE_FEEDBACK_QUEUE_LIMIT) {
    edgeFeedbackQueue.shift();
  }

  if (!edgeFeedbackActive) {
    runEdgeFeedbackQueue();
  }

  lastEdgeFeedback = { type: normalizedType, time: now };
}

function runEdgeFeedbackQueue() {
  const next = edgeFeedbackQueue.shift();
  if (!next) {
    edgeFeedbackActive = false;
    return;
  }

  edgeFeedbackActive = true;

  updateEdgeFeedbackMessage(next.message);

  const target = getEdgeFeedbackTarget();
  if (!target) {
    edgeFeedbackActive = false;
    setTimeout(runEdgeFeedbackQueue, 150);
    return;
  }

  target.classList.remove('edge-success', 'edge-error', 'edge-feedback-active');
  target.classList.add(`edge-${next.type}`, 'edge-feedback-active');

  setTimeout(() => {
    target.classList.remove('edge-feedback-active', `edge-${next.type}`);
    setTimeout(runEdgeFeedbackQueue, 150);
  }, next.duration);
}

function updateEdgeFeedbackMessage(message) {
  if (!message) return;
  const announcer = document.getElementById('edge-feedback-announcer');
  if (announcer) {
    announcer.textContent = message;
  }
}

window.showEdgeFeedback = showEdgeFeedback;
