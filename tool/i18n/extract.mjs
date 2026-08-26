// Zieht den Übersetzungsbaum aus der PWA nach JSON.
//
// js/core/i18n.js hat kein module.exports und endet in `window.t = t; ...`.
// Statt 3.200 Zeilen verschachtelter Literale mit Regex zu zerlegen, wird die
// Datei in einer Sandbox ausgewertet und `translations` herausgereicht.
//
//   node tool/i18n/extract.mjs
//
// Ergebnis: tool/i18n/legacy_de.json und legacy_en.json — eingecheckt als
// Vorrat, aus dem sich spätere Screens bedienen.

import { readFileSync, writeFileSync } from 'node:fs';
import vm from 'node:vm';

const src = readFileSync('js/core/i18n.js', 'utf8');

const translations = vm.runInNewContext(src + '\n;translations', {
  window: {}, document: undefined,
  Intl, Date, Number, String, Math, JSON, console,
});

const locales = Object.keys(translations);
if (!locales.includes('de') || !locales.includes('en')) {
  throw new Error(`Erwartet de und en, gefunden: ${locales.join(', ')}`);
}

function flatten(obj, prefix = '', out = {}) {
  for (const [k, v] of Object.entries(obj)) {
    const path = prefix ? `${prefix}.${k}` : k;
    if (v && typeof v === 'object' && !Array.isArray(v)) flatten(v, path, out);
    else out[path] = v;
  }
  return out;
}

const flat = Object.fromEntries(
  locales.map((l) => [l, flatten(translations[l])]),
);

// Parität ist eine Zusicherung, keine Hoffnung.
const deKeys = new Set(Object.keys(flat.de));
const enKeys = new Set(Object.keys(flat.en));
const missingEn = [...deKeys].filter((k) => !enKeys.has(k));
const missingDe = [...enKeys].filter((k) => !deKeys.has(k));

for (const l of ['de', 'en']) {
  writeFileSync(
    `tool/i18n/legacy_${l}.json`,
    JSON.stringify(flat[l], null, 2) + '\n',
  );
}

console.log(`de: ${deKeys.size} Schlüssel`);
console.log(`en: ${enKeys.size} Schlüssel`);
console.log(`fehlt in en: ${missingEn.length}${missingEn.length ? ' -> ' + missingEn.slice(0, 5).join(', ') : ''}`);
console.log(`fehlt in de: ${missingDe.length}${missingDe.length ? ' -> ' + missingDe.slice(0, 5).join(', ') : ''}`);

const nonString = Object.entries(flat.de).filter(([, v]) => typeof v !== 'string');
console.log(`Nicht-String-Werte: ${nonString.length}`);

if (missingEn.length || missingDe.length) process.exitCode = 1;
