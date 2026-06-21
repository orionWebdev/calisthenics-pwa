// ========================================
// DEMO MODE (?demo=1) — Redesign-Vorschau ohne Login.
// Rein clientseitig: injiziert realistische MOCK-Daten in den In-Memory-State
// und faked einen eingeloggten User. Greift NIE auf Firestore oder echte Auth zu.
// Inert ohne ?demo=1 (in localStorage gemerkt; ?demo=0 schaltet ab).
// ========================================
(function () {
  try {
    var p = new URLSearchParams(location.search);
    if (p.get('demo') === '1') localStorage.setItem('atemDemo', '1');
    if (p.get('demo') === '0') localStorage.removeItem('atemDemo');
    window.ATEM_DEMO = localStorage.getItem('atemDemo') === '1';
  } catch (e) { window.ATEM_DEMO = false; }

  if (!window.ATEM_DEMO) return;
  console.log('🎭 ATEM DEMO MODE aktiv — Mock-Daten, kein Firestore/Login. Abschalten: ?demo=0');

  // ---- Mock-Übungs-DB (muscleGroups passend zu den Sessions) ----
  var demoExercises = [
    { id: 'push_up', name: 'Liegestütze', name_de: 'Liegestütze', type: 'bodyweight', muscleGroups: ['chest','triceps','shoulders'], equipment: ['bodyweight'], difficulty: 1, source: 'curated' },
    { id: 'pull_up', name: 'Klimmzug', name_de: 'Klimmzug', type: 'bodyweight', muscleGroups: ['back','biceps'], equipment: ['bodyweight'], difficulty: 3, source: 'curated' },
    { id: 'squat', name: 'Kniebeuge', name_de: 'Kniebeuge', type: 'bodyweight', muscleGroups: ['legs','glutes'], equipment: ['bodyweight'], difficulty: 2, source: 'curated' },
    { id: 'bench_press', name: 'Bankdrücken', name_de: 'Bankdrücken', type: 'strength', muscleGroups: ['chest','triceps','shoulders'], equipment: ['barbell'], difficulty: 4, source: 'curated' },
    { id: 'plank', name: 'Unterarmstütz', name_de: 'Unterarmstütz', type: 'bodyweight', muscleGroups: ['core'], equipment: ['bodyweight'], difficulty: 1, source: 'curated' },
    { id: 'dip', name: 'Dips', name_de: 'Dips', type: 'bodyweight', muscleGroups: ['triceps','chest'], equipment: ['bodyweight'], difficulty: 3, source: 'curated' }
  ];
  var exById = {};
  demoExercises.forEach(function (e) { exById[e.id] = e; });

  function iso(d) { return d.toISOString(); }
  function daysAgo(n) { var d = new Date(); d.setHours(18, 0, 0, 0); d.setDate(d.getDate() - n); return d; }

  // ---- Mock-Sessions über ~10 Wochen (mit leichter Progression) ----
  var sessions = [];
  var sid = 1;
  var plans = [['pull_up', 'bench_press', 'dip'], ['squat', 'push_up', 'plank']];

  for (var week = 9; week >= 0; week--) {
    var prog = 9 - week; // 0..9
    [1, 4].forEach(function (dow, idx) {
      var exIds = plans[idx % 2];
      var exercises = exIds.map(function (exId) {
        var meta = exById[exId];
        var baseReps = meta.type === 'strength' ? 8 : (exId === 'push_up' ? 22 : (exId === 'plank' ? 1 : 9));
        var reps = baseReps + Math.round(prog * 0.6);
        var weight = meta.type === 'strength' ? Math.round(60 + prog * 1.6) : 0;
        var nSets = 3 + (week % 3 === 0 ? 1 : 0);
        var sets = [];
        for (var s = 0; s < nSets; s++) sets.push({ reps: Math.max(1, reps - s), weight: weight });
        return { exerciseId: exId, sets: sets };
      });
      var dt = daysAgo(week * 7 + dow);
      sessions.push({ id: 'demo' + (sid++), type: 'strength', date: iso(dt), createdAt: iso(dt), exercises: exercises, durationSec: (42 + (week % 3) * 6) * 60 });
    });
    var cdt = daysAgo(week * 7 + 6);
    var dist = Math.round((5 + prog * 0.25) * 10) / 10;
    sessions.push({ id: 'demo' + (sid++), type: 'cardio', activityType: 'running', date: iso(cdt), createdAt: iso(cdt), distanceKm: dist, durationSec: Math.round(dist * (5.6 - prog * 0.03) * 60) });
    if (week % 2 === 0) {
      var rdt = daysAgo(week * 7 + 2);
      sessions.push({ id: 'demo' + (sid++), type: 'recovery', activityType: 'mobility', date: iso(rdt), createdAt: iso(rdt), durationSec: 20 * 60 });
    }
  }

  // ---- Mock-Pläne ----
  var demoPlans = [
    { id: 'p1', name: 'Push Day A', type: 'strength', items: [{ exerciseId: 'bench_press' }, { exerciseId: 'dip' }, { exerciseId: 'push_up' }], exercises: [{ exerciseId: 'bench_press' }, { exerciseId: 'dip' }, { exerciseId: 'push_up' }] },
    { id: 'p2', name: 'Pull Day B', type: 'strength', items: [{ exerciseId: 'pull_up' }, { exerciseId: 'plank' }], exercises: [{ exerciseId: 'pull_up' }, { exerciseId: 'plank' }] },
    { id: 'p3', name: 'Easy Run', type: 'cardio', distanceKm: 5, duration: 30, durationSec: 1800 },
    { id: 'p4', name: 'Mobility Flow', type: 'recovery', duration: 20, durationSec: 1200 }
  ];

  // ---- In-Memory-Globals injizieren (in anderen classic scripts deklariert) ----
  try { allExercises = demoExercises; } catch (e) {}
  try { filteredExercises = demoExercises.slice(); } catch (e) {}
  try { allSessions = sessions; sessionsLoaded = true; } catch (e) {}
  try { scheduleData = []; } catch (e) {}
  try { allPlans = demoPlans; filteredPlans = demoPlans.slice(); } catch (e) {}

  // ---- Loader / Realtime-Listener stubben (kein Firestore) ----
  window.loadSessions = function () { try { allSessions = sessions; sessionsLoaded = true; } catch (e) {} return Promise.resolve(sessions); };
  window.loadExercises = function () {
    try { allExercises = demoExercises; filteredExercises = demoExercises.slice(); } catch (e) {}
    if (typeof renderExercises === 'function') { try { renderExercises(); } catch (e) {} }
    return Promise.resolve(demoExercises);
  };
  window.loadSchedule = function () { try { scheduleData = []; } catch (e) {} return Promise.resolve([]); };
  window.loadPlans = function () {
    try { allPlans = demoPlans; filteredPlans = demoPlans.slice(); } catch (e) {}
    if (typeof renderPlans === 'function') { try { renderPlans(); } catch (e) {} }
    return Promise.resolve(demoPlans);
  };
  window.onUserCollectionChange = function (col, cb) { try { cb(sessions); } catch (e) {} return function () {}; };

  // ---- Eingeloggten User faken, damit der Bootstrap die App zeigt ----
  function fakeAuth() {
    if (!window.authModule || !window.authModule.AUTH_STATES) return false;
    var fakeUser = { uid: 'demo-user', email: 'demo@atem.dev', displayName: 'Demo Athlet' };
    window.authModule.initAuth = function () { return Promise.resolve(); };
    window.authModule.onAuthStateChange = function (cb) {
      try { cb(fakeUser, window.authModule.AUTH_STATES.LOGGED_IN); } catch (e) {}
      return function () {};
    };
    window.authModule.isAuthenticated = function () { return true; };
    window.authModule.getCurrentUser = function () { return fakeUser; };
    return true;
  }
  if (!fakeAuth()) document.addEventListener('DOMContentLoaded', fakeAuth);

  // Force-Render der daten-getriebenen Views (Demo injiziert Daten, triggert aber
  // nicht jede View). Mehrfach gestaffelt, damit die DOM-Container bereit sind.
  document.addEventListener('DOMContentLoaded', function () {
    [400, 1000, 1600].forEach(function (delay) {
      setTimeout(function () {
        ['renderExercises', 'refreshDashboard', 'renderPlans'].forEach(function (fn) {
          if (typeof window[fn] === 'function') { try { window[fn](); } catch (e) {} }
        });
      }, delay);
    });
  });

  // Optional: View/Tab direkt öffnen für Previews/Screenshots
  // (?demo=1&view=training&tab=exercises)
  try {
    var sp = new URLSearchParams(location.search);
    var vw = sp.get('view');
    var tb = sp.get('tab');
    if (vw) {
      document.addEventListener('DOMContentLoaded', function () {
        setTimeout(function () {
          if (typeof showView === 'function') { try { showView(vw); } catch (e) {} }
          if (tb && typeof showTrainingTab === 'function') { setTimeout(function () { try { showTrainingTab(tb); } catch (e) {} }, 250); }
        }, 900);
      });
    }
  } catch (e) {}
})();
