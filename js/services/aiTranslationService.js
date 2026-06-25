// ============================================================================
// AI TRANSLATION SERVICE (Vorbereitung / Platzhalter)
// ----------------------------------------------------------------------------
// Übersetzt NUTZERERZEUGTE Inhalte (eigene Übungs-/Plannamen, Notizen) in die
// gewählte UI-Sprache. Die statische UI läuft bereits über das i18n-System –
// dieser Service zielt nur auf dynamische Strings, die nicht im Wörterbuch stehen.
//
// Aktuell STUB: keine Netzwerkaufrufe, keine Kosten – Originaltext wird
// durchgereicht. Das Flag liegt in userProfile.aiTranslation (settings.js).
//
// Zielarchitektur (geplant nach dem Capacitor-Packaging in die native App):
//   PRIMÄR   : Google ML Kit On-Device-Übersetzung (kostenlos, offline) über ein
//              Capacitor-Plugin – ideal für die native Play-Store-App.
//   FALLBACK : (Web) Firebase Callable Function → Google Cloud Translation API,
//              Ergebnisse in Firestore gecacht je (sourceText, targetLang), damit
//              jeder eindeutige String nur einmal kostenpflichtig übersetzt wird.
//
// Klassisches Script (kein Bundler): hängt sich an window.aiTranslationService.
// ============================================================================

(function () {
  'use strict';

  // In-Memory-Cache: `${lang}::${text}` -> Übersetzung (später + Firestore-Cache)
  var memCache = {};

  function isEnabled() {
    try { return !!(window.userProfile && window.userProfile.aiTranslation); }
    catch (e) { return false; }
  }

  function targetLang() {
    try { return (window.userProfile && window.userProfile.language) || 'de'; }
    catch (e) { return 'de'; }
  }

  function cacheKey(text, lang) { return lang + '::' + text; }

  var aiTranslationService = {
    isEnabled: isEnabled,

    /**
     * Hook zum Aktivieren/Deaktivieren (Flag selbst hält settings.js).
     * TODO: bei true das ML-Kit-Sprachmodell vorladen, bei false entladen.
     * @param {boolean} on
     * @returns {Promise<boolean>}
     */
    setEnabled: function (on) {
      return Promise.resolve(!!on);
    },

    /**
     * Einzelnen Text in die Zielsprache übersetzen (mit Cache).
     * @param {string} text
     * @param {string} [lang] - Zielsprache (default: UI-Sprache)
     * @returns {Promise<string>} übersetzter Text (Stub: Originaltext)
     */
    translate: function (text, lang) {
      var target = lang || targetLang();
      if (!text || !isEnabled()) return Promise.resolve(text);
      var key = cacheKey(text, target);
      if (memCache[key] !== undefined) return Promise.resolve(memCache[key]);
      // TODO: echte Übersetzung (ML Kit on-device / Cloud Translation via Callable),
      //       Ergebnis in memCache + Firestore-Cache ablegen.
      memCache[key] = text; // Stub: Originaltext durchreichen
      return Promise.resolve(text);
    },

    /**
     * Mehrere Felder eines Objekts übersetzen (z. B. {name, notes}).
     * @param {Object} obj
     * @param {string[]} fields - zu übersetzende Feldnamen
     * @param {string} [lang]
     * @returns {Promise<Object>} Kopie mit übersetzten Feldern
     */
    translateContent: function (obj, fields, lang) {
      if (!obj || !isEnabled()) return Promise.resolve(obj);
      var self = this;
      var out = Object.assign({}, obj);
      var jobs = (fields || []).map(function (f) {
        if (typeof out[f] !== 'string' || !out[f]) return Promise.resolve();
        return self.translate(out[f], lang).then(function (tr) { out[f] = tr; });
      });
      return Promise.all(jobs).then(function () { return out; });
    }
  };

  window.aiTranslationService = aiTranslationService;
})();
