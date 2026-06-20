// ========================================
// SCROLL-REVEAL UTILITY (Redesign)
// Reveals elements with the .reveal class as they scroll into view
// (Apple-style fly-in). Works for static and dynamically rendered
// (innerHTML) content via a MutationObserver.
//
// Fail-safe: CSS only hides .reveal while <html>.js-reveal is set, which
// this script adds. If the script fails to run, content stays visible.
// Respects prefers-reduced-motion.
// ========================================

(function () {
  'use strict';

  var root = document.documentElement;
  root.classList.add('js-reveal');

  var reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  function markAll() {
    var all = document.querySelectorAll('.reveal');
    for (var i = 0; i < all.length; i++) all[i].classList.add('in');
  }

  if (reduce || typeof IntersectionObserver === 'undefined') {
    // No animation: reveal everything immediately (and keep doing so for new nodes).
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', markAll);
    } else {
      markAll();
    }
    window.revealScan = markAll;
    return;
  }

  var io = new IntersectionObserver(function (entries) {
    for (var i = 0; i < entries.length; i++) {
      var e = entries[i];
      if (e.isIntersecting) {
        e.target.classList.add('in');
        io.unobserve(e.target);
      }
    }
  }, { threshold: 0.12, rootMargin: '0px 0px -6% 0px' });

  function observe(el) {
    if (!el || !el.classList || el.classList.contains('in') || el.__revObserved) return;
    el.__revObserved = true;
    io.observe(el);
  }

  function scan(scope) {
    var ctx = (scope && scope.querySelectorAll) ? scope : document;
    var els = ctx.querySelectorAll('.reveal');
    for (var i = 0; i < els.length; i++) observe(els[i]);
  }

  // Public: call after a dynamic render to (re)observe new .reveal nodes.
  window.revealScan = scan;

  var mo = new MutationObserver(function (muts) {
    for (var m = 0; m < muts.length; m++) {
      var added = muts[m].addedNodes;
      for (var n = 0; n < added.length; n++) {
        var node = added[n];
        if (node.nodeType !== 1) continue;
        if (node.classList && node.classList.contains('reveal')) observe(node);
        if (node.querySelectorAll) scan(node);
      }
    }
  });

  function start() {
    scan(document);
    var target = document.getElementById('app-container') || document.body;
    if (target) mo.observe(target, { childList: true, subtree: true });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
