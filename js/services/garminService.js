// ============================================================================
// GARMIN SERVICE (Vorbereitung / Platzhalter)
// ----------------------------------------------------------------------------
// Schnittstelle für die automatische Synchronisation von Garmin-Workouts inkl.
// Herzfrequenz-Werten (HF). Aktuell reine Platzhalter — die echte Anbindung
// (OAuth + Garmin Health/Activity API) wird hier später implementiert.
//
// Klassisches Script (kein Bundler): hängt sich an window.garminService.
// Die eigentlichen Netzwerkaufrufe sind TODOs und liefern bewusst Stubs zurück.
// ============================================================================

(function () {
  'use strict';

  var STORAGE_KEY = 'garminConnection';

  function getConnection() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY)) || { connected: false };
    } catch (e) {
      return { connected: false };
    }
  }

  function setConnection(conn) {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(conn)); } catch (e) {}
  }

  var garminService = {
    /** Ist ein Garmin-Konto verbunden? */
    isConnected: function () {
      return !!getConnection().connected;
    },

    /**
     * OAuth-Flow starten und Garmin-Konto verbinden.
     * TODO: OAuth 2.0 / PKCE gegen die Garmin Connect API, Tokens sicher ablegen.
     * @returns {Promise<{connected:boolean}>}
     */
    connect: function () {
      // TODO: echten OAuth-Flow öffnen, Access-/Refresh-Token speichern.
      return Promise.resolve({ connected: false, pending: true });
    },

    /** Verbindung trennen + lokale Tokens verwerfen. */
    disconnect: function () {
      // TODO: Token-Revocation gegen Garmin API.
      setConnection({ connected: false });
      return Promise.resolve(true);
    },

    /**
     * Workouts seit einem Zeitpunkt abrufen (inkl. HF-Zeitreihe).
     * TODO: GET /activities + /activityDetails (Herzfrequenz-Samples) abrufen
     * und in das interne Session-Schema mappen.
     * @param {Date|number} [since] - ab wann synchronisiert wird
     * @returns {Promise<Array>} Liste gemappter Workouts (Platzhalter: leer)
     */
    fetchWorkouts: function (since) {
      // TODO: API-Call + Mapping. Erwartetes Mapping-Ziel pro Workout:
      //   { date, type, durationSec, distanceKm, avgHr, maxHr, hrSamples: [{t, bpm}], source: 'garmin' }
      return Promise.resolve([]);
    },

    /**
     * Automatische Synchronisation anstoßen (z. B. beim App-Start / Pull-to-Refresh).
     * TODO: fetchWorkouts() → Deduplizieren gegen bestehende Sessions → speichern.
     * @returns {Promise<{imported:number}>}
     */
    sync: function () {
      // TODO: Sync-Pipeline implementieren.
      return Promise.resolve({ imported: 0 });
    },

    /**
     * Webhook/Push-Registrierung für automatische Workout-Pushes von Garmin.
     * TODO: Garmin Ping/Push-Service registrieren.
     */
    registerAutoSync: function () {
      return Promise.resolve(false);
    }
  };

  window.garminService = garminService;
})();
