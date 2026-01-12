// ========================================
// PREDEFINED EXERCISES DATA
// ========================================

const defaultExercises = [
  {
    name: 'Pull-ups',
    description: 'Hänge dich an die Stange, Hände schulterbreit. Ziehe deinen Körper hoch bis das Kinn über der Stange ist. Langsam wieder runter.',
    muscleGroups: ['back', 'arms'],
    equipment: ['pull-up-bar'],
    difficulty: 3,
    imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'
  },
  {
    name: 'Push-ups',
    description: 'Liegestützposition, Hände schulterbreit. Körper gerade halten. Runter bis die Brust fast den Boden berührt, dann explosiv hoch.',
    muscleGroups: ['chest', 'arms', 'shoulders'],
    equipment: ['none'],
    difficulty: 2,
    imageUrl: 'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?w=400'
  },
  {
    name: 'Dips',
    description: 'An Barren abstützen, Körper gerade. Runter bis die Schultern auf Ellenbogenhöhe sind. Hoch drücken.',
    muscleGroups: ['chest', 'arms', 'shoulders'],
    equipment: ['dip-bars'],
    difficulty: 3,
    imageUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400'
  },
  {
    name: 'Muscle-up',
    description: 'Pull-up + Dip in einer Bewegung. Explosiv hochziehen, Körper über die Stange bringen, in Dip-Position drücken.',
    muscleGroups: ['back', 'chest', 'arms', 'shoulders'],
    equipment: ['pull-up-bar', 'rings'],
    difficulty: 5,
    imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400'
  },
  {
    name: 'Handstand Push-ups',
    description: 'Handstand an der Wand. Kontrolliert runter bis der Kopf fast den Boden berührt. Hoch drücken.',
    muscleGroups: ['shoulders', 'arms'],
    equipment: ['wall'],
    difficulty: 4,
    imageUrl: 'https://images.unsplash.com/photo-1599058917212-d750089bc07e?w=400'
  },
  {
    name: 'Pistol Squats',
    description: 'Einbeinige Kniebeuge. Ein Bein nach vorne gestreckt, mit dem anderen tief runter. Balance halten!',
    muscleGroups: ['legs'],
    equipment: ['none'],
    difficulty: 4,
    imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400'
  },
  {
    name: 'L-Sit',
    description: 'Auf Barren oder Boden. Beine gestreckt nach vorne, Körper nur mit Armen in der Luft halten.',
    muscleGroups: ['core', 'arms'],
    equipment: ['parallettes', 'dip-bars'],
    difficulty: 3,
    imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400'
  },
  {
    name: 'Planche',
    description: 'Körper parallel zum Boden, nur mit Händen gestützt. Extrem anspruchsvoll!',
    muscleGroups: ['shoulders', 'core', 'chest'],
    equipment: ['parallettes'],
    difficulty: 5,
    imageUrl: 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?w=400'
  },
  {
    name: 'Front Lever',
    description: 'Körper waagerecht unter der Stange halten, nur mit Händen. Körperspannung maximal!',
    muscleGroups: ['back', 'core'],
    equipment: ['pull-up-bar', 'rings'],
    difficulty: 5,
    imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400'
  },
  {
    name: 'Dragon Flag',
    description: 'Rückenlage auf Bank, Körper steif nach oben, nur Schultern berühren Bank. Langsam runter.',
    muscleGroups: ['core'],
    equipment: ['box'],
    difficulty: 4,
    imageUrl: 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=400'
  },
  {
    name: 'Archer Push-ups',
    description: 'Breite Liegestütz-Position. Gewicht auf eine Seite verlagern, andere Arm gestreckt lassen.',
    muscleGroups: ['chest', 'shoulders', 'arms'],
    equipment: ['none'],
    difficulty: 3,
    imageUrl: 'https://images.unsplash.com/photo-1517963879433-6ad2b056d712?w=400'
  },
  {
    name: 'Hanging Leg Raises',
    description: 'An Stange hängen, Beine gestreckt bis 90° hochheben. Kontrolliert runter.',
    muscleGroups: ['core'],
    equipment: ['pull-up-bar'],
    difficulty: 3,
    imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'
  },
  {
    name: 'Typewriter Pull-ups',
    description: 'Pull-up hoch, dann seitlich zur einen Hand, zur anderen, runter. Fließende Bewegung.',
    muscleGroups: ['back', 'arms'],
    equipment: ['pull-up-bar'],
    difficulty: 4,
    imageUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400'
  },
  {
    name: 'Human Flag',
    description: 'Seitlich an vertikaler Stange, Körper waagerecht halten. Extrem schwer!',
    muscleGroups: ['core', 'shoulders', 'back'],
    equipment: ['pull-up-bar', 'wall'],
    difficulty: 5,
    imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400'
  },
  {
    name: 'Decline Push-ups',
    description: 'Füße erhöht (auf Bank/Box), normale Push-ups. Mehr Gewicht auf Armen.',
    muscleGroups: ['chest', 'shoulders', 'arms'],
    equipment: ['box'],
    difficulty: 2,
    imageUrl: 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=400'
  }
];

// ========================================
// INITIALIZE DEFAULT EXERCISES
// ========================================

// Wird beim ersten Laden aufgerufen
async function initializeDefaultExercises() {
  try {
    // Check ob schon Übungen existieren
    const existing = await getAllDocs(exercisesCollection);
    
    if (existing.length === 0) {
      console.log('📚 Initializing default exercises...');
      
      // Alle default Übungen hinzufügen
      for (const exercise of defaultExercises) {
        await addDoc(exercisesCollection, exercise);
      }
      
      console.log('✅ Default exercises added!');
    } else {
      console.log(`📚 ${existing.length} exercises already in database`);
    }
  } catch (error) {
    console.error('Error initializing exercises:', error);
  }
}