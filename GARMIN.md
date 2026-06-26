# Garmin Integration — plan & backend spec

Status: **client scaffolding done**, backend + Garmin API access **pending** (gated
on Christian). Premium (subscription) feature.

## Why a backend is required
Garmin Connect uses **OAuth 1.0a** and a **push model**: you register a webhook and
Garmin POSTs new activities to it; you then call the Activity API to fetch details
(incl. HR samples). The **consumer secret must never ship in the app**, and the
webhook needs a public server endpoint. → A small backend is mandatory. We use
**Firebase Cloud Functions** (Blaze plan; Christian confirmed OK).

## Gated steps (Christian)
1. Apply to the **Garmin Connect Developer Program** → get **Consumer Key + Secret**
   (Health/Activity API). Approval can take a while.
2. `firebase init functions` in this repo, set secrets:
   `firebase functions:config:set garmin.key="..." garmin.secret="..."`
   (or use Secret Manager). Deploy: `firebase deploy --only functions`.
3. In Garmin's developer console, set the **OAuth callback** + **webhook URL** to the
   deployed function (`…/garmin/oauth/callback`, `…/garmin/webhook`).
4. Set `window.GARMIN_BACKEND` (e.g. in index.html or config) to the function base
   URL, e.g. `https://us-central1-<project>.cloudfunctions.net/garmin`.

## Client (DONE — `js/services/garminService.js`)
- `isPremium()` gate, `connect()` (opens `…/oauth/start` via Capacitor Browser),
  `disconnect()`, `fetchActivities(since)`, `sync()` (fetch → map → dedupe by
  `garminActivityId` → `addDoc` → refresh), `registerAutoSync()`.
- `mapActivityToSession(activity)` maps a Garmin activity to our session schema and
  pre-computes `hrZones` via `computeHrZones()` (already wired into the cardio
  session detail — the zone-dust orbs fill from `hrSamples`).
- Until `GARMIN_BACKEND` is set, `connect()/sync()` return `{notConfigured:true}`
  gracefully.

## Backend endpoints to implement (Cloud Function `garmin`)
Express-style routes under one HTTPS function:
- `GET  /oauth/start`     → OAuth 1.0a request-token + redirect user to Garmin authorize.
- `GET  /oauth/callback`  → exchange verifier for access token; store per-user
  (Firestore, keyed by app user); deep-link back to the app.
- `POST /webhook`         → Garmin pushes activity summaries; verify + enqueue.
- `GET  /activities?since=<unixSec>` → return mapped/raw activities for the signed-in
  user (calls Garmin Activity API with the stored token; include HR samples).
- `POST /register-webhook`, `POST /disconnect`.

Auth between app ↔ function: pass the Firebase ID token (Authorization: Bearer) so
the function knows which user; store Garmin tokens under that uid.

## Data mapping (Garmin → session)
`{ type:'cardio', source:'garmin', garminActivityId, activityType, date,
   durationSec, distanceKm, avgHr, maxHr, calories, hrSamples:[{t,bpm}], hrZones }`
`pv4NormalizeSport()` already maps running/cycling/swimming/… to run/bike/swim/…

## Interim alternative (no Garmin API)
A manual **.FIT/.GPX/.TCX import** (parse client-side → same mapping → `hrSamples`)
could deliver HR-zone data without the Garmin API while approval is pending. Ask if
you want this as a bridge.
