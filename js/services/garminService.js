// ============================================================================
// GARMIN SERVICE — client contract for the Garmin Connect integration
// ----------------------------------------------------------------------------
// Garmin requires OAuth 1.0a and a SERVER (the consumer secret must never live
// in the client, and Garmin pushes activities to a backend webhook). So this
// client talks to YOUR backend (a Firebase Cloud Function) which holds the
// secret, runs the OAuth dance and stores/forwards activities. See GARMIN.md.
//
// Planned as a PREMIUM feature — active calls are gated behind isPremium().
// Until the backend + Garmin Developer access exist, connect()/sync() return a
// "not configured" result gracefully (no crashes).
//
// Classic script (no bundler): attaches to window.garminService.
// ============================================================================

(function () {
  'use strict';

  var STORAGE_KEY = 'garminConnection';

  // Base URL of your deployed Cloud Function (see GARMIN.md). Empty = not set up.
  // e.g. 'https://us-central1-calisthenics-pro-57d6d.cloudfunctions.net/garmin'
  var GARMIN_BACKEND = (typeof window !== 'undefined' && window.GARMIN_BACKEND) || '';

  function getConnection() {
    try { return JSON.parse(localStorage.getItem(STORAGE_KEY)) || { connected: false }; }
    catch (e) { return { connected: false }; }
  }
  function setConnection(conn) {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(conn)); } catch (e) {}
  }
  function configured() { return !!GARMIN_BACKEND; }

  // Garmin activityType → keep raw; pv4NormalizeSport() already maps
  // running/cycling/swimming/... to our internal run/bike/swim/…
  function mapActivityToSession(a) {
    if (!a) return null;
    var durationSec = a.durationInSeconds || a.durationSec || 0;
    var distanceKm = a.distanceInMeters ? a.distanceInMeters / 1000 : (a.distanceKm || 0);
    // Garmin can deliver HR time-series as samples; normalize to [{t, bpm}].
    var hrSamples = null;
    if (Array.isArray(a.heartRateSamples)) {
      hrSamples = a.heartRateSamples
        .map(function (s) { return { t: s.startTimeInSeconds != null ? (s.startTimeInSeconds - (a.startTimeInSeconds || 0)) : (s.t || 0), bpm: s.heartrate || s.bpm || 0 }; })
        .filter(function (s) { return s.bpm > 0; });
    } else if (Array.isArray(a.hrSamples)) {
      hrSamples = a.hrSamples;
    }
    var session = {
      type: 'cardio',
      source: 'garmin',
      garminActivityId: a.summaryId || a.activityId || a.garminActivityId || null,
      activityType: a.activityType || a.activityTypeKey || 'other',
      date: a.startTimeInSeconds ? new Date(a.startTimeInSeconds * 1000) : (a.date ? new Date(a.date) : new Date()),
      durationSec: durationSec,
      distanceKm: distanceKm || null,
      avgHr: a.averageHeartRateInBeatsPerMinute || a.avgHr || null,
      maxHr: a.maxHeartRateInBeatsPerMinute || a.maxHr || null,
      calories: a.activeKilocalories || a.calories || null,
      hrSamples: (hrSamples && hrSamples.length) ? hrSamples : null
    };
    // Pre-compute zones if we have samples and the helper is available.
    if (session.hrSamples && typeof window.computeHrZones === 'function') {
      var z = window.computeHrZones(session.hrSamples, session.maxHr || 190);
      if (z.some(function (x) { return x.minutes > 0; })) session.hrZones = z;
    }
    return session;
  }

  var garminService = {
    /** Premium gate — wire to your real entitlement (e.g. userProfile.premium). */
    isPremium: function () {
      try { return !!(window.userProfile && window.userProfile.premium); } catch (e) { return false; }
    },

    isConfigured: configured,
    isConnected: function () { return !!getConnection().connected; },

    /**
     * Start the connect flow. Opens the backend's OAuth-1.0a authorize URL in an
     * in-app browser (Capacitor Browser on device); the backend handles the
     * Garmin handshake + token storage and deep-links back to the app.
     * @returns {Promise<{connected:boolean, premiumRequired?:boolean, notConfigured?:boolean, pending?:boolean}>}
     */
    connect: function () {
      if (!this.isPremium()) return Promise.resolve({ connected: false, premiumRequired: true });
      if (!configured()) return Promise.resolve({ connected: false, notConfigured: true });
      var url = GARMIN_BACKEND + '/oauth/start';
      try {
        if (window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.Browser) {
          window.Capacitor.Plugins.Browser.open({ url: url });
        } else {
          window.open(url, '_blank');
        }
      } catch (e) {}
      // The backend reports success via a deep link / status poll; mark pending.
      return Promise.resolve({ connected: false, pending: true });
    },

    disconnect: function () {
      setConnection({ connected: false });
      if (configured()) {
        try { fetch(GARMIN_BACKEND + '/disconnect', { method: 'POST', credentials: 'include' }); } catch (e) {}
      }
      return Promise.resolve(true);
    },

    /**
     * Fetch raw Garmin activities since a date from YOUR backend (which holds the
     * tokens and calls the Garmin Activity API). Returns an array of raw activities.
     * @param {Date|number} [since]
     * @returns {Promise<Array>}
     */
    fetchActivities: function (since) {
      if (!this.isPremium() || !this.isConnected() || !configured()) return Promise.resolve([]);
      var ts = since ? (since instanceof Date ? Math.floor(since.getTime() / 1000) : since) : '';
      return fetch(GARMIN_BACKEND + '/activities?since=' + ts, { credentials: 'include' })
        .then(function (r) { return r.ok ? r.json() : []; })
        .catch(function () { return []; });
    },

    mapActivityToSession: mapActivityToSession,

    /**
     * Full sync: fetch → map → dedupe against existing sessions (by
     * garminActivityId) → persist via addDoc → refresh views.
     * @returns {Promise<{imported:number, notConfigured?:boolean}>}
     */
    sync: function () {
      if (!this.isPremium() || !this.isConnected()) return Promise.resolve({ imported: 0 });
      if (!configured()) return Promise.resolve({ imported: 0, notConfigured: true });
      var self = this;
      return this.fetchActivities().then(function (acts) {
        var existing = {};
        try {
          (typeof allSessions !== 'undefined' ? allSessions : []).forEach(function (s) {
            if (s.garminActivityId) existing[s.garminActivityId] = true;
          });
        } catch (e) {}
        var toAdd = (acts || []).map(self.mapActivityToSession).filter(function (s) {
          return s && s.garminActivityId && !existing[s.garminActivityId];
        });
        if (!toAdd.length || typeof addDoc !== 'function' || typeof sessionsCollection === 'undefined') {
          return { imported: 0 };
        }
        return Promise.all(toAdd.map(function (s) { return addDoc(sessionsCollection, s); }))
          .then(function () {
            if (typeof loadSessions === 'function') return loadSessions();
          })
          .then(function () {
            if (typeof renderProgressV4 === 'function') { try { renderProgressV4(); } catch (e) {} }
            return { imported: toAdd.length };
          });
      });
    },

    /**
     * Register the backend webhook so Garmin pushes new activities automatically.
     * (The webhook itself lives in the Cloud Function — see GARMIN.md.)
     */
    registerAutoSync: function () {
      if (!this.isPremium() || !this.isConnected() || !configured()) return Promise.resolve(false);
      return fetch(GARMIN_BACKEND + '/register-webhook', { method: 'POST', credentials: 'include' })
        .then(function (r) { return r.ok; })
        .catch(function () { return false; });
    }
  };

  window.garminService = garminService;
})();
