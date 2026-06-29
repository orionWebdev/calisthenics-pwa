#!/usr/bin/env node
/**
 * Assembles the Capacitor web payload into ./www
 *
 * This app has no bundler — source lives at the repo root. Capacitor copies the
 * contents of `webDir` (= www) into the native Android project, so we copy ONLY
 * the runtime files here and leave out dev/docs/build cruft (design-system,
 * configuration, dev-server.py, firestore rules, node_modules, android, .git …).
 *
 * Run via:  npm run build:www   (also runs automatically before `npm run sync`)
 */
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const out = path.join(root, 'www');

// Runtime assets the app actually loads in the browser/WebView.
const FILES = [
  'index.html',
  'manifest.json',
  'sw.js',
  'version.json',
  'icon-192.png',
  'icon-512.png',
];
const DIRS = ['css', 'js', 'assets', 'components'];

// Clean previous output for a deterministic payload.
fs.rmSync(out, { recursive: true, force: true });
fs.mkdirSync(out, { recursive: true });

let copied = 0;
for (const f of FILES) {
  const src = path.join(root, f);
  if (fs.existsSync(src)) { fs.copyFileSync(src, path.join(out, f)); copied++; }
  else console.warn(`[build-www] skip (missing file): ${f}`);
}
for (const d of DIRS) {
  const src = path.join(root, d);
  if (fs.existsSync(src)) { fs.cpSync(src, path.join(out, d), { recursive: true }); copied++; }
  else console.warn(`[build-www] skip (missing dir): ${d}`);
}

console.log(`[build-www] wrote ${copied} entries to ${path.relative(root, out)}/`);
