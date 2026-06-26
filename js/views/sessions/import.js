// ============================================================================
// ACTIVITY FILE IMPORT (.TCX / .GPX)
// ----------------------------------------------------------------------------
// Import an activity exported from Garmin Connect / Strava / Komoot etc. without
// any backend or API: parse the file client-side, map it to our normal cardio
// session schema and persist it via addDoc — so it counts as a real session and
// all aggregations (training load / ACWR / form, weekly volume) recompute. HR
// samples fill the zone-dust orbs via computeHrZones().
// ============================================================================

(function () {
  'use strict';

  // Find descendants by local name, ignoring XML namespaces/prefixes (TCX uses a
  // default ns; GPX HR lives under a gpxtpx:/ns3: prefix).
  function findAll(root, localName) {
    var out = [], all = root.getElementsByTagName('*');
    for (var i = 0; i < all.length; i++) if (all[i].localName === localName) out.push(all[i]);
    return out;
  }
  function firstText(root, localName) {
    var els = findAll(root, localName);
    return els.length ? (els[0].textContent || '').trim() : '';
  }

  var SPORT_MAP = { running: 'run', run: 'run', biking: 'bike', cycling: 'bike', bike: 'bike', swimming: 'swim', swim: 'swim', hiking: 'hike', walking: 'hike', rowing: 'row', row: 'row' };
  function normSport(s) { return SPORT_MAP[(s || '').toLowerCase()] || (s ? 'other' : 'run'); }

  function haversineKm(a, b) {
    var R = 6371, toRad = function (d) { return d * Math.PI / 180; };
    var dLat = toRad(b.lat - a.lat), dLon = toRad(b.lon - a.lon);
    var s = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
    return R * 2 * Math.atan2(Math.sqrt(s), Math.sqrt(1 - s));
  }

  // Returns a session-like object (without Firestore timestamps) or null.
  function parseActivityFile(text) {
    var doc;
    try { doc = new DOMParser().parseFromString(text, 'application/xml'); } catch (e) { return null; }
    if (!doc || doc.getElementsByTagName('parsererror').length) return null;

    var isTcx = findAll(doc, 'TrainingCenterDatabase').length || findAll(doc, 'Activity').length;
    var isGpx = doc.documentElement && doc.documentElement.localName === 'gpx';
    if (!isTcx && !isGpx) return null;

    var startDate = null, lastTimeMs = null, distKm = 0, calories = 0, durSec = 0, sport = '';
    var hrSamples = [];

    if (isTcx) {
      var act = findAll(doc, 'Activity')[0];
      if (act) sport = act.getAttribute('Sport') || '';
      // Duration / distance / calories from laps (more reliable than trackpoints)
      findAll(doc, 'Lap').forEach(function (lap) {
        var tt = parseFloat(firstText(lap, 'TotalTimeSeconds')); if (isFinite(tt)) durSec += tt;
        var cal = parseFloat(firstText(lap, 'Calories')); if (isFinite(cal)) calories += cal;
      });
      var maxDist = 0;
      findAll(doc, 'Trackpoint').forEach(function (tp) {
        var timeStr = firstText(tp, 'Time');
        var hrEl = findAll(tp, 'HeartRateBpm')[0];
        var bpm = hrEl ? parseInt(firstText(hrEl, 'Value'), 10) : NaN;
        var dist = parseFloat(firstText(tp, 'DistanceMeters'));
        if (isFinite(dist)) maxDist = Math.max(maxDist, dist);
        if (timeStr) {
          var ms = Date.parse(timeStr);
          if (!isNaN(ms)) {
            if (startDate == null) startDate = ms;
            lastTimeMs = ms;
            if (isFinite(bpm) && bpm > 0) hrSamples.push({ t: Math.round((ms - startDate) / 1000), bpm: bpm });
          }
        }
      });
      if (maxDist > 0) distKm = maxDist / 1000;
    } else { // GPX
      sport = firstText(doc, 'type');
      var pts = findAll(doc, 'trkpt');
      var prev = null;
      pts.forEach(function (pt) {
        var lat = parseFloat(pt.getAttribute('lat')), lon = parseFloat(pt.getAttribute('lon'));
        var timeStr = firstText(pt, 'time');
        var hr = parseInt(firstText(pt, 'hr'), 10);
        if (timeStr) {
          var ms = Date.parse(timeStr);
          if (!isNaN(ms)) {
            if (startDate == null) startDate = ms;
            lastTimeMs = ms;
            if (isFinite(hr) && hr > 0) hrSamples.push({ t: Math.round((ms - startDate) / 1000), bpm: hr });
          }
        }
        if (isFinite(lat) && isFinite(lon)) {
          if (prev) distKm += haversineKm(prev, { lat: lat, lon: lon });
          prev = { lat: lat, lon: lon };
        }
      });
      if (startDate != null && lastTimeMs != null) durSec = Math.round((lastTimeMs - startDate) / 1000);
    }

    if (startDate == null) return null;
    if (!durSec && lastTimeMs != null) durSec = Math.round((lastTimeMs - startDate) / 1000);

    var avgHr = null, maxHr = null;
    if (hrSamples.length) {
      var sum = 0; maxHr = 0;
      hrSamples.forEach(function (s) { sum += s.bpm; if (s.bpm > maxHr) maxHr = s.bpm; });
      avgHr = Math.round(sum / hrSamples.length);
    }

    return {
      type: 'cardio',
      source: 'import',
      activityType: normSport(sport),
      date: new Date(startDate),
      duration: Math.round(durSec / 60),
      durationSec: durSec,
      distanceKm: distKm > 0 ? Math.round(distKm * 100) / 100 : null,
      pace: distKm > 0 ? (durSec / 60) / distKm : null,
      avgHr: avgHr,
      maxHr: maxHr,
      calories: calories > 0 ? Math.round(calories) : null,
      hrSamples: hrSamples.length ? hrSamples : null
    };
  }

  function saveImportedSession(parsed, fileName) {
    if (!parsed) {
      if (typeof showEdgeFeedback === 'function') showEdgeFeedback('error', 'Datei konnte nicht gelesen werden (.TCX/.GPX erwartet)');
      return;
    }
    var session = Object.assign({}, parsed, {
      name: parsed.name || (fileName ? fileName.replace(/\.[^.]+$/, '') : null),
      date: (window.firebase && firebase.firestore) ? firebase.firestore.Timestamp.fromDate(parsed.date) : parsed.date,
      createdAt: (window.firebase && firebase.firestore) ? firebase.firestore.Timestamp.now() : new Date()
    });
    // Pre-compute HR zones so the dust orbs fill immediately.
    if (session.hrSamples && typeof window.computeHrZones === 'function') {
      var z = window.computeHrZones(session.hrSamples, session.maxHr || 190);
      if (z.some(function (x) { return x.minutes > 0; })) session.hrZones = z;
    }
    if (typeof addDoc !== 'function' || typeof sessionsCollection === 'undefined') {
      if (typeof showEdgeFeedback === 'function') showEdgeFeedback('error', 'Import nicht verfügbar');
      return;
    }
    Promise.resolve(addDoc(sessionsCollection, session))
      .then(function () { if (typeof loadSessions === 'function') return loadSessions(); })
      .then(function () {
        if (typeof closeAddCardioModal === 'function') closeAddCardioModal();
        if (typeof refreshDashboard === 'function') { try { refreshDashboard(); } catch (e) {} }
        if (typeof renderProgressV4 === 'function') { try { renderProgressV4(); } catch (e) {} }
        if (typeof triggerSuccessGlow === 'function') { try { triggerSuccessGlow(); } catch (e) {} }
        if (typeof showEdgeFeedback === 'function') showEdgeFeedback('success', 'Einheit importiert' + (session.hrSamples ? ' · HF-Zonen erkannt' : ''));
      })
      .catch(function (err) {
        if (typeof showEdgeFeedback === 'function') showEdgeFeedback('error', 'Import fehlgeschlagen');
        console.error('Import failed', err);
      });
  }

  // Opens the OS file picker and imports the chosen .tcx/.gpx file.
  function triggerActivityImport() {
    var input = document.createElement('input');
    input.type = 'file';
    input.accept = '.tcx,.gpx,.xml,application/gpx+xml';
    input.style.display = 'none';
    input.addEventListener('change', function () {
      var file = input.files && input.files[0];
      if (!file) return;
      var reader = new FileReader();
      reader.onload = function () { saveImportedSession(parseActivityFile(String(reader.result || '')), file.name); input.remove(); };
      reader.onerror = function () { if (typeof showEdgeFeedback === 'function') showEdgeFeedback('error', 'Datei konnte nicht gelesen werden'); input.remove(); };
      reader.readAsText(file);
    });
    document.body.appendChild(input);
    input.click();
  }

  window.parseActivityFile = parseActivityFile;
  window.triggerActivityImport = triggerActivityImport;
})();
