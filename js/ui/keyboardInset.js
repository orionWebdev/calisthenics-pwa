// ========================================
// KEYBOARD INSET HELPER
// ========================================
// Exposes:
//  - CSS variable `--keyboard-inset` on :root  (height of the on-screen keyboard, px)
//  - Class `keyboard-open` on <body>          (only when inset > threshold)
//
// Modern Chromium browsers (Play-Store WebView, Edge) honour the viewport meta
// `interactive-widget=resizes-content` and resize the layout viewport themselves.
// In that case window.innerHeight === visualViewport.height, so --keyboard-inset
// stays 0 and we don't fight the browser. The variable is only non-zero on iOS
// Safari and older browsers that leave the layout viewport untouched.
//
// We deliberately do NOT call scrollIntoView() on focus — the browser's native
// handling already scrolls focused inputs into view, and a second scroll would
// push surrounding content off the top of the screen.

(function () {
  'use strict';

  const root = document.documentElement;
  const vv = window.visualViewport;
  const KEYBOARD_THRESHOLD_PX = 150; // ignore URL-bar jitter, etc.

  function setInset(px) {
    root.style.setProperty('--keyboard-inset', `${px}px`);
    document.body.classList.toggle('keyboard-open', px > KEYBOARD_THRESHOLD_PX);
  }

  function update() {
    if (!vv) {
      setInset(0);
      return;
    }
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
})();
