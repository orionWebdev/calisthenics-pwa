// ========================================
// SHARED TYPEDEFS
// ========================================
// This file contains only JSDoc @typedef blocks — no runtime code.
// Loaded first so IDE/TypeScript language server sees the types early.

/**
 * @typedef {'normal'|'superset'|'circuit'|'emom'|'amrap'|'interval'} ExecutionType
 */

/**
 * @typedef {Object} PlanItemTarget
 * @property {number} [sets]
 * @property {string} [reps]    - z.B. '10', '8-12', 'max'
 * @property {number} [holdSec] - Isometrische Halte-Dauer in Sekunden
 */

/**
 * Plan-Item im Trainingsplan. Flaches Schema — optionale Felder werden nur
 * gesetzt, wenn der executionType sie benötigt.
 *
 * Backward-Kompatibilität: Fehlt `executionType`, wird 'normal' angenommen
 * (siehe getExecutionType() in plans.js).
 *
 * @typedef {Object} PlanItem
 * @property {string}         exerciseId
 * @property {PlanItemTarget} [target]
 * @property {number}         [restSec]         - Pause zwischen Sätzen (normal/superset/circuit)
 * @property {ExecutionType}  [executionType]   - Default 'normal' wenn nicht gesetzt
 *
 * @property {string}         [groupId]         - Gemeinsame ID für superset | circuit
 * @property {number}         [rounds]          - Anzahl Runden durch die Gruppe (circuit)
 *
 * @property {number}         [intervalSec]     - Intervall pro Runde (emom, Default 60)
 * @property {number}         [durationSec]     - Gesamtdauer (emom | amrap)
 *
 * @property {number}         [intervals]       - Anzahl Work/Rest-Zyklen (interval)
 * @property {number}         [workSec]         - Arbeitsphase pro Zyklus (interval)
 * @property {number}         [restIntervalSec] - Pause pro Zyklus (interval, NICHT restSec)
 *
 * @property {string[]}       [tags]            - z.B. 'warmup', 'finisher', 'mobility'
 */

// ========================================
// MULTI-USER ENTITY TYPES
// ========================================

/**
 * @typedef {Object} Session
 * @property {string} id
 * @property {string} userId           - Firebase Auth UID des Nutzers
 * @property {'strength'|'cardio'|'recovery'} type
 * @property {*} date                  - Firestore Timestamp
 * @property {Object[]} [exercises]
 * @property {number} [duration]
 * @property {string} [planId]
 * @property {string} [scheduleId]
 * @property {string} [notes]
 */

/**
 * @typedef {Object} Plan
 * @property {string} id
 * @property {string} userId           - Firebase Auth UID des Nutzers
 * @property {string} name
 * @property {string} [type]
 * @property {PlanItem[]} [items]
 */

/**
 * @typedef {Object} ProgressEntry
 * @property {string} id
 * @property {string} userId           - Firebase Auth UID des Nutzers
 * @property {string} exerciseId
 * @property {*} date                  - Firestore Timestamp
 * @property {Object[]} [sets]
 */

/**
 * @typedef {Object} ScheduleEntry
 * @property {string} id
 * @property {string} userId           - Firebase Auth UID des Nutzers
 * @property {string} date             - YYYY-MM-DD
 * @property {string} [planId]
 * @property {string} [planName]
 * @property {boolean} completed
 * @property {string} [sessionId]
 */

/**
 * @typedef {Object} Exercise
 * @property {string} id
 * @property {string} [userId]         - Firebase Auth UID (nur user-created, nicht curated)
 * @property {string} name
 * @property {string[]} muscleGroups
 * @property {number} difficulty
 * @property {string} [source]         - 'curated' | undefined
 */
