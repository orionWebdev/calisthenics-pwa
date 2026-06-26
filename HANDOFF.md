# HANDOFF / STATUS — ATEM Hybrid

Pick-up doc for any session (local CLI **or** claude.ai/code on mobile). The work
lives in git on branch **`develop`**; commit messages are detailed. This file is
the shared plan/context (local `~/.claude` memory does NOT travel to the cloud).

## What this app is
- Vanilla-JS PWA, **no bundler**, source at repo root (`index.html`, `css/`, `js/`).
- Firebase auth + Firestore. Demo mode via `?demo=1` (mock data, bypasses login;
  deep-links `&view=progress|training|workout&tab=…`, `&detail=<exerciseId>`).
- Dev server: `python -X utf8 dev-server.py` → http://localhost:8080 (no-cache).
- Headless verify: Chrome `--headless=new --force-device-scale-factor=1 ...
  --screenshot` (note: the headless CSS viewport floors ~484px regardless of
  `--window-size`; render wider + scale=1 for faithful shots).

## Native (Capacitor 8 → Android, Play Store)
- `npm run sync` after any web change → copies `www/` + plugins into `android/`,
  then build/run in Android Studio. appId `com.atemhybrid.app`.
- Native Google sign-in works (`@capacitor-firebase/authentication`, skipNativeAuth
  → credential handed to the JS Firebase SDK). google-services.json committed.

## Design language
- Dark premium, brand `#C01963` / light stop `#F02277`, font Zalando Sans Expanded.
- **Gradient-Dust** system (`css/components/muscle-dust.css` + `js/ui/muscleIcons.js`):
  soft grainy nebula orbs per muscle group (`.m-<grp>`/`.s-<grp>`) and HR zones
  (`.hz-1..5`). Reuse it everywhere.

## DONE recently (on develop)
- Home/nav fixes, modal brand inputs, profile overflow, keyboard squish, lighter type.
- **Muscle PNGs → gradient-dust orbs** (cards, detail, filters, progress).
- **Cardio**: optional Ø/Max HR fields in the manual log (`avgHr`/`maxHr`);
  endurance widget is now **per-sport (toggle)**; **separate Heart-Rate card** with
  Z1–Z5 dust orbs (time-in-zone fills with Garmin).

## NEXT — open tasks
### #5 Session detail redesign (IN PROGRESS)
- Approved mockup: **`design-system/screens/session-detail-mockup.png`** (+ `.html`).
  Hero + compact stat tiles (not fat bars), HR zones as time-in-zone dust orbs,
  route/GPS placeholder (Garmin), per-km splits, notes/RPE.
- **Build for ALL session types / sports**: cardio variant per sport
  (run/bike/swim/hike/row/other — pace vs km/h vs /100m vs duration), plus a
  **strength** variant (exercises + sets + volume instead of pace/splits).
- Current session-detail renderer to replace: search `openSessionDetail` /
  session detail in `js/views/sessions/`. Garmin will later fill avgHr/maxHr/
  hrSamples/route — leave hooks/placeholders.

### #3 Offline-first
- App currently won't boot offline (Firebase SDK from CDN). Plan: bundle Firebase
  SDK locally so the shell boots offline + enable Firestore offline persistence so
  workouts/exercises record locally and sync on reconnect. Decisions pending
  (auth offline behaviour, how far persistence goes).

### Backlog
- Extend gradient-dust to **plan cards**. Premium-gate `googleCalendarService`.
  Real AI-translation engine (ML-Kit on-device once native, or Cloud Translation).
  Cleanup dead CSS/JS (e.g. old endurance slider/Chart.js paths).
