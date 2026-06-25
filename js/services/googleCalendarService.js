// ============================================================================
// GOOGLE CALENDAR SERVICE (Vorbereitung / Platzhalter)
// ----------------------------------------------------------------------------
// Schnittstelle für die Synchronisation des Trainingsplans mit Google Kalender.
// Geplant als PREMIUM-Feature (Abo) — alle aktiven Aktionen sind hinter
// isPremium() gegated.
//
// Architektur ist bewusst BIDIREKTIONAL angelegt, auch wenn zunächst nur der
// Push verdrahtet wird:
//   • EXPORT  (App → Google): pushPlannedTrainings() / pushWorkout()
//       -> geplante Trainings landen in einem dedizierten "ATEM Hybrid"-Kalender
//          (nur Write-Scope, minimal-invasiv) — der eigentliche Verkaufswert.
//   • IMPORT  (Google → App): fetchEvents()
//       -> v2: reiner "Busy"-Indikator beim Verplanen, KEINE Fremd-Details in
//          der Trainingsansicht (Datenschutz / Clutter vermeiden).
//
// Klassisches Script (kein Bundler): hängt sich an window.googleCalendarService.
// Die echten Netzwerkaufrufe (Google Identity Services + Calendar API) sind
// TODOs und liefern bewusst Stubs zurück.
// ============================================================================

(function () {
  'use strict';

  var STORAGE_KEY = 'googleCalendarConnection';

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

  var googleCalendarService = {
    /**
     * Premium-Gate. Aktive Sync-Aktionen sind nur mit aktivem Abo erlaubt.
     * TODO: an die echte Abo-/Entitlement-Prüfung koppeln (z. B. profile.premium).
     * @returns {boolean}
     */
    isPremium: function () {
      try {
        if (typeof window.userProfile === 'object' && window.userProfile) {
          return !!window.userProfile.premium;
        }
      } catch (e) {}
      return false;
    },

    /** Ist ein Google-Konto verbunden? */
    isConnected: function () {
      return !!getConnection().connected;
    },

    /**
     * OAuth-Flow starten und Google-Konto verbinden.
     * TODO: Google Identity Services (GIS) Token-Flow mit Scope
     *   'https://www.googleapis.com/auth/calendar.events' (Write auf eigenen
     *   "ATEM Hybrid"-Kalender). Access-/Refresh-Token sicher ablegen, dedizierten
     *   Kalender via Calendar API anlegen falls nicht vorhanden.
     * @returns {Promise<{connected:boolean}>}
     */
    connect: function () {
      if (!this.isPremium()) {
        return Promise.resolve({ connected: false, premiumRequired: true });
      }
      // TODO: echten GIS/OAuth-Flow öffnen.
      return Promise.resolve({ connected: false, pending: true });
    },

    /** Verbindung trennen + lokale Tokens verwerfen. */
    disconnect: function () {
      // TODO: Token-Revocation gegen Google OAuth.
      setConnection({ connected: false });
      return Promise.resolve(true);
    },

    /**
     * EXPORT: geplante Trainings eines Zeitraums in den Google-Kalender pushen.
     * TODO: scheduleData im Zeitraum → Calendar API events.insert/patch (idempotent
     *   per stabiler iCalUID je Plan-Eintrag, damit kein Duplikat entsteht).
     * @param {{from?:Date, to?:Date}} [range]
     * @returns {Promise<{pushed:number}>}
     */
    pushPlannedTrainings: function (range) {
      if (!this.isPremium() || !this.isConnected()) {
        return Promise.resolve({ pushed: 0 });
      }
      // TODO: Mapping pro Eintrag:
      //   { summary: <Trainingsname>, start, end, reminders, iCalUID: 'atem-'+entryId }
      return Promise.resolve({ pushed: 0 });
    },

    /**
     * EXPORT: einzelnes (geplantes oder absolviertes) Training pushen.
     * @param {Object} event - interner Kalender-/Plan-Eintrag
     * @returns {Promise<{pushed:number}>}
     */
    pushWorkout: function (event) {
      if (!this.isPremium() || !this.isConnected()) {
        return Promise.resolve({ pushed: 0 });
      }
      // TODO: einzelnes events.insert/patch.
      return Promise.resolve({ pushed: 0 });
    },

    /**
     * IMPORT (v2): Events seit einem Zeitpunkt abrufen — nur als Busy-Indikator.
     * TODO: Calendar API events.list (timeMin), auf {date, busy} reduzieren —
     *   bewusst OHNE Titel/Details, um Privatsphäre & Clutter zu vermeiden.
     * @param {Date|number} [since]
     * @returns {Promise<Array<{date:string, busy:boolean}>>}
     */
    fetchEvents: function (since) {
      // TODO: API-Call + Reduktion auf Busy-Tage.
      return Promise.resolve([]);
    },

    /**
     * Sync-Pipeline anstoßen (Push raus + optional Busy-Overlay rein).
     * TODO: pushPlannedTrainings() und (v2) fetchEvents() orchestrieren.
     * @returns {Promise<{pushed:number, busyDays:number}>}
     */
    sync: function () {
      if (!this.isPremium() || !this.isConnected()) {
        return Promise.resolve({ pushed: 0, busyDays: 0 });
      }
      // TODO: Sync-Pipeline implementieren.
      return Promise.resolve({ pushed: 0, busyDays: 0 });
    },

    /**
     * Automatische Synchronisation registrieren (z. B. bei Plan-Änderungen).
     * TODO: an scheduleData-Änderungen koppeln (debounced push).
     */
    registerAutoSync: function () {
      return Promise.resolve(false);
    }
  };

  window.googleCalendarService = googleCalendarService;
})();
