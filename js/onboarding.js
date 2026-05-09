// ========================================
// ONBOARDING SEQUENCE
// ========================================
// Four-card intro shown to new users (or anyone whose profile flag
// `onboardingCompleted` is not yet true). Triggered at the end of initApp()
// or manually from Settings → "App-Tour neu starten".

const ONBOARDING_CARDS = [
  { key: 'welcome',    icon: 'fitness_center', tone: 'pink'   },
  { key: 'plan',       icon: 'calendar_month', tone: 'pink'   },
  { key: 'track',      icon: 'timer',          tone: 'orange' },
  { key: 'noWearable', icon: 'watch_off',      tone: 'violet' },
  { key: 'progress',   icon: 'trending_up',    tone: 'green'  }
];

let _onboardingCardIdx = 0;
let _onboardingMounted = false;
let _onboardingForcedReplay = false;

function _onboardingT(key, params) {
  return typeof t === 'function' ? t(key, params) : key;
}

/** Should we auto-show the onboarding right now? */
function shouldShowOnboarding() {
  if (typeof userProfile === 'undefined' || !userProfile) return false;
  if (userProfile.onboardingCompleted === true) return false;
  return true;
}

/** Public entrypoint called by initApp() once everything is loaded. */
function tryShowOnboardingAfterInit() {
  // Wait briefly so that the dashboard has rendered behind the overlay
  setTimeout(() => {
    if (shouldShowOnboarding()) showOnboarding();
  }, 600);
}

/** Manually re-trigger from settings. Always shows, regardless of flag. */
function restartOnboarding() {
  _onboardingForcedReplay = true;
  showOnboarding();
}

function showOnboarding() {
  if (!_onboardingMounted) mountOnboarding();
  _onboardingCardIdx = 0;
  renderOnboarding();
  const overlay = document.getElementById('onboarding-overlay');
  if (!overlay) return;
  overlay.hidden = false;
  document.body.classList.add('onboarding-active');
  // Trigger entrance transition next frame
  requestAnimationFrame(() => overlay.classList.add('active'));
}

function hideOnboarding() {
  const overlay = document.getElementById('onboarding-overlay');
  if (!overlay) return;
  overlay.classList.remove('active');
  document.body.classList.remove('onboarding-active');
  setTimeout(() => { overlay.hidden = true; }, 320);
}

function mountOnboarding() {
  let overlay = document.getElementById('onboarding-overlay');
  if (overlay) { _onboardingMounted = true; return; }

  overlay = document.createElement('div');
  overlay.id = 'onboarding-overlay';
  overlay.className = 'onboarding-overlay';
  overlay.hidden = true;
  overlay.setAttribute('role', 'dialog');
  overlay.setAttribute('aria-modal', 'true');
  overlay.setAttribute('aria-labelledby', 'onboarding-title');

  overlay.innerHTML = `
    <button type="button"
            class="onboarding-skip"
            onclick="completeOnboarding('skip')"
            aria-label="${_onboardingT('onboarding.skip')}">
      ${_onboardingT('onboarding.skip')}
    </button>

    <div class="onboarding-stage">
      <div class="onboarding-card-track" id="onboarding-card-track"></div>
    </div>

    <div class="onboarding-pagination" id="onboarding-pagination" aria-hidden="true"></div>

    <div class="onboarding-actions">
      <button type="button"
              class="onboarding-prev"
              id="onboarding-prev-btn"
              onclick="prevOnboardingCard()">
        <span class="material-symbols-rounded">arrow_back</span>
      </button>
      <button type="button"
              class="onboarding-next"
              id="onboarding-next-btn"
              onclick="nextOnboardingCard()">
        <span id="onboarding-next-label">${_onboardingT('onboarding.next')}</span>
        <span class="material-symbols-rounded">arrow_forward</span>
      </button>
    </div>
  `;

  document.body.appendChild(overlay);
  _onboardingMounted = true;
}

function renderOnboarding() {
  const track = document.getElementById('onboarding-card-track');
  const pagination = document.getElementById('onboarding-pagination');
  if (!track || !pagination) return;

  // Cards
  track.innerHTML = ONBOARDING_CARDS.map((card, i) => {
    const isActive = i === _onboardingCardIdx;
    const title  = _onboardingT(`onboarding.cards.${card.key}.title`);
    const body   = _onboardingT(`onboarding.cards.${card.key}.body`);
    const accent = _onboardingT(`onboarding.cards.${card.key}.accent`) || '';

    return `
      <article class="onboarding-card${isActive ? ' onboarding-card--active' : ''}"
               data-tone="${card.tone}"
               aria-hidden="${!isActive}">
        <div class="onboarding-card-icon">
          <span class="material-symbols-rounded">${card.icon}</span>
        </div>
        <h2 class="onboarding-card-title" ${i === 0 ? 'id="onboarding-title"' : ''}>${title}</h2>
        ${accent ? `<p class="onboarding-card-accent">${accent}</p>` : ''}
        <p class="onboarding-card-body">${body}</p>
      </article>
    `;
  }).join('');

  track.style.transform = `translateX(-${_onboardingCardIdx * 100}%)`;

  // Pagination dots
  pagination.innerHTML = ONBOARDING_CARDS.map((_, i) => {
    const isActive = i === _onboardingCardIdx;
    return `<span class="onboarding-dot${isActive ? ' active' : ''}"></span>`;
  }).join('');

  // Buttons
  const prevBtn = document.getElementById('onboarding-prev-btn');
  const nextLabel = document.getElementById('onboarding-next-label');
  if (prevBtn) prevBtn.style.visibility = _onboardingCardIdx === 0 ? 'hidden' : 'visible';
  if (nextLabel) {
    const isLast = _onboardingCardIdx === ONBOARDING_CARDS.length - 1;
    nextLabel.textContent = isLast
      ? _onboardingT('onboarding.start')
      : _onboardingT('onboarding.next');
  }
}

function nextOnboardingCard() {
  if (_onboardingCardIdx < ONBOARDING_CARDS.length - 1) {
    _onboardingCardIdx++;
    renderOnboarding();
    if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('selection');
  } else {
    completeOnboarding('finish');
  }
}

function prevOnboardingCard() {
  if (_onboardingCardIdx === 0) return;
  _onboardingCardIdx--;
  renderOnboarding();
  if (typeof triggerHapticFeedback === 'function') triggerHapticFeedback('selection');
}

async function completeOnboarding(reason /* 'skip' | 'finish' */) {
  hideOnboarding();
  if (typeof triggerHapticFeedback === 'function') {
    triggerHapticFeedback(reason === 'finish' ? 'success' : 'light');
  }

  // Mark as completed in profile (and persist if user is logged in)
  if (typeof userProfile !== 'undefined' && userProfile) {
    userProfile.onboardingCompleted = true;
    if (typeof saveUserProfileToCache === 'function') saveUserProfileToCache();
    if (typeof debouncedSaveToFirestore === 'function') debouncedSaveToFirestore();
  }
  _onboardingForcedReplay = false;
}

// Touch swipe between cards (mobile)
(function attachOnboardingSwipe() {
  let startX = 0;
  let startY = 0;
  let isDragging = false;

  document.addEventListener('touchstart', (e) => {
    const overlay = document.getElementById('onboarding-overlay');
    if (!overlay || overlay.hidden) return;
    if (!overlay.contains(e.target)) return;
    startX = e.touches[0].clientX;
    startY = e.touches[0].clientY;
    isDragging = true;
  }, { passive: true });

  document.addEventListener('touchend', (e) => {
    if (!isDragging) return;
    isDragging = false;
    const dx = e.changedTouches[0].clientX - startX;
    const dy = e.changedTouches[0].clientY - startY;
    if (Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy) * 1.5) {
      if (dx < 0) nextOnboardingCard();
      else prevOnboardingCard();
    }
  }, { passive: true });
})();

window.tryShowOnboardingAfterInit = tryShowOnboardingAfterInit;
window.restartOnboarding = restartOnboarding;
window.nextOnboardingCard = nextOnboardingCard;
window.prevOnboardingCard = prevOnboardingCard;
window.completeOnboarding = completeOnboarding;
