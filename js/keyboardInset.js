// ========================================
// KEYBOARD INSET HELPER
// ========================================
// Detects on-screen keyboard via visualViewport API and exposes:
//  - CSS variable `--keyboard-inset` on :root (height of keyboard in px)
//  - Class `keyboard-open` on <body> when keyboard is up
//  - Smart scrollIntoView for focused text inputs that are hidden by the keyboard
//
// Modern Chrome/Edge with `interactive-widget=resizes-content` resize the layout
// viewport themselves (so --keyboard-inset stays 0). iOS Safari and older Android
// browsers need this manual compensation.

(function () {
  'use strict';

  const root = document.documentElement;
  const vv = window.visualViewport;
  const KEYBOARD_THRESHOLD_PX = 100; // ignore tiny inset jitter (URL bar etc.)

  function setInset(px) {
    root.style.setProperty('--keyboard-inset', `${px}px`);
    document.body.classList.toggle('keyboard-open', px > KEYBOARD_THRESHOLD_PX);
  }

  function update() {
    if (!vv) {
      setInset(0);
      return;
    }
    // Layout viewport (window.innerHeight) does not shrink with the keyboard on iOS
    // and on browsers without interactive-widget support. The visual viewport does.
    const inset = Math.max(0, Math.round(window.innerHeight - vv.height - vv.offsetTop));
    setInset(inset);
  }

  if (vv) {
    vv.addEventListener('resize', update);
    vv.addEventListener('scroll', update);
  } else {
    setInset(0);
  }
  update();

  // ---- Smart scroll-into-view ----
  // After keyboard opens (~300ms animation), if the focused input is outside
  // the visible visual viewport, scroll it into the centre.

  function isTextInput(el) {
    if (!el || !el.matches) return false;
    if (el.matches('textarea')) return true;
    if (el.matches('[contenteditable=""], [contenteditable="true"]')) return true;
    if (el.matches('input')) {
      const type = (el.type || 'text').toLowerCase();
      return type === '' || type === 'text' || type === 'search' || type === 'email'
          || type === 'number' || type === 'tel' || type === 'url' || type === 'password'
          || type === 'date' || type === 'time' || type === 'datetime-local';
    }
    return false;
  }

  function scrollFocusedIntoView(target) {
    if (!target || !target.getBoundingClientRect) return;
    if (document.activeElement !== target) return; // user moved focus already
    const rect = target.getBoundingClientRect();
    const visibleTop = vv ? vv.offsetTop : 0;
    const visibleBottom = vv ? (vv.offsetTop + vv.height) : window.innerHeight;
    const TOP_MARGIN = 8;
    const BOTTOM_MARGIN = 16;
    if (rect.top >= visibleTop + TOP_MARGIN && rect.bottom <= visibleBottom - BOTTOM_MARGIN) return;
    try {
      target.scrollIntoView({ behavior: 'smooth', block: 'center' });
    } catch (e) {
      target.scrollIntoView();
    }
  }

  document.addEventListener('focusin', (e) => {
    if (!isTextInput(e.target)) return;
    setTimeout(() => scrollFocusedIntoView(e.target), 320);
  });
})();
