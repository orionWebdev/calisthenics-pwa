// ========================================
// SESSION TEMPLATES - Cardio & Recovery
// ========================================

/**
 * Session Template Model
 * {
 *   id: string,
 *   type: 'cardio' | 'recovery',
 *   name: string,
 *   difficulty: 'beginner' | 'intermediate' | 'advanced' | 'elite',
 *   targetDuration: number (minutes),
 *   // Cardio-specific
 *   activityType?: 'run' | 'bike' | 'swim' | 'row' | 'other',
 *   targetDistance?: number (km),
 *   intervals?: { warmup: number, work: number, rest: number, cooldown: number, rounds: number },
 *   // Recovery-specific
 *   focusArea?: 'fullBody' | 'upperBody' | 'lowerBody' | 'back' | 'hips' | 'shoulders',
 *   notes?: string,
 *   createdAt: Timestamp,
 *   updatedAt?: Timestamp
 * }
 */

let allSessionTemplates = [];
let editingSessionTemplateId = null;

// Activity type names mapping
const activityTypeNames = {
  run: 'Laufen',
  bike: 'Radfahren',
  swim: 'Schwimmen',
  row: 'Rudern',
  other: 'Sonstiges'
};

// Activity type icons mapping
const activityTypeIcons = {
  run: 'directions_run',
  bike: 'directions_bike',
  swim: 'pool',
  row: 'rowing',
  other: 'fitness_center'
};

// Focus area names mapping
const focusAreaNames = {
  fullBody: 'Ganzkörper',
  upperBody: 'Oberkörper',
  lowerBody: 'Unterkörper',
  back: 'Rücken',
  hips: 'Hüften',
  shoulders: 'Schultern'
};

// Difficulty level mapping
const difficultyLevels = {
  beginner: { label: 'Anfänger', value: 1, color: '#22c55e' },
  intermediate: { label: 'Mittel', value: 2, color: '#f59e0b' },
  advanced: { label: 'Fortgeschritten', value: 3, color: '#f97316' },
  elite: { label: 'Elite', value: 4, color: '#ef4444' }
};

// ========================================
// FIRESTORE COLLECTION
// ========================================

const sessionTemplatesCollection = db.collection('sessionTemplates');

// ========================================
// LOAD & DISPLAY
// ========================================

async function loadSessionTemplates() {
  try {
    allSessionTemplates = await getAllDocs(sessionTemplatesCollection);
    console.log('✅ Session templates loaded:', allSessionTemplates.length);
    return allSessionTemplates;
  } catch (error) {
    console.error('❌ Error loading session templates:', error);
    return [];
  }
}

function setupSessionTemplatesListener() {
  onCollectionChange(sessionTemplatesCollection, (templates) => {
    allSessionTemplates = templates;
    // Trigger re-render if needed
    if (typeof renderSessionTemplatesList === 'function') {
      renderSessionTemplatesList();
    }
  });
}

// ========================================
// TEMPLATE CREATION MODAL
// ========================================

function openSessionTemplateModal(type = 'cardio', editId = null) {
  editingSessionTemplateId = editId;

  const modal = document.getElementById('session-template-modal');
  if (!modal) {
    console.error('Session template modal not found');
    return;
  }

  const title = editId
    ? (type === 'cardio' ? t('template.cardioTemplate.title') : t('template.recoveryTemplate.title'))
    : t('template.createTemplate');

  document.getElementById('session-template-modal-title').textContent = title;

  // Show/hide type-specific sections
  const cardioSection = document.getElementById('cardio-template-section');
  const recoverySection = document.getElementById('recovery-template-section');

  if (cardioSection) cardioSection.style.display = type === 'cardio' ? 'block' : 'none';
  if (recoverySection) recoverySection.style.display = type === 'recovery' ? 'block' : 'none';

  // Set template type
  document.getElementById('session-template-type').value = type;

  // If editing, populate form
  if (editId) {
    const template = allSessionTemplates.find(t => t.id === editId);
    if (template) {
      populateSessionTemplateForm(template);
    }
  } else {
    clearSessionTemplateForm();
  }

  modal.classList.add('active');
}

function closeSessionTemplateModal() {
  const modal = document.getElementById('session-template-modal');
  if (modal) {
    modal.classList.remove('active');
  }
  clearSessionTemplateForm();
  editingSessionTemplateId = null;
}

function clearSessionTemplateForm() {
  document.getElementById('session-template-name').value = '';
  document.getElementById('session-template-duration').value = '30';
  document.getElementById('session-template-difficulty').value = 'intermediate';
  document.getElementById('session-template-notes').value = '';

  // Cardio fields
  const activityType = document.getElementById('session-template-activity-type');
  if (activityType) activityType.value = 'run';

  const targetDistance = document.getElementById('session-template-distance');
  if (targetDistance) targetDistance.value = '';

  // Reset training type to default
  setCardioTrainingType('liss');

  // Recovery fields
  const focusArea = document.getElementById('session-template-focus-area');
  if (focusArea) focusArea.value = 'fullBody';
}

function populateSessionTemplateForm(template) {
  document.getElementById('session-template-name').value = template.name || '';
  document.getElementById('session-template-duration').value = template.targetDuration || 30;
  document.getElementById('session-template-difficulty').value = template.difficulty || 'intermediate';
  document.getElementById('session-template-notes').value = template.notes || '';

  if (template.type === 'cardio') {
    const activityType = document.getElementById('session-template-activity-type');
    if (activityType) activityType.value = template.activityType || 'run';

    const targetDistance = document.getElementById('session-template-distance');
    if (targetDistance) targetDistance.value = template.targetDistance || '';

    // Restore training type
    setCardioTrainingType(template.trainingType || 'liss');
  } else if (template.type === 'recovery') {
    const focusArea = document.getElementById('session-template-focus-area');
    if (focusArea) focusArea.value = template.focusArea || 'fullBody';
  }
}

async function saveSessionTemplate() {
  const type = document.getElementById('session-template-type').value;
  const name = document.getElementById('session-template-name').value.trim();
  const duration = parseInt(document.getElementById('session-template-duration').value) || 30;
  const difficulty = document.getElementById('session-template-difficulty').value;
  const notes = document.getElementById('session-template-notes').value.trim();

  // Validation
  if (!name) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Bitte gib einen Namen ein');
    }
    return;
  }

  const templateData = {
    type,
    name,
    targetDuration: duration,
    difficulty,
    notes: notes || undefined
  };

  // Add type-specific fields
  if (type === 'cardio') {
    const activityType = document.getElementById('session-template-activity-type');
    if (activityType) templateData.activityType = activityType.value;

    const targetDistance = document.getElementById('session-template-distance');
    if (targetDistance && targetDistance.value) {
      templateData.targetDistance = parseFloat(targetDistance.value);
    }

    // Save training type (HIIT, LISS, Zone 2, etc.)
    const trainingType = document.getElementById('session-template-training-type');
    if (trainingType) templateData.trainingType = trainingType.value;
  } else if (type === 'recovery') {
    const focusArea = document.getElementById('session-template-focus-area');
    if (focusArea) templateData.focusArea = focusArea.value;
  }

  // Show loading
  const saveBtn = document.querySelector('#session-template-modal .modal-save-btn');
  if (saveBtn) {
    saveBtn.disabled = true;
    saveBtn.innerHTML = '<div class="spinner-small"></div><span>Speichert...</span>';
  }

  try {
    if (editingSessionTemplateId) {
      await updateDoc(sessionTemplatesCollection, editingSessionTemplateId, templateData);
      console.log('✅ Session template updated');
    } else {
      await addDoc(sessionTemplatesCollection, templateData);
      console.log('✅ Session template created');
    }

    closeSessionTemplateModal();
    await loadSessionTemplates();

    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', 'Vorlage gespeichert');
    }
  } catch (error) {
    console.error('❌ Error saving session template:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Fehler beim Speichern');
    }
  } finally {
    if (saveBtn) {
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<span class="material-symbols-rounded">check</span><span>Speichern</span>';
    }
  }
}

async function deleteSessionTemplate(id) {
  if (!confirm('Diese Vorlage wirklich löschen?')) {
    return;
  }

  try {
    await deleteDoc(sessionTemplatesCollection, id);
    console.log('✅ Session template deleted');
    await loadSessionTemplates();

    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', 'Vorlage gelöscht');
    }
  } catch (error) {
    console.error('❌ Error deleting session template:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Fehler beim Löschen');
    }
  }
}

// ========================================
// START SESSION FROM TEMPLATE
// ========================================

/**
 * Start a cardio or recovery session from a template
 * Opens the appropriate modal with pre-filled values
 */
function startSessionFromTemplate(templateId, scheduledDate = null) {
  const template = allSessionTemplates.find(t => t.id === templateId);
  if (!template) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Vorlage nicht gefunden');
    }
    return;
  }

  // Ensure valid date
  const dateStr = scheduledDate || formatDate(new Date());

  if (template.type === 'cardio') {
    openAddCardioModalFromTemplate(template, dateStr);
  } else if (template.type === 'recovery') {
    openAddRecoveryModalFromTemplate(template, dateStr);
  }
}

/**
 * Open cardio modal with template values pre-filled
 */
function openAddCardioModalFromTemplate(template, dateStr) {
  // Open the existing cardio modal
  if (typeof openAddCardioModal === 'function') {
    openAddCardioModal(dateStr);
  }

  // Pre-fill values from template
  setTimeout(() => {
    const activityType = document.getElementById('cardio-activity-type');
    if (activityType && template.activityType) {
      activityType.value = template.activityType;
    }

    const duration = document.getElementById('cardio-duration');
    if (duration && template.targetDuration) {
      duration.value = template.targetDuration;
    }

    const distance = document.getElementById('cardio-distance');
    if (distance && template.targetDistance) {
      distance.value = template.targetDistance;
    }

    // Update pace display
    if (typeof updateCardioLivePace === 'function') {
      updateCardioLivePace();
    }
  }, 100);
}

/**
 * Open recovery modal with template values pre-filled
 */
function openAddRecoveryModalFromTemplate(template, dateStr) {
  // Open the existing recovery modal
  if (typeof openAddRecoveryModal === 'function') {
    openAddRecoveryModal(dateStr);
  }

  // Pre-fill values from template
  setTimeout(() => {
    const duration = document.getElementById('recovery-duration');
    if (duration && template.targetDuration) {
      duration.value = template.targetDuration;
    }

    const notes = document.getElementById('recovery-notes');
    if (notes && template.focusArea) {
      notes.value = `Fokus: ${focusAreaNames[template.focusArea] || template.focusArea}`;
    }
  }, 100);
}

// ========================================
// RENDER SESSION TEMPLATES LIST
// ========================================

function renderSessionTemplatesList(containerId = 'session-templates-list') {
  const container = document.getElementById(containerId);
  if (!container) return;

  if (allSessionTemplates.length === 0) {
    container.innerHTML = `
      <div class="empty-state-inline">
        <span class="material-symbols-rounded">description</span>
        <span>${t('planner.noTemplates')}</span>
      </div>
    `;
    return;
  }

  // Training type label mapping
  const trainingTypeLabels = {
    liss: 'LISS',
    zone2: 'Zone 2',
    hiit: 'HIIT',
    tempo: 'Tempo',
    intervals: 'Intervalle'
  };

  container.innerHTML = allSessionTemplates.map(template => {
    const isCardio = template.type === 'cardio';
    const typeIcon = isCardio
      ? (activityTypeIcons[template.activityType] || 'directions_run')
      : 'self_improvement';
    const typeColor = isCardio ? 'var(--color-category-cardio)' : 'var(--color-category-recovery)';
    const typeName = isCardio
      ? (activityTypeNames[template.activityType] || 'Cardio')
      : 'Recovery';
    const difficultyInfo = difficultyLevels[template.difficulty] || difficultyLevels.intermediate;
    const trainingType = isCardio && template.trainingType ? trainingTypeLabels[template.trainingType] : null;

    return `
      <div class="session-template-card" data-template-id="${template.id}">
        <div class="session-template-icon" style="background: ${typeColor}20; color: ${typeColor};">
          <span class="material-symbols-rounded">${typeIcon}</span>
        </div>
        <div class="session-template-content">
          <div class="session-template-name">${template.name}</div>
          <div class="session-template-meta">
            <span class="session-template-type-badge" style="background: ${typeColor}30; color: ${typeColor};">
              ${typeName}
            </span>
            ${trainingType ? `<span class="training-type-badge">${trainingType}</span>` : ''}
            <span>${template.targetDuration} min</span>
            ${template.targetDistance ? `<span>${template.targetDistance} km</span>` : ''}
          </div>
        </div>
        <div class="session-template-difficulty" style="color: ${difficultyInfo.color};">
          ${difficultyInfo.label}
        </div>
        <div class="session-template-actions">
          <button
            onclick="event.stopPropagation(); startSessionFromTemplate('${template.id}')"
            class="session-template-action-btn start"
            title="Session starten"
          >
            <span class="material-symbols-rounded">play_arrow</span>
          </button>
          <button
            onclick="event.stopPropagation(); openSessionTemplateModal('${template.type}', '${template.id}')"
            class="session-template-action-btn"
            title="Bearbeiten"
          >
            <span class="material-symbols-rounded">edit</span>
          </button>
        </div>
      </div>
    `;
  }).join('');
}

// ========================================
// SCHEDULE SESSION TEMPLATE
// ========================================

/**
 * Schedule a session template to a specific date
 */
async function scheduleSessionTemplate(templateId, dateStr) {
  const template = allSessionTemplates.find(t => t.id === templateId);
  if (!template) {
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Vorlage nicht gefunden');
    }
    return null;
  }

  try {
    const scheduleData = {
      type: 'session-template',
      templateId: templateId,
      templateType: template.type,
      templateName: template.name,
      date: dateStr,
      status: 'scheduled',
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    };

    const scheduleId = await addDoc(scheduleCollection, scheduleData);
    console.log('✅ Session template scheduled:', scheduleId);

    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('success', 'Vorlage geplant');
    }

    return scheduleId;
  } catch (error) {
    console.error('❌ Error scheduling session template:', error);
    if (typeof showEdgeFeedback === 'function') {
      showEdgeFeedback('error', 'Fehler beim Planen');
    }
    return null;
  }
}

// ========================================
// UTILITY FUNCTIONS
// ========================================

function getDifficultyFromLevel(level) {
  if (typeof level === 'string') return level;

  // Convert numeric level (1-5) to difficulty enum
  if (level <= 1) return 'beginner';
  if (level <= 2) return 'intermediate';
  if (level <= 3) return 'advanced';
  return 'elite';
}

function getDifficultyLevel(difficulty) {
  return (difficultyLevels[difficulty] || difficultyLevels.intermediate).value;
}

// ========================================
// UI HELPER FUNCTIONS
// ========================================

/**
 * Switch template type in the modal
 */
function switchTemplateType(type) {
  document.getElementById('session-template-type').value = type;

  // Update button states
  document.querySelectorAll('.template-type-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.type === type);
  });

  // Show/hide type-specific sections
  const cardioSection = document.getElementById('cardio-template-section');
  const recoverySection = document.getElementById('recovery-template-section');

  if (cardioSection) cardioSection.style.display = type === 'cardio' ? 'block' : 'none';
  if (recoverySection) recoverySection.style.display = type === 'recovery' ? 'block' : 'none';
}

/**
 * Set difficulty in the session template modal
 */
function setSessionTemplateDifficulty(difficulty) {
  document.getElementById('session-template-difficulty').value = difficulty;

  // Update pill states
  document.querySelectorAll('#session-template-modal .difficulty-pill').forEach(pill => {
    pill.classList.toggle('active', pill.dataset.difficulty === difficulty);
  });
}

/**
 * Set cardio training type (HIIT, LISS, Zone 2, etc.)
 */
function setCardioTrainingType(type) {
  const input = document.getElementById('session-template-training-type');
  if (input) input.value = type;

  // Update button states
  document.querySelectorAll('.training-type-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.type === type);
  });

  // Update info text
  updateTrainingTypeInfo(type);
}

/**
 * Update the training type info text
 */
function updateTrainingTypeInfo(type) {
  const infoText = document.getElementById('training-type-info-text');
  if (!infoText) return;

  const infoTexts = {
    liss: t('template.cardioTemplate.trainingTypeInfo.liss'),
    zone2: t('template.cardioTemplate.trainingTypeInfo.zone2'),
    hiit: t('template.cardioTemplate.trainingTypeInfo.hiit'),
    tempo: t('template.cardioTemplate.trainingTypeInfo.tempo'),
    intervals: t('template.cardioTemplate.trainingTypeInfo.intervals')
  };

  infoText.textContent = infoTexts[type] || infoTexts.liss;
}

/**
 * Toggle training type info panel visibility
 */
function toggleTrainingTypeInfo() {
  const panel = document.getElementById('training-type-info-panel');
  if (panel) {
    const isVisible = panel.style.display !== 'none';
    panel.style.display = isVisible ? 'none' : 'block';
  }
}

// ========================================
// EXPORTS
// ========================================

window.allSessionTemplates = allSessionTemplates;
window.loadSessionTemplates = loadSessionTemplates;
window.setupSessionTemplatesListener = setupSessionTemplatesListener;
window.openSessionTemplateModal = openSessionTemplateModal;
window.closeSessionTemplateModal = closeSessionTemplateModal;
window.saveSessionTemplate = saveSessionTemplate;
window.deleteSessionTemplate = deleteSessionTemplate;
window.startSessionFromTemplate = startSessionFromTemplate;
window.renderSessionTemplatesList = renderSessionTemplatesList;
window.scheduleSessionTemplate = scheduleSessionTemplate;
window.activityTypeNames = activityTypeNames;
window.activityTypeIcons = activityTypeIcons;
window.focusAreaNames = focusAreaNames;
window.difficultyLevels = difficultyLevels;
window.getDifficultyFromLevel = getDifficultyFromLevel;
window.getDifficultyLevel = getDifficultyLevel;
window.switchTemplateType = switchTemplateType;
window.setSessionTemplateDifficulty = setSessionTemplateDifficulty;
window.setCardioTrainingType = setCardioTrainingType;
window.updateTrainingTypeInfo = updateTrainingTypeInfo;
window.toggleTrainingTypeInfo = toggleTrainingTypeInfo;

console.log('✅ Session Templates module loaded');
