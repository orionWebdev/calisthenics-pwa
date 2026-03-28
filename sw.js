// ========================================
// SERVICE WORKER für CALISTHENICS PRO
// ========================================

const CACHE_NAME = 'calisthenics-pro-v1';
const ASSETS_TO_CACHE = [
  '/',
  '/index.html',
  '/css/style.css',
  '/css/components.css',
  '/js/app.js',
  '/js/firebase.js',
  '/js/exercises.js',
  '/js/calendar.js',
  '/js/plans.js',
  '/js/data.js',
  '/logo.svg',
  '/icon-192.png',
  '/icon-512.png',
  '/manifest.json'
];

// Install Event - Cache Assets
self.addEventListener('install', (event) => {
  console.log('Service Worker: Installing...');

  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('Service Worker: Caching files');
        return cache.addAll(ASSETS_TO_CACHE);
      })
      .then(() => {
        console.log('Service Worker: Installation complete');
        return self.skipWaiting();
      })
      .catch((error) => {
        console.error('Service Worker: Installation failed', error);
      })
  );
});

// Activate Event - Clean up old caches
self.addEventListener('activate', (event) => {
  console.log('Service Worker: Activating...');

  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cache) => {
            if (cache !== CACHE_NAME) {
              console.log('Service Worker: Deleting old cache:', cache);
              return caches.delete(cache);
            }
          })
        );
      })
      .then(() => {
        console.log('Service Worker: Activation complete');
        return self.clients.claim();
      })
  );
});

// Fetch Event - Serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  // Skip Firebase requests and version.json (always fetch from network)
  if (event.request.url.includes('firestore.googleapis.com') ||
      event.request.url.includes('firebase') ||
      event.request.url.includes('version.json')) {
    return;
  }

  event.respondWith(
    caches.match(event.request)
      .then((cachedResponse) => {
        // Return cached response if found
        if (cachedResponse) {
          console.log('Service Worker: Serving from cache:', event.request.url);
          return cachedResponse;
        }

        // Otherwise fetch from network
        console.log('Service Worker: Fetching from network:', event.request.url);
        return fetch(event.request)
          .then((response) => {
            // Don't cache non-successful responses
            if (!response || response.status !== 200 || response.type === 'opaque') {
              return response;
            }

            // Clone the response (can only be consumed once)
            const responseToCache = response.clone();

            // Cache the new response
            caches.open(CACHE_NAME)
              .then((cache) => {
                cache.put(event.request, responseToCache);
              });

            return response;
          })
          .catch((error) => {
            console.error('Service Worker: Fetch failed', error);
            // You could return a custom offline page here
            throw error;
          });
      })
  );
});
