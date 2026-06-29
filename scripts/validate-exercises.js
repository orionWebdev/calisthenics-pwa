#!/usr/bin/env node
// ========================================
// CURATED EXERCISE DATABASE VALIDATOR
// ========================================
// Validates the curated seed dataset in js/core/data.js:
//  - unique, snake_case ids
//  - required fields present
//  - type in {bodyweight, strength}  (no cardio)
//  - primaryMuscles non-empty & canonical; secondaryMuscles canonical & disjoint
//  - muscleGroups === unique([...primary, ...secondary])
//  - equipment canonical & non-empty
//  - difficulty integer 1..5
//  - instructions present
// Exit code 0 = clean, 1 = errors. Run: `node scripts/validate-exercises.js`
const fs = require('fs');
const path = require('path');

const CANON_MUSCLES = new Set([
  'chest', 'back', 'shoulders', 'biceps', 'triceps', 'core',
  'quads', 'hamstrings', 'glutes', 'calves'
]);
const CANON_EQUIPMENT = new Set([
  'bodyweight', 'pull-up-bar', 'dip-bars', 'parallettes', 'rings',
  'box', 'bench', 'wall', 'mat',
  'barbell', 'dumbbell', 'kettlebell', 'machine', 'resistance-bands'
]);
const VALID_TYPES = new Set(['bodyweight', 'strength']);

function loadExercises() {
  const src = fs.readFileSync(path.join(__dirname, '..', 'js', 'core', 'data.js'), 'utf8');
  const m = src.match(/const defaultExercises = (\[[\s\S]*?\n\]);/);
  if (!m) throw new Error('Could not locate `const defaultExercises = [...]` in js/core/data.js');
  // eslint-disable-next-line no-eval
  return eval(m[1]);
}

function sameSet(a, b) {
  if (a.length !== b.length) return false;
  const sb = new Set(b);
  return a.every(x => sb.has(x));
}

const errors = [];
const warnings = [];
const exercises = loadExercises();
const seenIds = new Set();

for (const ex of exercises) {
  const id = ex.id || '(missing id)';

  if (!ex.id) errors.push(`${id}: missing id`);
  else if (!/^[a-z0-9]+(_[a-z0-9]+)*$/.test(ex.id)) errors.push(`${id}: id is not snake_case`);
  if (seenIds.has(ex.id)) errors.push(`${id}: duplicate id`);
  seenIds.add(ex.id);

  if (!ex.name) errors.push(`${id}: missing name`);
  if (!VALID_TYPES.has(ex.type)) errors.push(`${id}: invalid type "${ex.type}" (cardio not allowed)`);

  const primary = Array.isArray(ex.primaryMuscles) ? ex.primaryMuscles : [];
  const secondary = Array.isArray(ex.secondaryMuscles) ? ex.secondaryMuscles : [];
  if (primary.length === 0) errors.push(`${id}: primaryMuscles is empty`);
  primary.forEach(m => { if (!CANON_MUSCLES.has(m)) errors.push(`${id}: non-canonical primary muscle "${m}"`); });
  secondary.forEach(m => { if (!CANON_MUSCLES.has(m)) errors.push(`${id}: non-canonical secondary muscle "${m}"`); });
  secondary.forEach(m => { if (primary.includes(m)) errors.push(`${id}: "${m}" listed as both primary and secondary`); });

  const derived = [...new Set([...primary, ...secondary])];
  if (!Array.isArray(ex.muscleGroups) || !sameSet(ex.muscleGroups, derived)) {
    errors.push(`${id}: muscleGroups must equal unique([...primary, ...secondary])`);
  }

  const equipment = Array.isArray(ex.equipment) ? ex.equipment : [];
  if (equipment.length === 0) errors.push(`${id}: equipment is empty`);
  equipment.forEach(e => { if (!CANON_EQUIPMENT.has(e)) errors.push(`${id}: non-canonical equipment "${e}"`); });

  if (!Number.isInteger(ex.difficulty) || ex.difficulty < 1 || ex.difficulty > 5) {
    errors.push(`${id}: difficulty must be an integer 1..5 (got ${ex.difficulty})`);
  }

  if (!Array.isArray(ex.instructionsSteps) || ex.instructionsSteps.length === 0) {
    errors.push(`${id}: instructionsSteps is empty`);
  }
  if (!ex.name_de) warnings.push(`${id}: no German name (name_de) — UI will fall back to English`);
  if (!ex.i18n || !ex.i18n.de) warnings.push(`${id}: no German i18n content`);
}

// Summary
const byType = exercises.reduce((acc, e) => { acc[e.type] = (acc[e.type] || 0) + 1; return acc; }, {});
console.log(`Validated ${exercises.length} curated exercises:`, byType);

if (warnings.length) {
  console.log(`\n${warnings.length} warning(s):`);
  warnings.forEach(w => console.log('  ⚠ ' + w));
}

if (errors.length) {
  console.error(`\n${errors.length} ERROR(S):`);
  errors.forEach(e => console.error('  ✗ ' + e));
  process.exit(1);
}

console.log('\n✓ All checks passed.');
