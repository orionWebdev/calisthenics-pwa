// ========================================
// SERVICE WORKER für CALISTHENICS PRO
// ========================================
//
// Strategy:
//   - Source code (HTML/CSS/JS, navigation requests):  network-first, cache fallback.
//     -> Code updates reach users on next reload, no manual cache busting needed.
//   - Static assets (images, fonts, icons):           cache-first, network fallback.
//     -> Stays fast and works offline.
//   - Firebase / version.json:                         always network, never cached.

const CACHE_NAME = 'calisthenics-pro-v5';

// Pre-cached on install for offline shell. Anything else is cached on first fetch.
const PRECACHE_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icon-192.png',
  '/icon-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(PRECACHE_ASSETS))
      .then(() => self.skipWaiting())
      .catch((err) => console.error('SW install failed:', err))
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((names) => Promise.all(
        names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n))
      ))
      .then(() => self.clients.claim())
  );
});

function isSourceRequest(request) {
  if (request.mode === 'navigate') return true;
  const url = request.url;
  // Match .html / .css / .js (with optional query string) hosted from our origin
  return /\.(html|css|js)(\?[^/]*)?$/.test(url);
}

function shouldBypass(request) {
  const url = request.url;
  return url.includes('firestore.googleapis.com')
      || url.includes('firebase')
      || url.includes('googleapis.com')
      || url.includes('version.json');
}

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  if (shouldBypass(event.request)) return;

  // --- Source code: network-first ---
  if (isSourceRequest(event.request)) {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          if (response && response.ok) {
            const copy = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy)).catch(() => {});
          }
          return response;
        })
        .catch(() => caches.match(event.request).then((cached) => cached || caches.match('/index.html')))
    );
    return;
  }

  // --- Static assets: cache-first ---
  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;
      return fetch(event.request).then((response) => {
        if (response && response.ok && response.type !== 'opaque') {
          const copy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy)).catch(() => {});
        }
        return response;
      });
    })
  );
});

// Allow the page to ask the SW to take over immediately after a new install
self.addEventListener('message', (event) => {
  if (event.data === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
