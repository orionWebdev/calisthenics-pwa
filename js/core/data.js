// ========================================
// PREDEFINED EXERCISES DATA (CURATED CORE)
// ========================================
// 80 curated essential strength & calisthenics exercises.
// Single source of truth — generated/maintained dataset (no external API).
// source: 'curated' marks these as read-only default exercises.
//
// Muscle model: each exercise has explicit primaryMuscles (>=1) and
// secondaryMuscles (0..n). `muscleGroups` is the derived flat list
// [...primary, ...secondary] kept for backward compatibility.
// Canonical muscles: chest, back, shoulders, biceps, triceps, core, quads, hamstrings, glutes, calves.
//
// Bump CURATED_SEED_VERSION whenever this dataset changes so existing installs
// re-seed the global exercises_curated collection (clean slate, stable ids).

const CURATED_SEED_VERSION = 2;
const CURATED_SEED_KEY = 'curated_seed_version';

const defaultExercises = [
  {
    "id": "push_up",
    "name": "Push Up",
    "name_de": "Liegestütze",
    "type": "bodyweight",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [
      "triceps",
      "shoulders"
    ],
    "muscleGroups": [
      "chest",
      "triceps",
      "shoulders"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Place your hands shoulder-width apart on the floor with arms fully extended.",
      "Lower your chest toward the ground by bending your elbows to about 90 degrees.",
      "Push through your palms to return to the starting position.",
      "Keep your body in a straight line from head to heels throughout."
    ],
    "cues": [
      "Engage your core and squeeze your glutes to prevent hip sagging.",
      "Keep elbows at roughly a 45-degree angle from your torso.",
      "Breathe in on the way down, exhale as you push up."
    ],
    "commonMistakes": [
      "Letting the hips sag or pike up, breaking the straight body line.",
      "Flaring elbows out to 90 degrees, which strains the shoulders.",
      "Not reaching full range of motion at the bottom or top."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Platziere die Hände schulterbreit auf dem Boden mit vollständig gestreckten Armen.",
          "Senke die Brust zum Boden, indem du die Ellbogen auf etwa 90 Grad beugst.",
          "Drücke dich über die Handflächen zurück in die Ausgangsposition.",
          "Halte den Körper während der gesamten Bewegung in einer geraden Linie von Kopf bis Ferse."
        ],
        "cues": [
          "Spanne den Rumpf an und drücke die Gesäßmuskeln zusammen, um ein Durchhängen der Hüfte zu vermeiden.",
          "Halte die Ellbogen in einem Winkel von etwa 45 Grad zum Oberkörper.",
          "Atme beim Absenken ein und beim Hochdrücken aus."
        ],
        "commonMistakes": [
          "Die Hüfte hängen lassen oder nach oben drücken, wodurch die gerade Körperlinie verloren geht.",
          "Ellbogen auf 90 Grad abspreizen, was die Schultern belastet.",
          "Den vollen Bewegungsumfang am tiefsten oder höchsten Punkt nicht erreichen."
        ]
      }
    }
  },
  {
    "id": "decline_push_up",
    "name": "Decline Push Up",
    "name_de": "Negative Liegestütze",
    "type": "bodyweight",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [
      "shoulders"
    ],
    "muscleGroups": [
      "chest",
      "shoulders"
    ],
    "equipment": [
      "bodyweight",
      "box"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Place your feet on a raised surface like a box and your hands on the floor shoulder-width apart.",
      "Lower your chest toward the ground while maintaining a straight body line.",
      "Push back up to full arm extension.",
      "Keep your core tight to prevent your lower back from arching."
    ],
    "cues": [
      "The higher the feet, the more shoulder-dominant the exercise becomes.",
      "Look slightly forward, not straight down, to keep the neck neutral.",
      "Drive through the full palm, spreading your fingers for stability."
    ],
    "commonMistakes": [
      "Letting the hips sag under the increased angle.",
      "Placing hands too far forward, reducing chest engagement.",
      "Using a surface that is too high before building adequate strength."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stelle die Füße auf eine erhöhte Fläche wie eine Box und die Hände schulterbreit auf den Boden.",
          "Senke die Brust zum Boden und halte dabei eine gerade Körperlinie.",
          "Drücke dich zurück in die volle Armstreckung.",
          "Halte den Rumpf angespannt, um ein Hohlkreuz zu vermeiden."
        ],
        "cues": [
          "Je höher die Füße, desto mehr werden die Schultern beansprucht.",
          "Schaue leicht nach vorne, nicht gerade nach unten, um den Nacken neutral zu halten.",
          "Drücke über die gesamte Handfläche und spreize die Finger für Stabilität."
        ],
        "commonMistakes": [
          "Die Hüfte unter dem erhöhten Winkel durchhängen lassen.",
          "Die Hände zu weit vorne platzieren, was die Brustbeteiligung verringert.",
          "Eine zu hohe Fläche verwenden, bevor ausreichend Kraft aufgebaut wurde."
        ]
      }
    }
  },
  {
    "id": "diamond_push_up",
    "name": "Diamond Push Up",
    "name_de": "Diamant-Liegestütze",
    "type": "bodyweight",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [
      "triceps"
    ],
    "muscleGroups": [
      "chest",
      "triceps"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Place your hands close together under your chest so thumbs and index fingers form a diamond shape.",
      "Lower your chest toward your hands by bending your elbows.",
      "Push back up to full extension while keeping elbows close to your body.",
      "Maintain a rigid plank position throughout the movement."
    ],
    "cues": [
      "Keep the elbows tucked tight to the ribcage.",
      "Focus on squeezing the triceps at the top of each rep.",
      "If wrists feel strained, widen the hand position slightly."
    ],
    "commonMistakes": [
      "Flaring the elbows outward, reducing triceps activation.",
      "Shortening the range of motion because the exercise feels hard.",
      "Allowing the hips to pike up to make the push easier."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Platziere die Hände eng zusammen unter der Brust, sodass Daumen und Zeigefinger eine Rautenform bilden.",
          "Senke die Brust zu den Händen, indem du die Ellbogen beugst.",
          "Drücke dich zurück in die volle Streckung und halte die Ellbogen nah am Körper.",
          "Halte während der gesamten Bewegung eine stabile Plank-Position."
        ],
        "cues": [
          "Halte die Ellbogen eng am Brustkorb.",
          "Konzentriere dich darauf, den Trizeps am höchsten Punkt jeder Wiederholung anzuspannen.",
          "Bei Handgelenkbeschwerden die Handposition leicht verbreitern."
        ],
        "commonMistakes": [
          "Die Ellbogen nach außen abspreizen, was die Trizepsaktivierung verringert.",
          "Den Bewegungsumfang verkürzen, weil die Übung schwer ist.",
          "Die Hüfte nach oben drücken, um das Drücken zu erleichtern."
        ]
      }
    }
  },
  {
    "id": "wide_push_up",
    "name": "Wide Push Up",
    "name_de": "Breite Liegestütze",
    "type": "bodyweight",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [
      "shoulders"
    ],
    "muscleGroups": [
      "chest",
      "shoulders"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Place your hands about 1.5 times shoulder-width apart on the floor.",
      "Lower your chest to the ground while keeping your elbows pointing outward.",
      "Push back up to full arm extension.",
      "Maintain a straight body line from head to heels throughout."
    ],
    "cues": [
      "Think about spreading the floor apart with your hands for chest activation.",
      "Keep your core braced to avoid hip sag.",
      "Control the descent for at least two seconds."
    ],
    "commonMistakes": [
      "Placing hands too wide, which limits range of motion and strains shoulders.",
      "Letting the head drop forward instead of keeping a neutral spine.",
      "Rushing through reps without controlling the eccentric phase."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Platziere die Hände etwa anderthalbfach schulterbreit auf dem Boden.",
          "Senke die Brust zum Boden und lass die Ellbogen nach außen zeigen.",
          "Drücke dich zurück in die volle Armstreckung.",
          "Halte während der gesamten Bewegung eine gerade Körperlinie von Kopf bis Ferse."
        ],
        "cues": [
          "Stelle dir vor, den Boden mit den Händen auseinanderzudrücken, um die Brust zu aktivieren.",
          "Halte den Rumpf angespannt, um ein Durchhängen der Hüfte zu vermeiden.",
          "Kontrolliere das Absenken für mindestens zwei Sekunden."
        ],
        "commonMistakes": [
          "Die Hände zu weit platzieren, was den Bewegungsumfang einschränkt und die Schultern belastet.",
          "Den Kopf nach vorne hängen lassen, statt eine neutrale Wirbelsäule beizubehalten.",
          "Wiederholungen ohne Kontrolle der exzentrischen Phase durchhasten."
        ]
      }
    }
  },
  {
    "id": "archer_push_up",
    "name": "Archer Push Up",
    "name_de": "Bogenschützen-Liegestütze",
    "type": "bodyweight",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [
      "triceps",
      "shoulders"
    ],
    "muscleGroups": [
      "chest",
      "triceps",
      "shoulders"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 3,
    "source": "curated",
    "instructionsSteps": [
      "Start in a wide push-up position with hands turned slightly outward.",
      "Lower your body toward one hand while extending the other arm out straight.",
      "Push back up to the center starting position.",
      "Alternate sides with each repetition."
    ],
    "cues": [
      "Keep the straight arm active and pressing into the floor.",
      "Shift your weight deliberately over the working arm.",
      "Maintain a tight plank throughout the entire movement."
    ],
    "commonMistakes": [
      "Not fully extending the non-working arm, reducing unilateral loading.",
      "Rotating the torso excessively instead of staying square to the ground.",
      "Using momentum to bounce out of the bottom position."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Starte in einer breiten Liegestützposition mit leicht nach außen gedrehten Händen.",
          "Senke den Körper zu einer Hand, während du den anderen Arm gerade ausstreckst.",
          "Drücke dich zurück in die zentrale Ausgangsposition.",
          "Wechsle die Seiten mit jeder Wiederholung."
        ],
        "cues": [
          "Halte den gestreckten Arm aktiv und drücke ihn in den Boden.",
          "Verlagere dein Gewicht bewusst über den arbeitenden Arm.",
          "Halte während der gesamten Bewegung eine stabile Plank-Position."
        ],
        "commonMistakes": [
          "Den nicht arbeitenden Arm nicht vollständig strecken, was die einseitige Belastung verringert.",
          "Den Oberkörper übermäßig rotieren, anstatt parallel zum Boden zu bleiben.",
          "Schwung nutzen, um aus der tiefsten Position herauszukommen."
        ]
      }
    }
  },
  {
    "id": "pseudo_planche_push_up",
    "name": "Pseudo Planche Push Up",
    "name_de": "Pseudo-Planche-Liegestütze",
    "type": "bodyweight",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [
      "shoulders",
      "triceps"
    ],
    "muscleGroups": [
      "chest",
      "shoulders",
      "triceps"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 4,
    "source": "curated",
    "instructionsSteps": [
      "Place your hands by your waist with fingers pointing sideways or backward.",
      "Lean your shoulders well forward past your hands.",
      "Lower yourself while maintaining the forward lean.",
      "Push back up without letting your shoulders drift backward."
    ],
    "cues": [
      "Protract your shoulder blades to round the upper back slightly.",
      "Keep your body in a straight line and avoid piking at the hips.",
      "The more forward lean, the harder the exercise becomes."
    ],
    "commonMistakes": [
      "Not leaning far enough forward, turning it into a regular push-up.",
      "Placing hands too far forward instead of near the waist.",
      "Losing the forward lean during the pushing phase."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Platziere die Hände auf Höhe der Taille mit Fingern seitlich oder nach hinten zeigend.",
          "Lehne die Schultern deutlich über die Hände nach vorne.",
          "Senke dich ab, während du die Vorneigung beibehältst.",
          "Drücke dich hoch, ohne die Schultern nach hinten driften zu lassen."
        ],
        "cues": [
          "Protrahiere die Schulterblätter, um den oberen Rücken leicht zu runden.",
          "Halte den Körper in einer geraden Linie und vermeide ein Abknicken in der Hüfte.",
          "Je weiter du dich nach vorne lehnst, desto schwerer wird die Übung."
        ],
        "commonMistakes": [
          "Sich nicht weit genug nach vorne lehnen, wodurch es ein normaler Liegestütz wird.",
          "Die Hände zu weit vorne statt in der Nähe der Taille platzieren.",
          "Die Vorneigung während der Druckphase verlieren."
        ]
      }
    }
  },
  {
    "id": "dips",
    "name": "Dips",
    "type": "bodyweight",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [
      "triceps",
      "shoulders"
    ],
    "muscleGroups": [
      "chest",
      "triceps",
      "shoulders"
    ],
    "equipment": [
      "dip-bars"
    ],
    "difficulty": 3,
    "source": "curated",
    "instructionsSteps": [
      "Grip the dip bars and lift yourself to straight-arm support.",
      "Lower your body by bending your elbows until your upper arms are parallel to the floor.",
      "Push back up to full arm extension.",
      "Lean slightly forward to emphasize the chest or stay upright for more triceps focus."
    ],
    "cues": [
      "Keep your shoulders down and away from your ears.",
      "Control the descent; do not drop into the bottom position.",
      "Exhale forcefully as you press back up."
    ],
    "commonMistakes": [
      "Going too deep, which places excessive stress on the shoulder capsule.",
      "Swinging the legs to generate momentum.",
      "Shrugging the shoulders up toward the ears."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Greife die Dip-Barren und hebe dich in den Stütz mit gestreckten Armen.",
          "Senke den Körper, indem du die Ellbogen beugst, bis die Oberarme parallel zum Boden sind.",
          "Drücke dich zurück in die volle Armstreckung.",
          "Lehne dich leicht nach vorne für mehr Brustfokus oder bleibe aufrecht für mehr Trizeps."
        ],
        "cues": [
          "Halte die Schultern unten und weg von den Ohren.",
          "Kontrolliere das Absenken; lasse dich nicht in die tiefste Position fallen.",
          "Atme kräftig aus, wenn du dich hochdrückst."
        ],
        "commonMistakes": [
          "Zu tief gehen, was die Schulterkapsel übermäßig belastet.",
          "Die Beine schwingen, um Schwung zu erzeugen.",
          "Die Schultern zu den Ohren hochziehen."
        ]
      }
    }
  },
  {
    "id": "ring_dips",
    "name": "Ring Dips",
    "name_de": "Ring-Dips",
    "type": "bodyweight",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [
      "triceps",
      "shoulders"
    ],
    "muscleGroups": [
      "chest",
      "triceps",
      "shoulders"
    ],
    "equipment": [
      "rings"
    ],
    "difficulty": 4,
    "source": "curated",
    "instructionsSteps": [
      "Mount the rings and press to a straight-arm support with rings turned out.",
      "Lower yourself under control until your upper arms are parallel to the ground.",
      "Press back up to full lockout while stabilizing the rings.",
      "Keep the rings close to your body throughout the movement."
    ],
    "cues": [
      "Turn the rings out at the top to fully activate the triceps and stabilizers.",
      "Squeeze the rings tightly to minimize wobble.",
      "Maintain a slight forward lean for chest engagement."
    ],
    "commonMistakes": [
      "Letting the rings drift away from the body, losing control.",
      "Not achieving full lockout and ring turnout at the top.",
      "Attempting ring dips before mastering stable ring support holds."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Steige an die Ringe und drücke dich in den Stütz mit nach außen gedrehten Ringen.",
          "Senke dich kontrolliert ab, bis die Oberarme parallel zum Boden sind.",
          "Drücke dich zurück in die volle Streckung und stabilisiere dabei die Ringe.",
          "Halte die Ringe während der gesamten Bewegung nah am Körper."
        ],
        "cues": [
          "Drehe die Ringe oben nach außen, um Trizeps und Stabilisatoren voll zu aktivieren.",
          "Drücke die Ringe fest zusammen, um Wackeln zu minimieren.",
          "Halte eine leichte Vorneigung für die Brustbeteiligung."
        ],
        "commonMistakes": [
          "Die Ringe vom Körper wegdriften lassen und die Kontrolle verlieren.",
          "Oben keine volle Streckung und Ringausdrehung erreichen.",
          "Ring-Dips versuchen, bevor der stabile Ringstütz beherrscht wird."
        ]
      }
    }
  },
  {
    "id": "pull_up",
    "name": "Pull Up",
    "name_de": "Klimmzug",
    "type": "bodyweight",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "biceps"
    ],
    "muscleGroups": [
      "back",
      "biceps"
    ],
    "equipment": [
      "pull-up-bar"
    ],
    "difficulty": 3,
    "source": "curated",
    "instructionsSteps": [
      "Hang from the bar with an overhand grip slightly wider than shoulder-width.",
      "Pull yourself up until your chin clears the bar.",
      "Lower yourself under control back to a full dead hang.",
      "Initiate the pull by depressing and retracting your shoulder blades."
    ],
    "cues": [
      "Think about driving your elbows down and back toward your hips.",
      "Avoid kipping or swinging your legs for momentum.",
      "Fully extend your arms at the bottom of each rep."
    ],
    "commonMistakes": [
      "Using momentum or kipping instead of strict pulling strength.",
      "Not going to full extension at the bottom, cutting range of motion short.",
      "Craning the neck forward to get the chin over the bar."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Hänge mit einem Obergriff etwas breiter als schulterbreit an der Stange.",
          "Ziehe dich hoch, bis dein Kinn über die Stange kommt.",
          "Senke dich kontrolliert zurück in den vollen Aushang.",
          "Beginne den Zug, indem du die Schulterblätter nach unten und zusammenziehst."
        ],
        "cues": [
          "Stelle dir vor, die Ellbogen nach unten und hinten zu den Hüften zu ziehen.",
          "Vermeide Kipping oder Schwingen der Beine für Schwung.",
          "Strecke die Arme am tiefsten Punkt jeder Wiederholung vollständig."
        ],
        "commonMistakes": [
          "Schwung oder Kipping nutzen statt reiner Zugkraft.",
          "Am tiefsten Punkt nicht vollständig strecken und den Bewegungsumfang verkürzen.",
          "Den Hals nach vorne strecken, um das Kinn über die Stange zu bekommen."
        ]
      }
    }
  },
  {
    "id": "chin_up",
    "name": "Chin Up",
    "name_de": "Klimmzug im Untergriff",
    "type": "bodyweight",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "biceps"
    ],
    "muscleGroups": [
      "back",
      "biceps"
    ],
    "equipment": [
      "pull-up-bar"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Hang from the bar with an underhand (supinated) grip at shoulder-width.",
      "Pull yourself up until your chin is above the bar.",
      "Lower yourself under control to a full dead hang.",
      "Keep your elbows pointing forward throughout the movement."
    ],
    "cues": [
      "Squeeze your biceps hard at the top of the movement.",
      "Depress your shoulders before initiating the pull.",
      "Keep your chest up and aim to touch the bar with your upper chest."
    ],
    "commonMistakes": [
      "Using excessive body swing to complete reps.",
      "Only pulling halfway up instead of getting the chin over the bar.",
      "Letting the shoulders shrug up to the ears at the bottom."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Hänge mit einem Untergriff (supiniert) schulterbreit an der Stange.",
          "Ziehe dich hoch, bis dein Kinn über der Stange ist.",
          "Senke dich kontrolliert in den vollen Aushang.",
          "Halte die Ellbogen während der gesamten Bewegung nach vorne gerichtet."
        ],
        "cues": [
          "Spanne den Bizeps am höchsten Punkt der Bewegung stark an.",
          "Drücke die Schultern nach unten, bevor du den Zug einleitest.",
          "Halte die Brust oben und versuche, die Stange mit der oberen Brust zu berühren."
        ],
        "commonMistakes": [
          "Übermäßiges Körperschwingen nutzen, um Wiederholungen zu schaffen.",
          "Nur halb hochziehen, statt das Kinn über die Stange zu bringen.",
          "Die Schultern am tiefsten Punkt zu den Ohren hochziehen lassen."
        ]
      }
    }
  },
  {
    "id": "wide_pull_up",
    "name": "Wide Pull Up",
    "name_de": "Breiter Klimmzug",
    "type": "bodyweight",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "shoulders",
      "biceps"
    ],
    "muscleGroups": [
      "back",
      "shoulders",
      "biceps"
    ],
    "equipment": [
      "pull-up-bar"
    ],
    "difficulty": 3,
    "source": "curated",
    "instructionsSteps": [
      "Grip the bar with an overhand grip about 1.5 times shoulder-width.",
      "Pull yourself up until your chin clears the bar.",
      "Lower yourself under control to a full hang.",
      "Focus on driving the elbows down toward the hips."
    ],
    "cues": [
      "Initiate the movement by pulling your shoulder blades together.",
      "Keep your chest up and think about pulling the bar to your collarbone.",
      "Avoid swinging or kipping to maintain strict form."
    ],
    "commonMistakes": [
      "Gripping too wide, which limits range of motion and strains the shoulders.",
      "Not pulling high enough due to reduced leverage.",
      "Letting the shoulders roll forward at the top of the movement."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Greife die Stange mit einem Obergriff etwa anderthalbfach schulterbreit.",
          "Ziehe dich hoch, bis dein Kinn über der Stange ist.",
          "Senke dich kontrolliert in den vollen Aushang.",
          "Konzentriere dich darauf, die Ellbogen nach unten zu den Hüften zu ziehen."
        ],
        "cues": [
          "Leite die Bewegung ein, indem du die Schulterblätter zusammenziehst.",
          "Halte die Brust oben und stelle dir vor, die Stange zum Schlüsselbein zu ziehen.",
          "Vermeide Schwingen oder Kipping, um saubere Form beizubehalten."
        ],
        "commonMistakes": [
          "Zu breit greifen, was den Bewegungsumfang einschränkt und die Schultern belastet.",
          "Aufgrund der reduzierten Hebelwirkung nicht hoch genug ziehen.",
          "Die Schultern am höchsten Punkt der Bewegung nach vorne rollen lassen."
        ]
      }
    }
  },
  {
    "id": "australian_pull_up",
    "name": "Australian Pull Up",
    "name_de": "Australischer Klimmzug",
    "type": "bodyweight",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "biceps"
    ],
    "muscleGroups": [
      "back",
      "biceps"
    ],
    "equipment": [
      "pull-up-bar"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Set a bar at about waist height and hang underneath with an overhand grip.",
      "Keep your body in a straight line with heels on the ground.",
      "Pull your chest to the bar by squeezing your shoulder blades together.",
      "Lower yourself back to full arm extension under control."
    ],
    "cues": [
      "Keep your hips up and body rigid like a reverse plank.",
      "Squeeze your shoulder blades together at the top.",
      "Lower the bar height to increase difficulty."
    ],
    "commonMistakes": [
      "Letting the hips sag, breaking the straight body line.",
      "Only pulling with the arms instead of engaging the back.",
      "Not pulling the chest all the way to the bar."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stelle eine Stange auf etwa Hüfthöhe ein und hänge dich mit Obergriff darunter.",
          "Halte den Körper in einer geraden Linie mit den Fersen auf dem Boden.",
          "Ziehe die Brust zur Stange, indem du die Schulterblätter zusammenziehst.",
          "Senke dich kontrolliert zurück in die volle Armstreckung."
        ],
        "cues": [
          "Halte die Hüfte oben und den Körper steif wie bei einem umgekehrten Plank.",
          "Drücke die Schulterblätter am höchsten Punkt zusammen.",
          "Senke die Stangenhöhe ab, um den Schwierigkeitsgrad zu erhöhen."
        ],
        "commonMistakes": [
          "Die Hüfte durchhängen lassen und die gerade Körperlinie brechen.",
          "Nur mit den Armen ziehen, statt den Rücken einzusetzen.",
          "Die Brust nicht bis zur Stange ziehen."
        ]
      }
    }
  },
  {
    "id": "muscle_up",
    "name": "Muscle Up",
    "type": "bodyweight",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "chest",
      "triceps",
      "shoulders",
      "biceps"
    ],
    "muscleGroups": [
      "back",
      "chest",
      "triceps",
      "shoulders",
      "biceps"
    ],
    "equipment": [
      "pull-up-bar"
    ],
    "difficulty": 5,
    "source": "curated",
    "instructionsSteps": [
      "Hang from the bar with a false (thumbless) overhand grip.",
      "Perform an explosive pull-up while pulling the bar toward your hips.",
      "Transition over the bar by leaning your chest forward.",
      "Press to full lockout above the bar."
    ],
    "cues": [
      "Use a slight swing to generate momentum for the transition.",
      "Pull the bar to your waistline, not your chin.",
      "Lean aggressively forward during the transition phase."
    ],
    "commonMistakes": [
      "Pulling to the chin instead of the waist, making the transition impossible.",
      "Not leaning forward enough during the transition.",
      "Attempting muscle-ups without a strong high pull-up foundation."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Hänge mit einem daumenlosen Obergriff an der Stange.",
          "Führe einen explosiven Klimmzug aus und ziehe die Stange Richtung Hüfte.",
          "Gehe über die Stange, indem du die Brust nach vorne lehnst.",
          "Drücke dich in die volle Streckung über der Stange."
        ],
        "cues": [
          "Nutze einen leichten Schwung, um Momentum für den Übergang zu erzeugen.",
          "Ziehe die Stange zur Taille, nicht zum Kinn.",
          "Lehne dich während der Übergangsphase aggressiv nach vorne."
        ],
        "commonMistakes": [
          "Zum Kinn statt zur Taille ziehen, was den Übergang unmöglich macht.",
          "Sich während des Übergangs nicht weit genug nach vorne lehnen.",
          "Muscle-Ups versuchen, ohne eine starke Grundlage bei hohen Klimmzügen zu haben."
        ]
      }
    }
  },
  {
    "id": "ring_muscle_up",
    "name": "Ring Muscle Up",
    "type": "bodyweight",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "chest",
      "triceps",
      "shoulders",
      "biceps"
    ],
    "muscleGroups": [
      "back",
      "chest",
      "triceps",
      "shoulders",
      "biceps"
    ],
    "equipment": [
      "rings"
    ],
    "difficulty": 5,
    "source": "curated",
    "instructionsSteps": [
      "Hang from the rings with a false grip, wrists over the top of the rings.",
      "Pull explosively while bringing your elbows tight to your body.",
      "Transition by rolling your chest over the rings.",
      "Press to full lockout with rings turned out."
    ],
    "cues": [
      "Maintain the false grip throughout the entire movement.",
      "Pull deep to your sternum before initiating the transition.",
      "Keep the rings as close together as possible."
    ],
    "commonMistakes": [
      "Losing the false grip during the pull, making the transition impossible.",
      "Letting the rings flare out wide during the movement.",
      "Not pulling deep enough before attempting the transition."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Hänge mit einem Stützgriff an den Ringen, Handgelenke über den Ringen.",
          "Ziehe explosiv und bringe die Ellbogen eng an den Körper.",
          "Gehe über, indem du die Brust über die Ringe rollst.",
          "Drücke dich in die volle Streckung mit nach außen gedrehten Ringen."
        ],
        "cues": [
          "Halte den Stützgriff während der gesamten Bewegung aufrecht.",
          "Ziehe tief zum Brustbein, bevor du den Übergang einleitest.",
          "Halte die Ringe so nah zusammen wie möglich."
        ],
        "commonMistakes": [
          "Den Stützgriff beim Ziehen verlieren, was den Übergang unmöglich macht.",
          "Die Ringe während der Bewegung weit auseinanderdriften lassen.",
          "Nicht tief genug ziehen, bevor man den Übergang versucht."
        ]
      }
    }
  },
  {
    "id": "typewriter_pull_up",
    "name": "Typewriter Pull Up",
    "name_de": "Schreibmaschinen-Klimmzug",
    "type": "bodyweight",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "biceps",
      "shoulders"
    ],
    "muscleGroups": [
      "back",
      "biceps",
      "shoulders"
    ],
    "equipment": [
      "pull-up-bar"
    ],
    "difficulty": 4,
    "source": "curated",
    "instructionsSteps": [
      "Pull up to the top of a wide-grip pull-up with chin above the bar.",
      "At the top, shift your body laterally toward one hand while extending the other arm.",
      "Slide back to center while staying above the bar.",
      "Shift to the opposite side, then lower to the starting position."
    ],
    "cues": [
      "Stay at the top throughout the lateral movement; do not drop down.",
      "Keep your chin above the bar the entire time.",
      "Use a wide grip to allow enough room for lateral travel."
    ],
    "commonMistakes": [
      "Dropping below the bar between side shifts.",
      "Not shifting far enough to create meaningful unilateral loading.",
      "Using a grip that is too narrow, limiting lateral range of motion."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Ziehe dich mit breitem Griff hoch, bis das Kinn über der Stange ist.",
          "Verschiebe am höchsten Punkt den Körper seitlich zu einer Hand, während du den anderen Arm streckst.",
          "Gleite zurück zur Mitte und bleibe dabei über der Stange.",
          "Verschiebe dich zur anderen Seite und senke dich dann in die Ausgangsposition."
        ],
        "cues": [
          "Bleibe während der seitlichen Bewegung oben; lass dich nicht absinken.",
          "Halte das Kinn die ganze Zeit über der Stange.",
          "Nutze einen breiten Griff, um genug Platz für die seitliche Bewegung zu haben."
        ],
        "commonMistakes": [
          "Zwischen den Seitenwechseln unter die Stange sinken.",
          "Sich nicht weit genug verschieben, um eine sinnvolle einseitige Belastung zu erzeugen.",
          "Einen zu engen Griff verwenden, der den seitlichen Bewegungsumfang einschränkt."
        ]
      }
    }
  },
  {
    "id": "pike_push_up",
    "name": "Pike Push Up",
    "name_de": "Pike-Liegestütze",
    "type": "bodyweight",
    "primaryMuscles": [
      "shoulders"
    ],
    "secondaryMuscles": [
      "triceps"
    ],
    "muscleGroups": [
      "shoulders",
      "triceps"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Start in a downward-dog position with hips piked high and hands shoulder-width apart.",
      "Bend your elbows and lower the top of your head toward the floor between your hands.",
      "Push back up to the starting position.",
      "Keep your hips high throughout the movement to target the shoulders."
    ],
    "cues": [
      "Look back toward your feet to keep a neutral neck.",
      "Walk your feet closer to your hands to increase difficulty.",
      "Keep your legs as straight as possible."
    ],
    "commonMistakes": [
      "Letting the hips drop, turning it into a regular push-up.",
      "Placing hands too far from the feet, reducing shoulder activation.",
      "Flaring the elbows out instead of keeping them at 45 degrees."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Starte in einer Position mit hoch angehobener Hüfte und schulterbreiten Händen.",
          "Beuge die Ellbogen und senke den Kopf zum Boden zwischen deinen Händen.",
          "Drücke dich zurück in die Ausgangsposition.",
          "Halte die Hüfte während der gesamten Bewegung hoch, um die Schultern zu beanspruchen."
        ],
        "cues": [
          "Schaue zurück zu deinen Füßen, um den Nacken neutral zu halten.",
          "Laufe mit den Füßen näher an die Hände, um den Schwierigkeitsgrad zu erhöhen.",
          "Halte die Beine so gerade wie möglich."
        ],
        "commonMistakes": [
          "Die Hüfte absinken lassen, wodurch es ein normaler Liegestütz wird.",
          "Die Hände zu weit von den Füßen platzieren, was die Schulteraktivierung verringert.",
          "Die Ellbogen abspreizen, statt sie bei 45 Grad zu halten."
        ]
      }
    }
  },
  {
    "id": "handstand_push_up",
    "name": "Handstand Push Up",
    "name_de": "Handstand-Liegestütze",
    "type": "bodyweight",
    "primaryMuscles": [
      "shoulders"
    ],
    "secondaryMuscles": [
      "triceps"
    ],
    "muscleGroups": [
      "shoulders",
      "triceps"
    ],
    "equipment": [
      "wall"
    ],
    "difficulty": 4,
    "source": "curated",
    "instructionsSteps": [
      "Kick up into a handstand against a wall with hands shoulder-width apart.",
      "Lower yourself by bending your elbows until the top of your head touches the floor.",
      "Press back up to full arm extension.",
      "Keep your core tight and body stacked vertically."
    ],
    "cues": [
      "Place your hands about 15 cm from the wall.",
      "Keep your elbows at a 45-degree angle, not flared out.",
      "Use an ab mat or pad under your head for safety."
    ],
    "commonMistakes": [
      "Flaring the elbows out to the sides, stressing the shoulder joint.",
      "Arching the lower back excessively instead of staying stacked.",
      "Not going to full depth due to fear or lack of strength."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Schwinge dich in den Handstand gegen eine Wand mit schulterbreiten Händen.",
          "Senke dich, indem du die Ellbogen beugst, bis der Kopf den Boden berührt.",
          "Drücke dich zurück in die volle Armstreckung.",
          "Halte den Rumpf angespannt und den Körper vertikal gestapelt."
        ],
        "cues": [
          "Platziere die Hände etwa 15 cm von der Wand entfernt.",
          "Halte die Ellbogen in einem 45-Grad-Winkel, nicht abgespreizt.",
          "Verwende eine Matte unter dem Kopf zur Sicherheit."
        ],
        "commonMistakes": [
          "Die Ellbogen zu den Seiten abspreizen, was das Schultergelenk belastet.",
          "Den unteren Rücken übermäßig überstrecken, statt gestapelt zu bleiben.",
          "Aus Angst oder Kraftmangel nicht die volle Tiefe erreichen."
        ]
      }
    }
  },
  {
    "id": "handstand_hold",
    "name": "Handstand Hold",
    "name_de": "Handstand-Halten",
    "type": "bodyweight",
    "primaryMuscles": [
      "shoulders"
    ],
    "secondaryMuscles": [
      "core"
    ],
    "muscleGroups": [
      "shoulders",
      "core"
    ],
    "equipment": [
      "wall"
    ],
    "difficulty": 3,
    "source": "curated",
    "instructionsSteps": [
      "Kick up into a handstand with your back or chest facing the wall.",
      "Stack your hips over your shoulders and your shoulders over your hands.",
      "Spread your fingers wide and press actively through your palms.",
      "Hold the position for the target duration while breathing steadily."
    ],
    "cues": [
      "Push the floor away to fully elevate the shoulder blades.",
      "Squeeze your glutes and point your toes to keep the body tight.",
      "Use your fingers to make small balance corrections."
    ],
    "commonMistakes": [
      "Over-arching the lower back instead of maintaining a hollow body.",
      "Placing hands too close or too far from the wall.",
      "Holding the breath instead of breathing steadily."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Schwinge dich in den Handstand mit dem Rücken oder der Brust zur Wand.",
          "Stapele die Hüfte über die Schultern und die Schultern über die Hände.",
          "Spreize die Finger weit und drücke aktiv durch die Handflächen.",
          "Halte die Position für die Zieldauer bei gleichmäßiger Atmung."
        ],
        "cues": [
          "Drücke den Boden weg, um die Schulterblätter vollständig anzuheben.",
          "Spanne die Gesäßmuskeln an und strecke die Zehen, um den Körper straff zu halten.",
          "Nutze die Finger für kleine Gleichgewichtskorrekturen."
        ],
        "commonMistakes": [
          "Den unteren Rücken überstrecken, statt eine Hollow-Body-Position zu halten.",
          "Die Hände zu nah oder zu weit von der Wand platzieren.",
          "Die Luft anhalten, statt gleichmäßig zu atmen."
        ]
      }
    }
  },
  {
    "id": "plank",
    "name": "Plank",
    "name_de": "Unterarmstütz",
    "type": "bodyweight",
    "primaryMuscles": [
      "core"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "core"
    ],
    "equipment": [
      "mat"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Place your forearms on the ground with elbows directly under your shoulders.",
      "Extend your legs behind you, balancing on your toes.",
      "Maintain a straight line from your head to your heels.",
      "Hold the position for the target duration while breathing normally."
    ],
    "cues": [
      "Actively push the floor away with your forearms to engage the serratus anterior.",
      "Squeeze your glutes and quads to keep the body rigid.",
      "Look at the floor between your hands to maintain a neutral neck."
    ],
    "commonMistakes": [
      "Letting the hips sag toward the floor, placing stress on the lower back.",
      "Piking the hips too high, reducing core engagement.",
      "Holding the breath instead of breathing steadily."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Lege die Unterarme auf den Boden mit den Ellbogen direkt unter den Schultern.",
          "Strecke die Beine nach hinten aus und balanciere auf den Zehenspitzen.",
          "Halte eine gerade Linie von Kopf bis Ferse.",
          "Halte die Position für die Zieldauer bei normaler Atmung."
        ],
        "cues": [
          "Drücke den Boden aktiv mit den Unterarmen weg, um den vorderen Sägemuskel zu aktivieren.",
          "Spanne Gesäß und Oberschenkel an, um den Körper steif zu halten.",
          "Schaue auf den Boden zwischen deinen Händen, um den Nacken neutral zu halten."
        ],
        "commonMistakes": [
          "Die Hüfte zum Boden durchhängen lassen, was den unteren Rücken belastet.",
          "Die Hüfte zu hoch anheben, was die Rumpfspannung verringert.",
          "Die Luft anhalten, statt gleichmäßig zu atmen."
        ]
      }
    }
  },
  {
    "id": "side_plank",
    "name": "Side Plank",
    "name_de": "Seitlicher Unterarmstütz",
    "type": "bodyweight",
    "primaryMuscles": [
      "core"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "core"
    ],
    "equipment": [
      "mat"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Lie on your side with your forearm on the ground, elbow directly under your shoulder.",
      "Stack your feet on top of each other or stagger them for stability.",
      "Lift your hips off the ground to form a straight line from head to feet.",
      "Hold the position for the target duration, then switch sides."
    ],
    "cues": [
      "Drive your bottom hip up toward the ceiling.",
      "Keep your top shoulder stacked directly over the bottom shoulder.",
      "Engage your obliques to prevent the hips from dropping."
    ],
    "commonMistakes": [
      "Letting the hips sag toward the ground over time.",
      "Rotating the torso forward or backward instead of staying perpendicular.",
      "Placing the elbow too far forward or behind the shoulder."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Lege dich auf die Seite mit dem Unterarm auf dem Boden, Ellbogen direkt unter der Schulter.",
          "Stapele die Füße übereinander oder versetzt sie für Stabilität.",
          "Hebe die Hüfte vom Boden, um eine gerade Linie von Kopf bis Fuß zu bilden.",
          "Halte die Position für die Zieldauer und wechsle dann die Seite."
        ],
        "cues": [
          "Drücke die untere Hüfte zur Decke hoch.",
          "Halte die obere Schulter direkt über der unteren Schulter gestapelt.",
          "Spanne die seitlichen Bauchmuskeln an, um ein Absinken der Hüfte zu verhindern."
        ],
        "commonMistakes": [
          "Die Hüfte im Laufe der Zeit zum Boden absinken lassen.",
          "Den Oberkörper nach vorne oder hinten rotieren, statt senkrecht zu bleiben.",
          "Den Ellbogen zu weit vor oder hinter der Schulter platzieren."
        ]
      }
    }
  },
  {
    "id": "hanging_leg_raise",
    "name": "Hanging Leg Raise",
    "name_de": "Hängendes Beinheben",
    "type": "bodyweight",
    "primaryMuscles": [
      "core"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "core"
    ],
    "equipment": [
      "pull-up-bar"
    ],
    "difficulty": 3,
    "source": "curated",
    "instructionsSteps": [
      "Hang from a pull-up bar with arms fully extended and shoulders engaged.",
      "Raise your legs with straight knees until they are parallel to the floor or higher.",
      "Lower your legs back down under control.",
      "Avoid swinging by keeping the movement slow and deliberate."
    ],
    "cues": [
      "Tilt your pelvis posteriorly to engage the lower abs.",
      "Keep your legs straight for maximum difficulty, or bend knees to scale down.",
      "Depress your shoulder blades to stabilize the hang."
    ],
    "commonMistakes": [
      "Using momentum and swinging to lift the legs.",
      "Bending the knees excessively when the goal is straight-leg raises.",
      "Not controlling the descent, letting gravity do the work."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Hänge an einer Klimmzugstange mit vollständig gestreckten Armen und aktivierten Schultern.",
          "Hebe die Beine mit gestreckten Knien an, bis sie parallel zum Boden oder höher sind.",
          "Senke die Beine kontrolliert zurück.",
          "Vermeide Schwingen, indem du die Bewegung langsam und bewusst ausführst."
        ],
        "cues": [
          "Kippe das Becken nach hinten, um die unteren Bauchmuskeln zu aktivieren.",
          "Halte die Beine für maximale Schwierigkeit gestreckt oder beuge die Knie zur Vereinfachung.",
          "Drücke die Schulterblätter nach unten, um den Aushang zu stabilisieren."
        ],
        "commonMistakes": [
          "Schwung und Schwingen nutzen, um die Beine anzuheben.",
          "Die Knie übermäßig beugen, wenn gestreckte Beine das Ziel sind.",
          "Das Absenken nicht kontrollieren und die Schwerkraft arbeiten lassen."
        ]
      }
    }
  },
  {
    "id": "l_sit",
    "name": "L-Sit",
    "type": "bodyweight",
    "primaryMuscles": [
      "core"
    ],
    "secondaryMuscles": [
      "quads"
    ],
    "muscleGroups": [
      "core",
      "quads"
    ],
    "equipment": [
      "parallettes"
    ],
    "difficulty": 3,
    "source": "curated",
    "instructionsSteps": [
      "Grip the parallettes and press yourself up with arms fully locked out.",
      "Lift your legs straight out in front of you until they are parallel to the ground.",
      "Hold this L-shaped position with pointed toes.",
      "Keep pressing the shoulders down away from your ears throughout."
    ],
    "cues": [
      "Actively push down through the parallettes to lift your hips.",
      "Engage your quads hard to keep the legs straight and elevated.",
      "Round your upper back slightly to help maintain the position."
    ],
    "commonMistakes": [
      "Bending the knees because of tight hamstrings or weak quads.",
      "Shrugging the shoulders instead of depressing them.",
      "Holding the breath during the isometric hold."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Greife die Parallettes und drücke dich mit vollständig gestreckten Armen hoch.",
          "Hebe die Beine gestreckt nach vorne an, bis sie parallel zum Boden sind.",
          "Halte diese L-förmige Position mit gestreckten Fußspitzen.",
          "Drücke die Schultern durchgehend nach unten weg von den Ohren."
        ],
        "cues": [
          "Drücke aktiv durch die Parallettes nach unten, um die Hüfte anzuheben.",
          "Spanne die Oberschenkel stark an, um die Beine gerade und angehoben zu halten.",
          "Runde den oberen Rücken leicht, um die Position besser halten zu können."
        ],
        "commonMistakes": [
          "Die Knie beugen aufgrund verkürzter hinteren Oberschenkelmuskulatur oder schwacher Oberschenkel.",
          "Die Schultern hochziehen, statt sie nach unten zu drücken.",
          "Während der isometrischen Halteposition die Luft anhalten."
        ]
      }
    }
  },
  {
    "id": "dragon_flag",
    "name": "Dragon Flag",
    "type": "bodyweight",
    "primaryMuscles": [
      "core"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "core"
    ],
    "equipment": [
      "bench"
    ],
    "difficulty": 4,
    "source": "curated",
    "instructionsSteps": [
      "Lie on a bench and grip the edges behind your head with both hands.",
      "Lift your entire body off the bench so only your upper back and shoulders remain in contact.",
      "Lower your body as a straight unit toward the bench under control.",
      "Raise back up before touching the bench and repeat."
    ],
    "cues": [
      "Keep your body perfectly straight from shoulders to toes.",
      "Lower as slowly as possible to maximize time under tension.",
      "Grip the bench hard to create a stable anchor point."
    ],
    "commonMistakes": [
      "Bending at the hips, turning it into a leg raise instead of a dragon flag.",
      "Lowering too fast without control.",
      "Not lifting the hips high enough at the top of the movement."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Lege dich auf eine Bank und greife die Kanten hinter deinem Kopf mit beiden Händen.",
          "Hebe den gesamten Körper von der Bank, sodass nur der obere Rücken und die Schultern Kontakt haben.",
          "Senke den Körper als gerade Einheit kontrolliert zur Bank.",
          "Hebe den Körper wieder an, bevor du die Bank berührst, und wiederhole."
        ],
        "cues": [
          "Halte den Körper von den Schultern bis zu den Zehen perfekt gerade.",
          "Senke so langsam wie möglich, um die Zeit unter Spannung zu maximieren.",
          "Greife die Bank fest, um einen stabilen Ankerpunkt zu schaffen."
        ],
        "commonMistakes": [
          "In der Hüfte abknicken, wodurch es ein Beinheben statt ein Dragon Flag wird.",
          "Zu schnell und ohne Kontrolle absenken.",
          "Die Hüfte am höchsten Punkt der Bewegung nicht hoch genug heben."
        ]
      }
    }
  },
  {
    "id": "ab_wheel_rollout",
    "name": "Ab Wheel Rollout",
    "name_de": "Bauchroller",
    "type": "bodyweight",
    "primaryMuscles": [
      "core"
    ],
    "secondaryMuscles": [
      "shoulders"
    ],
    "muscleGroups": [
      "core",
      "shoulders"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 3,
    "source": "curated",
    "instructionsSteps": [
      "Kneel on the floor and grip the ab wheel with both hands.",
      "Roll the wheel forward by extending your arms and hips simultaneously.",
      "Go as far as you can while keeping your lower back from arching.",
      "Pull the wheel back to the starting position by contracting your abs."
    ],
    "cues": [
      "Tuck your pelvis under and brace your core before rolling out.",
      "Think about pulling your elbows back toward your knees on the return.",
      "Keep a slight posterior pelvic tilt throughout the movement."
    ],
    "commonMistakes": [
      "Allowing the lower back to arch at the end range of the rollout.",
      "Bending at the hips on the way back instead of using the core.",
      "Going too far out before having the strength to maintain proper form."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Knie auf dem Boden und greife den Bauchroller mit beiden Händen.",
          "Rolle das Rad nach vorne, indem du Arme und Hüfte gleichzeitig streckst.",
          "Gehe so weit wie möglich, ohne den unteren Rücken ins Hohlkreuz fallen zu lassen.",
          "Ziehe das Rad zurück in die Ausgangsposition, indem du die Bauchmuskeln anspannst."
        ],
        "cues": [
          "Kippe das Becken nach hinten und spanne den Rumpf an, bevor du ausrollst.",
          "Stelle dir vor, die Ellbogen beim Zurückrollen zu den Knien zu ziehen.",
          "Halte während der gesamten Bewegung eine leichte hintere Beckenneigung."
        ],
        "commonMistakes": [
          "Den unteren Rücken am Ende des Ausrollens ins Hohlkreuz fallen lassen.",
          "Auf dem Rückweg in der Hüfte abknicken, statt den Rumpf zu nutzen.",
          "Zu weit ausrollen, bevor die Kraft für eine saubere Ausführung vorhanden ist."
        ]
      }
    }
  },
  {
    "id": "hollow_body_hold",
    "name": "Hollow Body Hold",
    "name_de": "Hollow-Body-Halten",
    "type": "bodyweight",
    "primaryMuscles": [
      "core"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "core"
    ],
    "equipment": [
      "mat"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Lie on your back and press your lower back firmly into the floor.",
      "Raise your legs slightly off the ground while keeping them straight.",
      "Extend your arms overhead and lift your shoulders off the floor.",
      "Hold this banana-shaped position for the target duration."
    ],
    "cues": [
      "Your lower back must stay glued to the floor at all times.",
      "Point your toes and squeeze your legs together.",
      "If you cannot maintain back contact, raise your legs higher to reduce difficulty."
    ],
    "commonMistakes": [
      "Letting the lower back lift off the floor, which strains the spine.",
      "Holding the legs too low before having the core strength to maintain position.",
      "Bending the knees or arms to compensate for weak core muscles."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Lege dich auf den Rücken und drücke den unteren Rücken fest in den Boden.",
          "Hebe die gestreckten Beine leicht vom Boden ab.",
          "Strecke die Arme über den Kopf und hebe die Schultern vom Boden.",
          "Halte diese bananenförmige Position für die Zieldauer."
        ],
        "cues": [
          "Der untere Rücken muss jederzeit am Boden bleiben.",
          "Strecke die Zehen und drücke die Beine zusammen.",
          "Wenn du den Bodenkontakt nicht halten kannst, hebe die Beine höher an."
        ],
        "commonMistakes": [
          "Den unteren Rücken vom Boden abheben lassen, was die Wirbelsäule belastet.",
          "Die Beine zu tief halten, bevor die Rumpfkraft für die Position ausreicht.",
          "Knie oder Arme beugen, um schwache Rumpfmuskeln zu kompensieren."
        ]
      }
    }
  },
  {
    "id": "bodyweight_squat",
    "name": "Bodyweight Squat",
    "name_de": "Kniebeuge",
    "type": "bodyweight",
    "primaryMuscles": [
      "quads"
    ],
    "secondaryMuscles": [
      "glutes"
    ],
    "muscleGroups": [
      "quads",
      "glutes"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Stand with feet shoulder-width apart and toes slightly turned out.",
      "Lower yourself by bending your knees and pushing your hips back as if sitting into a chair.",
      "Descend until your thighs are at least parallel to the floor.",
      "Drive through your heels to return to the standing position."
    ],
    "cues": [
      "Keep your chest up and your weight on your heels.",
      "Push your knees out over your toes; do not let them cave inward.",
      "Extend your arms forward for counterbalance if needed."
    ],
    "commonMistakes": [
      "Letting the knees cave inward during the descent or ascent.",
      "Rising onto the toes instead of driving through the heels.",
      "Not reaching parallel depth, cutting the range of motion short."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stehe schulterbreit mit leicht nach außen gedrehten Zehen.",
          "Senke dich, indem du die Knie beugst und die Hüfte nach hinten schiebst, als würdest du dich auf einen Stuhl setzen.",
          "Gehe herunter, bis die Oberschenkel mindestens parallel zum Boden sind.",
          "Drücke dich über die Fersen zurück in den Stand."
        ],
        "cues": [
          "Halte die Brust oben und das Gewicht auf den Fersen.",
          "Drücke die Knie über die Zehen nach außen; lass sie nicht nach innen fallen.",
          "Strecke die Arme nach vorne als Gegengewicht, falls nötig."
        ],
        "commonMistakes": [
          "Die Knie beim Absenken oder Aufstehen nach innen fallen lassen.",
          "Auf die Zehen gehen, statt über die Fersen zu drücken.",
          "Die parallele Tiefe nicht erreichen und den Bewegungsumfang verkürzen."
        ]
      }
    }
  },
  {
    "id": "lunges",
    "name": "Lunges",
    "name_de": "Ausfallschritte",
    "type": "bodyweight",
    "primaryMuscles": [
      "quads"
    ],
    "secondaryMuscles": [
      "glutes"
    ],
    "muscleGroups": [
      "quads",
      "glutes"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Stand upright with feet hip-width apart.",
      "Step forward with one leg and lower your hips until both knees are bent at about 90 degrees.",
      "Push through the front heel to return to the starting position.",
      "Alternate legs with each repetition."
    ],
    "cues": [
      "Keep your torso upright and your core braced throughout.",
      "The back knee should hover just above the floor at the bottom.",
      "Take a long enough step that your front knee stays behind your toes."
    ],
    "commonMistakes": [
      "Taking too short a step, causing the front knee to travel far past the toes.",
      "Leaning the torso forward excessively.",
      "Letting the back knee slam into the ground."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stehe aufrecht mit hüftbreiten Füßen.",
          "Mache einen Schritt nach vorne und senke die Hüfte, bis beide Knie etwa 90 Grad gebeugt sind.",
          "Drücke dich über die vordere Ferse zurück in die Ausgangsposition.",
          "Wechsle die Beine mit jeder Wiederholung."
        ],
        "cues": [
          "Halte den Oberkörper aufrecht und den Rumpf durchgehend angespannt.",
          "Das hintere Knie sollte am tiefsten Punkt knapp über dem Boden schweben.",
          "Mache einen ausreichend langen Schritt, damit das vordere Knie hinter den Zehen bleibt."
        ],
        "commonMistakes": [
          "Einen zu kurzen Schritt machen, sodass das vordere Knie weit über die Zehen hinausgeht.",
          "Den Oberkörper übermäßig nach vorne lehnen.",
          "Das hintere Knie auf den Boden knallen lassen."
        ]
      }
    }
  },
  {
    "id": "pistol_squat",
    "name": "Pistol Squat",
    "name_de": "Einbeinige Kniebeuge",
    "type": "bodyweight",
    "primaryMuscles": [
      "quads"
    ],
    "secondaryMuscles": [
      "glutes"
    ],
    "muscleGroups": [
      "quads",
      "glutes"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 4,
    "source": "curated",
    "instructionsSteps": [
      "Stand on one leg with the other leg extended straight in front of you.",
      "Lower yourself on the standing leg as deep as possible while keeping the other leg off the ground.",
      "Descend until your hamstring touches your calf.",
      "Drive through the heel of the standing leg to return to full extension."
    ],
    "cues": [
      "Extend your arms forward for counterbalance.",
      "Keep the standing foot flat on the ground throughout.",
      "Control the descent; do not drop into the bottom position."
    ],
    "commonMistakes": [
      "Falling backward at the bottom due to poor ankle mobility.",
      "Letting the knee cave inward on the working leg.",
      "Using the extended leg to push off the ground for assistance."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stehe auf einem Bein mit dem anderen Bein gerade nach vorne gestreckt.",
          "Senke dich auf dem Standbein so tief wie möglich, während das andere Bein in der Luft bleibt.",
          "Gehe herunter, bis der hintere Oberschenkel die Wade berührt.",
          "Drücke dich über die Ferse des Standbeins zurück in die volle Streckung."
        ],
        "cues": [
          "Strecke die Arme als Gegengewicht nach vorne.",
          "Halte den Fuß des Standbeins durchgehend flach auf dem Boden.",
          "Kontrolliere das Absenken; lass dich nicht in die tiefste Position fallen."
        ],
        "commonMistakes": [
          "Am tiefsten Punkt nach hinten fallen aufgrund schlechter Sprunggelenkbeweglichkeit.",
          "Das Knie des arbeitenden Beins nach innen fallen lassen.",
          "Das gestreckte Bein nutzen, um sich vom Boden abzudrücken."
        ]
      }
    }
  },
  {
    "id": "jump_squat",
    "name": "Jump Squat",
    "name_de": "Sprung-Kniebeuge",
    "type": "bodyweight",
    "primaryMuscles": [
      "quads"
    ],
    "secondaryMuscles": [
      "glutes",
      "calves"
    ],
    "muscleGroups": [
      "quads",
      "glutes",
      "calves"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Stand with feet shoulder-width apart.",
      "Lower into a squat until your thighs are parallel to the floor.",
      "Explode upward and jump as high as possible.",
      "Land softly by bending your knees and immediately transition into the next rep."
    ],
    "cues": [
      "Swing your arms to generate additional power.",
      "Land on the balls of your feet and roll to the heels.",
      "Absorb the landing through your hips and knees, not your lower back."
    ],
    "commonMistakes": [
      "Landing with stiff legs, which is hard on the joints.",
      "Not squatting deep enough before the jump.",
      "Leaning too far forward during the jump."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stehe schulterbreit.",
          "Gehe in die Kniebeuge, bis die Oberschenkel parallel zum Boden sind.",
          "Springe explosiv so hoch wie möglich nach oben.",
          "Lande weich mit gebeugten Knien und gehe direkt in die nächste Wiederholung."
        ],
        "cues": [
          "Schwinge die Arme mit, um zusätzliche Kraft zu erzeugen.",
          "Lande auf den Fußballen und rolle zur Ferse ab.",
          "Fange die Landung über Hüfte und Knie ab, nicht über den unteren Rücken."
        ],
        "commonMistakes": [
          "Mit steifen Beinen landen, was die Gelenke belastet.",
          "Vor dem Sprung nicht tief genug in die Kniebeuge gehen.",
          "Beim Sprung zu weit nach vorne lehnen."
        ]
      }
    }
  },
  {
    "id": "nordic_curl",
    "name": "Nordic Curl",
    "name_de": "Nordischer Beinbeuger",
    "type": "bodyweight",
    "primaryMuscles": [
      "hamstrings"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "hamstrings"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 4,
    "source": "curated",
    "instructionsSteps": [
      "Kneel on the floor with your feet anchored behind you by a partner or fixed object.",
      "Keeping your body straight from knees to head, slowly lower yourself toward the floor.",
      "Resist the fall using your hamstrings for as long as possible.",
      "Catch yourself with your hands and push back up to repeat."
    ],
    "cues": [
      "Keep your hips extended; do not bend at the waist.",
      "Lower as slowly as you can to maximize eccentric loading.",
      "Use your hands to assist the push-up portion if you cannot pull yourself back up."
    ],
    "commonMistakes": [
      "Bending at the hips instead of keeping the body straight.",
      "Falling forward uncontrolled instead of lowering with resistance.",
      "Not anchoring the feet securely enough."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Knie auf dem Boden mit den Füßen hinter dir fixiert durch einen Partner oder ein festes Objekt.",
          "Senke dich mit geradem Körper von Knien bis Kopf langsam zum Boden.",
          "Widerstehe dem Fall so lange wie möglich mit deiner hinteren Oberschenkelmuskulatur.",
          "Fange dich mit den Händen auf und drücke dich hoch, um zu wiederholen."
        ],
        "cues": [
          "Halte die Hüfte gestreckt; knicke nicht in der Taille ab.",
          "Senke dich so langsam wie möglich, um die exzentrische Belastung zu maximieren.",
          "Nutze die Hände zur Unterstützung beim Hochdrücken, falls du dich nicht alleine hochziehen kannst."
        ],
        "commonMistakes": [
          "In der Hüfte abknicken, statt den Körper gerade zu halten.",
          "Unkontrolliert nach vorne fallen, statt sich mit Widerstand abzusenken.",
          "Die Füße nicht sicher genug fixieren."
        ]
      }
    }
  },
  {
    "id": "glute_bridge",
    "name": "Glute Bridge",
    "name_de": "Beckenheben",
    "type": "bodyweight",
    "primaryMuscles": [
      "glutes"
    ],
    "secondaryMuscles": [
      "hamstrings"
    ],
    "muscleGroups": [
      "glutes",
      "hamstrings"
    ],
    "equipment": [
      "mat"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Lie on your back with knees bent and feet flat on the floor hip-width apart.",
      "Drive through your heels to lift your hips until your body forms a straight line from shoulders to knees.",
      "Squeeze your glutes hard at the top of the movement.",
      "Lower your hips back to the floor under control."
    ],
    "cues": [
      "Push through the heels, not the toes.",
      "Avoid hyperextending the lower back at the top; stop at a straight line.",
      "Keep your core braced to protect the spine."
    ],
    "commonMistakes": [
      "Pushing through the toes instead of the heels, reducing glute activation.",
      "Over-arching the lower back at the top of the movement.",
      "Placing feet too far from or too close to the glutes."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Lege dich auf den Rücken mit gebeugten Knien und hüftbreit aufgestellten Füßen.",
          "Drücke über die Fersen die Hüfte hoch, bis der Körper eine gerade Linie von Schultern zu Knien bildet.",
          "Spanne die Gesäßmuskeln am höchsten Punkt kräftig an.",
          "Senke die Hüfte kontrolliert zurück zum Boden."
        ],
        "cues": [
          "Drücke über die Fersen, nicht über die Zehen.",
          "Vermeide ein Überstrecken des unteren Rückens oben; stoppe bei einer geraden Linie.",
          "Halte den Rumpf angespannt, um die Wirbelsäule zu schützen."
        ],
        "commonMistakes": [
          "Über die Zehen statt die Fersen drücken, was die Gesäßaktivierung verringert.",
          "Den unteren Rücken am höchsten Punkt der Bewegung überstrecken.",
          "Die Füße zu weit vom oder zu nah am Gesäß platzieren."
        ]
      }
    }
  },
  {
    "id": "calf_raise",
    "name": "Calf Raise",
    "name_de": "Wadenheben",
    "type": "bodyweight",
    "primaryMuscles": [
      "calves"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "calves"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Stand with feet hip-width apart on flat ground or with the balls of your feet on a raised edge.",
      "Rise up onto your toes as high as possible.",
      "Hold the top position briefly and squeeze your calves.",
      "Lower back down under control, going below the starting height if using a raised edge."
    ],
    "cues": [
      "Go through the full range of motion: full stretch at the bottom, full contraction at the top.",
      "Keep your knees straight but not locked.",
      "Perform the movement slowly and avoid bouncing."
    ],
    "commonMistakes": [
      "Bouncing through the reps instead of using controlled movement.",
      "Not reaching full extension at the top.",
      "Leaning forward and shifting weight off the calves."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stehe hüftbreit auf ebenem Boden oder mit den Fußballen auf einer erhöhten Kante.",
          "Hebe dich so hoch wie möglich auf die Zehenspitzen.",
          "Halte die obere Position kurz und spanne die Waden an.",
          "Senke dich kontrolliert ab, bei einer erhöhten Kante unter die Ausgangshöhe."
        ],
        "cues": [
          "Nutze den vollen Bewegungsumfang: volle Dehnung unten, volle Kontraktion oben.",
          "Halte die Knie gestreckt, aber nicht durchgedrückt.",
          "Führe die Bewegung langsam aus und vermeide Federn."
        ],
        "commonMistakes": [
          "Durch die Wiederholungen federn, statt kontrolliert zu arbeiten.",
          "Die volle Streckung am höchsten Punkt nicht erreichen.",
          "Nach vorne lehnen und das Gewicht von den Waden nehmen."
        ]
      }
    }
  },
  {
    "id": "front_lever",
    "name": "Front Lever",
    "type": "bodyweight",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "core"
    ],
    "muscleGroups": [
      "back",
      "core"
    ],
    "equipment": [
      "pull-up-bar"
    ],
    "difficulty": 5,
    "source": "curated",
    "instructionsSteps": [
      "Hang from a pull-up bar with an overhand grip at shoulder-width.",
      "Engage your lats and core to raise your body until it is horizontal and parallel to the ground.",
      "Hold this position with arms fully extended and body straight.",
      "Keep your shoulder blades depressed and retracted throughout."
    ],
    "cues": [
      "Think about pushing the bar toward your hips while keeping arms straight.",
      "Squeeze your entire posterior chain: lats, glutes, and hamstrings.",
      "Progress through tuck, advanced tuck, straddle, and full variations."
    ],
    "commonMistakes": [
      "Letting the hips sag below the horizontal line.",
      "Bending the arms instead of maintaining straight-arm strength.",
      "Skipping progressions and attempting the full lever too early."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Hänge mit schulterbreitem Obergriff an einer Klimmzugstange.",
          "Spanne Latissimus und Rumpf an, um den Körper horizontal und parallel zum Boden anzuheben.",
          "Halte diese Position mit vollständig gestreckten Armen und geradem Körper.",
          "Halte die Schulterblätter durchgehend nach unten und zusammengezogen."
        ],
        "cues": [
          "Stelle dir vor, die Stange zu den Hüften zu drücken, während die Arme gestreckt bleiben.",
          "Spanne die gesamte hintere Kette an: Latissimus, Gesäß und hintere Oberschenkel.",
          "Arbeite dich durch Tuck, Advanced Tuck, Grätsche und volle Variante vor."
        ],
        "commonMistakes": [
          "Die Hüfte unter die horizontale Linie absacken lassen.",
          "Die Arme beugen, statt gerade Armkraft aufrechtzuerhalten.",
          "Vorstufen überspringen und den vollen Lever zu früh versuchen."
        ]
      }
    }
  },
  {
    "id": "back_lever",
    "name": "Back Lever",
    "type": "bodyweight",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "shoulders",
      "core",
      "biceps"
    ],
    "muscleGroups": [
      "back",
      "shoulders",
      "core",
      "biceps"
    ],
    "equipment": [
      "rings"
    ],
    "difficulty": 4,
    "source": "curated",
    "instructionsSteps": [
      "Hang from the rings and perform a skin-the-cat motion to rotate backward.",
      "Lower your body until it is horizontal behind you, face down.",
      "Hold this position with arms straight and body in a straight line.",
      "Return to the starting position by reversing the rotation."
    ],
    "cues": [
      "Keep your arms fully locked out throughout the hold.",
      "Engage your core and glutes to maintain a straight body line.",
      "Start with tuck and straddle progressions before attempting full back lever."
    ],
    "commonMistakes": [
      "Bending the arms, which makes the position feel easier but reduces training effect.",
      "Arching the lower back excessively.",
      "Attempting the full position without adequate shoulder conditioning."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Hänge an den Ringen und führe eine Skin-the-Cat-Bewegung nach hinten aus.",
          "Senke den Körper, bis er horizontal hinter dir liegt, mit dem Gesicht nach unten.",
          "Halte diese Position mit gestreckten Armen und geradem Körper.",
          "Kehre in die Ausgangsposition zurück, indem du die Rotation umkehrst."
        ],
        "cues": [
          "Halte die Arme während der gesamten Halteposition vollständig durchgestreckt.",
          "Spanne Rumpf und Gesäß an, um eine gerade Körperlinie zu halten.",
          "Beginne mit Tuck- und Grätsche-Vorstufen, bevor du den vollen Back Lever versuchst."
        ],
        "commonMistakes": [
          "Die Arme beugen, was die Position einfacher macht, aber den Trainingseffekt verringert.",
          "Den unteren Rücken übermäßig überstrecken.",
          "Die volle Position ohne ausreichende Schulterkonditionierung versuchen."
        ]
      }
    }
  },
  {
    "id": "planche",
    "name": "Planche",
    "type": "bodyweight",
    "primaryMuscles": [
      "shoulders"
    ],
    "secondaryMuscles": [
      "chest",
      "core"
    ],
    "muscleGroups": [
      "shoulders",
      "chest",
      "core"
    ],
    "equipment": [
      "parallettes"
    ],
    "difficulty": 5,
    "source": "curated",
    "instructionsSteps": [
      "Grip the parallettes and lean forward until your shoulders are well past your hands.",
      "Lift your feet off the ground by engaging your shoulders, chest, and core.",
      "Hold your body horizontal with arms fully locked out.",
      "Keep your body in a straight line from head to toes."
    ],
    "cues": [
      "Protract your shoulder blades maximally to round the upper back.",
      "Lean forward as far as possible; the lean is what makes the hold possible.",
      "Progress through tuck, advanced tuck, straddle, and full planche."
    ],
    "commonMistakes": [
      "Not leaning forward enough, making it impossible to hold the position.",
      "Bending the arms instead of maintaining a locked-out straight arm.",
      "Piking at the hips instead of holding a flat body position."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Greife die Parallettes und lehne dich nach vorne, bis die Schultern deutlich vor den Händen sind.",
          "Hebe die Füße vom Boden, indem du Schultern, Brust und Rumpf anspannst.",
          "Halte den Körper horizontal mit vollständig gestreckten Armen.",
          "Halte den Körper in einer geraden Linie von Kopf bis Fuß."
        ],
        "cues": [
          "Protrahiere die Schulterblätter maximal, um den oberen Rücken zu runden.",
          "Lehne dich so weit wie möglich nach vorne; die Vorneigung macht die Halteposition möglich.",
          "Arbeite dich durch Tuck, Advanced Tuck, Grätsche und volle Planche vor."
        ],
        "commonMistakes": [
          "Sich nicht weit genug nach vorne lehnen, was die Position unmöglich macht.",
          "Die Arme beugen, statt gestreckte Arme beizubehalten.",
          "In der Hüfte abknicken, statt eine flache Körperposition zu halten."
        ]
      }
    }
  },
  {
    "id": "skin_the_cat",
    "name": "Skin The Cat",
    "type": "bodyweight",
    "primaryMuscles": [
      "shoulders"
    ],
    "secondaryMuscles": [
      "back",
      "core"
    ],
    "muscleGroups": [
      "shoulders",
      "back",
      "core"
    ],
    "equipment": [
      "rings"
    ],
    "difficulty": 3,
    "source": "curated",
    "instructionsSteps": [
      "Hang from the rings with a shoulder-width grip.",
      "Tuck your knees and rotate backward through your arms until your body passes underneath.",
      "Extend into a German hang with arms behind you and shoulders stretched.",
      "Reverse the movement to return to the starting hang position."
    ],
    "cues": [
      "Move slowly and with control, especially when entering the German hang.",
      "Keep the rings close together throughout the rotation.",
      "Only go as deep into the German hang as your shoulders comfortably allow."
    ],
    "commonMistakes": [
      "Swinging through the movement instead of controlling the rotation.",
      "Going too deep into the German hang without adequate shoulder flexibility.",
      "Releasing the grip when the stretch becomes intense."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Hänge mit schulterbreitem Griff an den Ringen.",
          "Ziehe die Knie an und rotiere rückwärts durch die Arme, bis der Körper darunter durchgeht.",
          "Strecke dich in den German Hang mit Armen hinter dir und gedehnten Schultern.",
          "Kehre die Bewegung um, um in den Ausgangshang zurückzukehren."
        ],
        "cues": [
          "Bewege dich langsam und kontrolliert, besonders beim Eintritt in den German Hang.",
          "Halte die Ringe während der gesamten Rotation nah beieinander.",
          "Gehe nur so tief in den German Hang, wie es die Schultern bequem zulassen."
        ],
        "commonMistakes": [
          "Durch die Bewegung schwingen, statt die Rotation zu kontrollieren.",
          "Ohne ausreichende Schulterbeweglichkeit zu tief in den German Hang gehen.",
          "Den Griff lösen, wenn die Dehnung intensiv wird."
        ]
      }
    }
  },
  {
    "id": "ring_row",
    "name": "Ring Row",
    "name_de": "Ringrudern",
    "type": "bodyweight",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "biceps"
    ],
    "muscleGroups": [
      "back",
      "biceps"
    ],
    "equipment": [
      "rings"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Set the rings at about waist height and hang underneath with arms extended.",
      "Keep your body in a straight line from head to heels with feet on the ground.",
      "Pull your chest to the rings by squeezing your shoulder blades together.",
      "Lower yourself back to full arm extension under control."
    ],
    "cues": [
      "Turn the rings out at the top of each rep for extra back activation.",
      "Keep your hips up and body rigid throughout the pull.",
      "Walk your feet further forward to increase difficulty."
    ],
    "commonMistakes": [
      "Letting the hips sag, breaking the straight body line.",
      "Not pulling the rings all the way to the chest.",
      "Shrugging the shoulders instead of pulling with the back."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stelle die Ringe auf etwa Hüfthöhe ein und hänge dich mit gestreckten Armen darunter.",
          "Halte den Körper in einer geraden Linie von Kopf bis Ferse mit den Füßen auf dem Boden.",
          "Ziehe die Brust zu den Ringen, indem du die Schulterblätter zusammenziehst.",
          "Senke dich kontrolliert zurück in die volle Armstreckung."
        ],
        "cues": [
          "Drehe die Ringe am höchsten Punkt jeder Wiederholung nach außen für mehr Rückenaktivierung.",
          "Halte die Hüfte oben und den Körper steif während des Zuges.",
          "Laufe mit den Füßen weiter nach vorne, um den Schwierigkeitsgrad zu erhöhen."
        ],
        "commonMistakes": [
          "Die Hüfte durchhängen lassen und die gerade Körperlinie brechen.",
          "Die Ringe nicht bis zur Brust ziehen.",
          "Die Schultern hochziehen, statt mit dem Rücken zu ziehen."
        ]
      }
    }
  },
  {
    "id": "burpee",
    "name": "Burpee",
    "type": "bodyweight",
    "primaryMuscles": [
      "quads"
    ],
    "secondaryMuscles": [
      "chest",
      "glutes",
      "core",
      "shoulders"
    ],
    "muscleGroups": [
      "quads",
      "chest",
      "glutes",
      "core",
      "shoulders"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Stand upright, then squat down and place your hands on the floor.",
      "Jump or step your feet back into a plank position.",
      "Perform a push-up, then jump or step your feet back to your hands.",
      "Explode upward into a jump with arms overhead."
    ],
    "cues": [
      "Move fluidly between each phase without pausing.",
      "Land softly from the jump to protect your joints.",
      "Keep your core engaged when transitioning to and from the plank."
    ],
    "commonMistakes": [
      "Skipping the push-up or not going to full depth.",
      "Landing with stiff legs after the jump.",
      "Letting the hips sag in the plank phase."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stehe aufrecht, gehe dann in die Hocke und platziere die Hände auf dem Boden.",
          "Springe oder steige mit den Füßen zurück in eine Plank-Position.",
          "Führe einen Liegestütz aus und springe oder steige dann mit den Füßen zurück zu den Händen.",
          "Springe explosiv nach oben mit den Armen über dem Kopf."
        ],
        "cues": [
          "Bewege dich fließend zwischen jeder Phase ohne Pause.",
          "Lande weich nach dem Sprung, um die Gelenke zu schonen.",
          "Halte den Rumpf angespannt beim Wechsel in und aus der Plank-Position."
        ],
        "commonMistakes": [
          "Den Liegestütz auslassen oder nicht in voller Tiefe ausführen.",
          "Nach dem Sprung mit steifen Beinen landen.",
          "Die Hüfte in der Plank-Phase durchhängen lassen."
        ]
      }
    }
  },
  {
    "id": "mountain_climber",
    "name": "Mountain Climber",
    "name_de": "Bergsteiger",
    "type": "bodyweight",
    "primaryMuscles": [
      "core"
    ],
    "secondaryMuscles": [
      "shoulders"
    ],
    "muscleGroups": [
      "core",
      "shoulders"
    ],
    "equipment": [
      "bodyweight"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Start in a high plank position with hands directly under your shoulders.",
      "Drive one knee toward your chest while keeping the other leg extended.",
      "Quickly switch legs, bringing the other knee forward.",
      "Continue alternating in a running motion while maintaining the plank position."
    ],
    "cues": [
      "Keep your hips level and avoid bouncing them up and down.",
      "Drive each knee as close to your chest as possible.",
      "Maintain a strong plank; do not let your lower back sag."
    ],
    "commonMistakes": [
      "Piking the hips up instead of maintaining a flat plank.",
      "Not bringing the knees far enough forward to engage the core.",
      "Bouncing the hips with each leg switch."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Starte in einer hohen Plank-Position mit Händen direkt unter den Schultern.",
          "Ziehe ein Knie zur Brust, während das andere Bein gestreckt bleibt.",
          "Wechsle schnell die Beine und bringe das andere Knie nach vorne.",
          "Wechsle weiter in einer Laufbewegung, während du die Plank-Position hältst."
        ],
        "cues": [
          "Halte die Hüfte waagerecht und vermeide ein Auf- und Abwippen.",
          "Ziehe jedes Knie so nah wie möglich an die Brust.",
          "Halte einen stabilen Plank; lass den unteren Rücken nicht durchhängen."
        ],
        "commonMistakes": [
          "Die Hüfte nach oben drücken, statt einen flachen Plank zu halten.",
          "Die Knie nicht weit genug nach vorne bringen, um den Rumpf zu aktivieren.",
          "Die Hüfte bei jedem Beinwechsel wippen lassen."
        ]
      }
    }
  },
  {
    "id": "box_jump",
    "name": "Box Jump",
    "name_de": "Box Jumps",
    "type": "bodyweight",
    "primaryMuscles": [
      "quads"
    ],
    "secondaryMuscles": [
      "glutes",
      "calves"
    ],
    "muscleGroups": [
      "quads",
      "glutes",
      "calves"
    ],
    "equipment": [
      "box"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Stand facing a sturdy box at an appropriate height with feet shoulder-width apart.",
      "Swing your arms back and bend your knees to load the jump.",
      "Explode upward and forward, landing on the box with both feet simultaneously.",
      "Stand to full extension on top of the box, then step back down."
    ],
    "cues": [
      "Land softly on the box with your whole foot, not just the toes.",
      "Use your arms aggressively to generate upward momentum.",
      "Step down rather than jumping down to reduce joint impact."
    ],
    "commonMistakes": [
      "Landing on the edge of the box, risking a fall.",
      "Jumping down from the box, which increases impact on the joints.",
      "Using a box that is too high, compromising landing mechanics."
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stehe vor einer stabilen Box in angemessener Höhe mit schulterbreiten Füßen.",
          "Schwinge die Arme zurück und beuge die Knie, um den Sprung vorzubereiten.",
          "Springe explosiv nach oben und vorne und lande mit beiden Füßen gleichzeitig auf der Box.",
          "Stehe oben auf der Box in volle Streckung und steige dann zurück herunter."
        ],
        "cues": [
          "Lande weich auf der Box mit dem ganzen Fuß, nicht nur den Zehen.",
          "Nutze die Arme aktiv, um Aufwärtsschwung zu erzeugen.",
          "Steige herunter, statt zu springen, um die Gelenkbelastung zu reduzieren."
        ],
        "commonMistakes": [
          "Auf der Kante der Box landen und einen Sturz riskieren.",
          "Von der Box herunterspringen, was die Gelenkbelastung erhöht.",
          "Eine zu hohe Box verwenden, was die Landemechanik beeinträchtigt."
        ]
      }
    }
  },
  {
    "id": "bench_press",
    "name": "Bench Press",
    "name_de": "Bankdrücken",
    "type": "strength",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [
      "triceps",
      "shoulders"
    ],
    "muscleGroups": [
      "chest",
      "triceps",
      "shoulders"
    ],
    "equipment": [
      "barbell",
      "bench"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Lie on a flat bench, grip barbell slightly wider than shoulder-width",
      "Unrack the bar and hold it over your chest with arms extended",
      "Lower the bar to mid-chest with control",
      "Press the bar back up to full arm extension"
    ],
    "cues": [
      "Retract shoulder blades",
      "Feet flat on the floor"
    ],
    "commonMistakes": [
      "Bouncing bar off chest",
      "Flaring elbows too wide"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Auf der Flachbank liegen, Langhantel etwas weiter als schulterbreit greifen",
          "Stange aus der Ablage nehmen, über der Brust mit gestreckten Armen halten",
          "Stange kontrolliert zur Brustmitte senken",
          "Stange zurück in volle Armstreckung drücken"
        ],
        "cues": [
          "Schulterblätter zusammenziehen",
          "Füße flach auf dem Boden"
        ],
        "commonMistakes": [
          "Stange von der Brust abprallen lassen",
          "Ellbogen zu weit außen"
        ]
      }
    }
  },
  {
    "id": "incline_bench_press",
    "name": "Incline Bench Press",
    "name_de": "Schrägbankdrücken",
    "type": "strength",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [
      "shoulders"
    ],
    "muscleGroups": [
      "chest",
      "shoulders"
    ],
    "equipment": [
      "barbell",
      "bench"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Set bench to 30-45 degree incline",
      "Grip barbell slightly wider than shoulder-width and unrack",
      "Lower bar to upper chest with control",
      "Press back up to full extension"
    ],
    "cues": [
      "Keep upper back pressed into bench",
      "Bar path slightly angled"
    ],
    "commonMistakes": [
      "Incline too steep",
      "Flaring elbows"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Bank auf 30-45 Grad Schräge einstellen",
          "Langhantel etwas weiter als schulterbreit greifen und abheben",
          "Stange kontrolliert zur oberen Brust senken",
          "Zurück in volle Streckung drücken"
        ],
        "cues": [
          "Oberen Rücken in die Bank drücken",
          "Stangenbahn leicht schräg"
        ],
        "commonMistakes": [
          "Schräge zu steil",
          "Ellbogen zu weit außen"
        ]
      }
    }
  },
  {
    "id": "dumbbell_bench_press",
    "name": "Dumbbell Bench Press",
    "name_de": "Kurzhantel-Bankdrücken",
    "type": "strength",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [
      "triceps"
    ],
    "muscleGroups": [
      "chest",
      "triceps"
    ],
    "equipment": [
      "dumbbell",
      "bench"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Lie on a flat bench holding a dumbbell in each hand at chest level",
      "Press dumbbells upward until arms are fully extended",
      "Lower dumbbells back to chest level with control",
      "Keep a slight arch in the lower back"
    ],
    "cues": [
      "Squeeze chest at the top",
      "Lower to a deep stretch"
    ],
    "commonMistakes": [
      "Dumbbells drifting too far apart",
      "Not controlling the descent"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Auf der Flachbank liegen, eine Kurzhantel in jeder Hand auf Brusthöhe",
          "Kurzhanteln nach oben drücken bis Arme voll gestreckt",
          "Kurzhanteln kontrolliert zurück auf Brusthöhe senken",
          "Leichtes Hohlkreuz im unteren Rücken beibehalten"
        ],
        "cues": [
          "Brust oben zusammendrücken",
          "Tief in die Dehnung senken"
        ],
        "commonMistakes": [
          "Hanteln driften zu weit auseinander",
          "Abstieg nicht kontrolliert"
        ]
      }
    }
  },
  {
    "id": "incline_dumbbell_press",
    "name": "Incline Dumbbell Press",
    "name_de": "Schrägbank-Kurzhanteldrücken",
    "type": "strength",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [
      "shoulders"
    ],
    "muscleGroups": [
      "chest",
      "shoulders"
    ],
    "equipment": [
      "dumbbell",
      "bench"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Set bench to 30-45 degrees, sit back with a dumbbell in each hand",
      "Press dumbbells up over upper chest until arms are extended",
      "Lower with control until dumbbells are at chest level",
      "Press back up squeezing chest and shoulders"
    ],
    "cues": [
      "Keep wrists over elbows",
      "Control the negative"
    ],
    "commonMistakes": [
      "Bench angle too steep",
      "Arching excessively"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Bank auf 30-45 Grad, zurücklehnen mit je einer Kurzhantel",
          "Hanteln über der oberen Brust hochdrücken bis Arme gestreckt",
          "Kontrolliert senken bis Hanteln auf Brusthöhe",
          "Hochdrücken, Brust und Schultern anspannen"
        ],
        "cues": [
          "Handgelenke über Ellbogen",
          "Negative Phase kontrollieren"
        ],
        "commonMistakes": [
          "Bank zu steil",
          "Zu starkes Hohlkreuz"
        ]
      }
    }
  },
  {
    "id": "dumbbell_fly",
    "name": "Dumbbell Fly",
    "name_de": "Kurzhantel-Fliegende",
    "type": "strength",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "chest"
    ],
    "equipment": [
      "dumbbell",
      "bench"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Lie on a flat bench holding dumbbells above chest with slight elbow bend",
      "Open arms wide, lowering dumbbells to the sides in an arc",
      "Feel a stretch in the chest at the bottom",
      "Squeeze chest to bring dumbbells back together above"
    ],
    "cues": [
      "Maintain slight elbow bend throughout",
      "Think hugging a tree"
    ],
    "commonMistakes": [
      "Straightening arms completely",
      "Going too heavy"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Auf der Flachbank liegen, Hanteln über der Brust mit leichter Ellbogenbeugung",
          "Arme weit öffnen, Hanteln seitlich in einem Bogen senken",
          "Dehnung in der Brust am tiefsten Punkt spüren",
          "Brust anspannen, Hanteln wieder zusammenführen"
        ],
        "cues": [
          "Leichte Ellbogenbeugung beibehalten",
          "Wie einen Baum umarmen"
        ],
        "commonMistakes": [
          "Arme komplett strecken",
          "Zu schweres Gewicht"
        ]
      }
    }
  },
  {
    "id": "cable_crossover",
    "name": "Cable Crossover",
    "name_de": "Kabelzug-Crossover",
    "type": "strength",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "chest"
    ],
    "equipment": [
      "machine"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Stand between cable towers with pulleys set high",
      "Grip handles and step forward into a slight lunge",
      "Bring hands together in front of chest in a hugging motion",
      "Slowly return arms to the stretched position"
    ],
    "cues": [
      "Keep slight bend in elbows",
      "Squeeze chest at the bottom"
    ],
    "commonMistakes": [
      "Using too much shoulder",
      "Leaning too far forward"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Zwischen den Kabeltürmen stehen, Rollen oben eingestellt",
          "Griffe fassen und in leichten Ausfallschritt nach vorne treten",
          "Hände vor der Brust zusammenführen in Umarm-Bewegung",
          "Arme langsam zurück in die gedehnte Position"
        ],
        "cues": [
          "Leichte Ellbogenbeugung",
          "Brust unten zusammendrücken"
        ],
        "commonMistakes": [
          "Zu viel Schulter",
          "Zu weit nach vorne lehnen"
        ]
      }
    }
  },
  {
    "id": "barbell_row",
    "name": "Barbell Row",
    "name_de": "Langhantelrudern",
    "type": "strength",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "biceps"
    ],
    "muscleGroups": [
      "back",
      "biceps"
    ],
    "equipment": [
      "barbell"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Stand with feet shoulder-width, hinge at hips holding barbell",
      "Keep back flat at roughly 45 degrees to the floor",
      "Pull bar toward lower chest or upper abdomen",
      "Lower bar with control back to arm extension"
    ],
    "cues": [
      "Drive elbows behind you",
      "Squeeze shoulder blades at top"
    ],
    "commonMistakes": [
      "Rounding the back",
      "Using momentum to swing bar up"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Schulterbreit stehen, in der Hüfte beugen, Langhantel halten",
          "Rücken gerade ca. 45 Grad zum Boden",
          "Stange zur unteren Brust oder oberen Bauch ziehen",
          "Stange kontrolliert zurück in Armstreckung senken"
        ],
        "cues": [
          "Ellbogen nach hinten ziehen",
          "Schulterblätter oben zusammendrücken"
        ],
        "commonMistakes": [
          "Rücken runden",
          "Schwung zum Hochziehen nutzen"
        ]
      }
    }
  },
  {
    "id": "dumbbell_row",
    "name": "Dumbbell Row",
    "name_de": "Kurzhantelrudern",
    "type": "strength",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "biceps"
    ],
    "muscleGroups": [
      "back",
      "biceps"
    ],
    "equipment": [
      "dumbbell",
      "bench"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Place one knee and hand on a bench for support",
      "Hold a dumbbell in the free hand with arm extended",
      "Pull dumbbell toward hip by driving elbow upward",
      "Lower with control and repeat"
    ],
    "cues": [
      "Keep back flat and parallel to floor",
      "Pull to hip, not to chest"
    ],
    "commonMistakes": [
      "Rotating torso",
      "Rounding upper back"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Ein Knie und eine Hand zur Stütze auf die Bank",
          "Kurzhantel in der freien Hand mit gestrecktem Arm halten",
          "Hantel zur Hüfte ziehen, Ellbogen nach oben",
          "Kontrolliert ablassen und wiederholen"
        ],
        "cues": [
          "Rücken flach und parallel zum Boden",
          "Zur Hüfte ziehen, nicht zur Brust"
        ],
        "commonMistakes": [
          "Oberkörper dreht sich",
          "Oberen Rücken runden"
        ]
      }
    }
  },
  {
    "id": "lat_pulldown",
    "name": "Lat Pulldown",
    "name_de": "Latzug",
    "type": "strength",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "biceps"
    ],
    "muscleGroups": [
      "back",
      "biceps"
    ],
    "equipment": [
      "machine"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Sit at the lat pulldown machine and grip bar wider than shoulder-width",
      "Lean back slightly and pull bar down to upper chest",
      "Squeeze shoulder blades together at the bottom",
      "Let bar return slowly to the top with control"
    ],
    "cues": [
      "Pull elbows down and back",
      "Chest up toward the bar"
    ],
    "commonMistakes": [
      "Leaning too far back",
      "Pulling behind the neck"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Am Latzug sitzen, Stange weiter als schulterbreit greifen",
          "Leicht zurücklehnen, Stange zur oberen Brust ziehen",
          "Schulterblätter unten zusammendrücken",
          "Stange langsam und kontrolliert zurückführen"
        ],
        "cues": [
          "Ellbogen nach unten und hinten",
          "Brust zur Stange strecken"
        ],
        "commonMistakes": [
          "Zu weit zurücklehnen",
          "Hinter den Nacken ziehen"
        ]
      }
    }
  },
  {
    "id": "seated_cable_row",
    "name": "Seated Cable Row",
    "name_de": "Kabelrudern sitzend",
    "type": "strength",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "biceps"
    ],
    "muscleGroups": [
      "back",
      "biceps"
    ],
    "equipment": [
      "machine"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Sit at the cable row machine with feet on the platform",
      "Grip the handle with arms extended, back straight",
      "Pull handle toward lower chest, squeezing shoulder blades",
      "Return with control to the stretched position"
    ],
    "cues": [
      "Keep chest up",
      "Don't swing the torso"
    ],
    "commonMistakes": [
      "Excessive torso swing",
      "Rounding the back"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Am Kabelruder-Gerät sitzen, Füße auf der Plattform",
          "Griff mit gestreckten Armen fassen, Rücken gerade",
          "Griff zur unteren Brust ziehen, Schulterblätter zusammen",
          "Kontrolliert in die gestreckte Position zurück"
        ],
        "cues": [
          "Brust raus",
          "Oberkörper nicht schwingen"
        ],
        "commonMistakes": [
          "Zu viel Oberkörperschwung",
          "Rücken runden"
        ]
      }
    }
  },
  {
    "id": "t_bar_row",
    "name": "T-Bar Row",
    "name_de": "T-Bar-Rudern",
    "type": "strength",
    "primaryMuscles": [
      "back"
    ],
    "secondaryMuscles": [
      "biceps"
    ],
    "muscleGroups": [
      "back",
      "biceps"
    ],
    "equipment": [
      "barbell"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Straddle the T-bar or landmine with a close grip handle",
      "Hinge at hips with back flat at 45 degrees",
      "Pull weight toward chest by driving elbows back",
      "Lower with control"
    ],
    "cues": [
      "Keep chest up",
      "Squeeze at the top"
    ],
    "commonMistakes": [
      "Standing too upright",
      "Jerking the weight"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Über der T-Bar stehen, engen Griff verwenden",
          "In der Hüfte beugen, Rücken gerade bei 45 Grad",
          "Gewicht zur Brust ziehen, Ellbogen nach hinten",
          "Kontrolliert ablassen"
        ],
        "cues": [
          "Brust raus",
          "Oben zusammendrücken"
        ],
        "commonMistakes": [
          "Zu aufrecht stehen",
          "Gewicht reißen"
        ]
      }
    }
  },
  {
    "id": "face_pull",
    "name": "Face Pull",
    "type": "strength",
    "primaryMuscles": [
      "shoulders"
    ],
    "secondaryMuscles": [
      "back"
    ],
    "muscleGroups": [
      "shoulders",
      "back"
    ],
    "equipment": [
      "machine"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Set cable pulley to upper chest or face height with rope attachment",
      "Grip rope with thumbs pointing back and step back",
      "Pull rope toward face, separating hands at the end",
      "Squeeze rear delts and return with control"
    ],
    "cues": [
      "Pull apart at the end",
      "Keep elbows high"
    ],
    "commonMistakes": [
      "Using too much weight",
      "Pulling too low"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Kabelzug auf Brust- oder Gesichtshöhe mit Seilaufsatz",
          "Seil greifen, Daumen nach hinten, zurücktreten",
          "Seil zum Gesicht ziehen, Hände am Ende auseinanderziehen",
          "Hintere Schulter anspannen, kontrolliert zurück"
        ],
        "cues": [
          "Am Ende auseinanderziehen",
          "Ellbogen hoch halten"
        ],
        "commonMistakes": [
          "Zu viel Gewicht",
          "Zu tief ziehen"
        ]
      }
    }
  },
  {
    "id": "overhead_press",
    "name": "Overhead Press",
    "name_de": "Schulterdrücken",
    "type": "strength",
    "primaryMuscles": [
      "shoulders"
    ],
    "secondaryMuscles": [
      "triceps"
    ],
    "muscleGroups": [
      "shoulders",
      "triceps"
    ],
    "equipment": [
      "barbell"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Stand with feet shoulder-width, barbell at shoulder height in front",
      "Grip bar slightly wider than shoulder-width",
      "Press bar overhead until arms are fully locked out",
      "Lower bar back to shoulders with control"
    ],
    "cues": [
      "Brace core tight",
      "Push head through at the top"
    ],
    "commonMistakes": [
      "Excessive back arch",
      "Not locking out at the top"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Schulterbreit stehen, Langhantel auf Schulterhöhe vorne",
          "Stange etwas weiter als schulterbreit greifen",
          "Stange über Kopf drücken bis Arme voll gestreckt",
          "Stange kontrolliert zurück zu den Schultern"
        ],
        "cues": [
          "Core fest anspannen",
          "Kopf oben durchschieben"
        ],
        "commonMistakes": [
          "Zu starkes Hohlkreuz",
          "Oben nicht voll ausstrecken"
        ]
      }
    }
  },
  {
    "id": "dumbbell_shoulder_press",
    "name": "Dumbbell Shoulder Press",
    "name_de": "Kurzhantel-Schulterdrücken",
    "type": "strength",
    "primaryMuscles": [
      "shoulders"
    ],
    "secondaryMuscles": [
      "triceps"
    ],
    "muscleGroups": [
      "shoulders",
      "triceps"
    ],
    "equipment": [
      "dumbbell"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Sit or stand holding dumbbells at shoulder height, palms forward",
      "Press dumbbells overhead until arms are fully extended",
      "Lower dumbbells back to shoulder height with control",
      "Keep core engaged throughout"
    ],
    "cues": [
      "Don't arch the back",
      "Full lockout at top"
    ],
    "commonMistakes": [
      "Leaning back",
      "Pressing unevenly"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Sitzen oder stehen, Kurzhanteln auf Schulterhöhe, Handflächen nach vorne",
          "Hanteln über Kopf drücken bis Arme voll gestreckt",
          "Hanteln kontrolliert auf Schulterhöhe senken",
          "Core durchgehend anspannen"
        ],
        "cues": [
          "Nicht ins Hohlkreuz gehen",
          "Oben voll ausstrecken"
        ],
        "commonMistakes": [
          "Zurücklehnen",
          "Ungleichmäßig drücken"
        ]
      }
    }
  },
  {
    "id": "lateral_raise",
    "name": "Lateral Raise",
    "name_de": "Seitheben",
    "type": "strength",
    "primaryMuscles": [
      "shoulders"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "shoulders"
    ],
    "equipment": [
      "dumbbell"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Stand with dumbbells at your sides, slight bend in elbows",
      "Raise arms out to the sides until parallel to the floor",
      "Pause briefly at the top",
      "Lower with control back to your sides"
    ],
    "cues": [
      "Lead with elbows, not hands",
      "Slight forward lean"
    ],
    "commonMistakes": [
      "Swinging the weights up",
      "Shrugging shoulders"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stehen, Kurzhanteln seitlich, leichte Ellbogenbeugung",
          "Arme seitlich anheben bis parallel zum Boden",
          "Kurz oben pausieren",
          "Kontrolliert zurück zur Seite senken"
        ],
        "cues": [
          "Mit Ellbogen führen, nicht mit Händen",
          "Leicht nach vorne lehnen"
        ],
        "commonMistakes": [
          "Gewichte hochschwingen",
          "Schultern hochziehen"
        ]
      }
    }
  },
  {
    "id": "rear_delt_fly",
    "name": "Rear Delt Fly",
    "name_de": "Reverse Flys",
    "type": "strength",
    "primaryMuscles": [
      "shoulders"
    ],
    "secondaryMuscles": [
      "back"
    ],
    "muscleGroups": [
      "shoulders",
      "back"
    ],
    "equipment": [
      "dumbbell"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Bend forward at the hips with dumbbells hanging below chest",
      "Raise arms out to the sides, squeezing shoulder blades",
      "Pause at the top with arms parallel to floor",
      "Lower with control"
    ],
    "cues": [
      "Lead with pinkies slightly up",
      "Squeeze rear delts at top"
    ],
    "commonMistakes": [
      "Using too much weight",
      "Swinging the torso"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "In der Hüfte nach vorne beugen, Hanteln hängen unter der Brust",
          "Arme seitlich anheben, Schulterblätter zusammendrücken",
          "Oben pausieren, Arme parallel zum Boden",
          "Kontrolliert senken"
        ],
        "cues": [
          "Kleine Finger leicht nach oben",
          "Hintere Schulter oben anspannen"
        ],
        "commonMistakes": [
          "Zu viel Gewicht",
          "Oberkörper schwingt"
        ]
      }
    }
  },
  {
    "id": "shrug",
    "name": "Shrug",
    "name_de": "Schulterheben",
    "type": "strength",
    "primaryMuscles": [
      "shoulders"
    ],
    "secondaryMuscles": [
      "back"
    ],
    "muscleGroups": [
      "shoulders",
      "back"
    ],
    "equipment": [
      "dumbbell"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Stand upright holding dumbbells at your sides",
      "Raise shoulders straight up toward ears",
      "Hold briefly at the top, squeezing traps",
      "Lower shoulders back down with control"
    ],
    "cues": [
      "Straight up and down, no rolling",
      "Squeeze hard at the top"
    ],
    "commonMistakes": [
      "Rolling shoulders",
      "Bending elbows"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Aufrecht stehen, Kurzhanteln seitlich halten",
          "Schultern gerade nach oben zu den Ohren ziehen",
          "Kurz oben halten, Nacken anspannen",
          "Schultern kontrolliert senken"
        ],
        "cues": [
          "Gerade hoch und runter, kein Kreisen",
          "Oben fest anspannen"
        ],
        "commonMistakes": [
          "Schultern kreisen lassen",
          "Ellbogen beugen"
        ]
      }
    }
  },
  {
    "id": "barbell_curl",
    "name": "Barbell Curl",
    "name_de": "Langhantel-Curl",
    "type": "strength",
    "primaryMuscles": [
      "biceps"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "biceps"
    ],
    "equipment": [
      "barbell"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Stand with feet shoulder-width, grip barbell with underhand grip",
      "Keep elbows pinned at your sides",
      "Curl the bar up toward shoulders by flexing biceps",
      "Lower bar back down with control"
    ],
    "cues": [
      "Keep upper arms stationary",
      "Squeeze at the top"
    ],
    "commonMistakes": [
      "Swinging the body",
      "Elbows drifting forward"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Schulterbreit stehen, Langhantel im Untergriff halten",
          "Ellbogen fest an den Seiten",
          "Stange durch Bizeps-Beugung zu den Schultern curlen",
          "Stange kontrolliert absenken"
        ],
        "cues": [
          "Oberarme bleiben stationär",
          "Oben zusammendrücken"
        ],
        "commonMistakes": [
          "Körper schwingt",
          "Ellbogen wandern nach vorne"
        ]
      }
    }
  },
  {
    "id": "dumbbell_curl",
    "name": "Dumbbell Curl",
    "name_de": "Kurzhantel-Curl",
    "type": "strength",
    "primaryMuscles": [
      "biceps"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "biceps"
    ],
    "equipment": [
      "dumbbell"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Stand holding dumbbells at your sides with palms forward",
      "Curl one or both dumbbells up toward shoulders",
      "Squeeze biceps at the top",
      "Lower with control back to starting position"
    ],
    "cues": [
      "Keep elbows at your sides",
      "Full range of motion"
    ],
    "commonMistakes": [
      "Swinging for momentum",
      "Not fully extending at bottom"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stehen, Kurzhanteln seitlich, Handflächen nach vorne",
          "Eine oder beide Hanteln zu den Schultern curlen",
          "Bizeps oben anspannen",
          "Kontrolliert zurück in Ausgangsposition"
        ],
        "cues": [
          "Ellbogen an den Seiten",
          "Voller Bewegungsumfang"
        ],
        "commonMistakes": [
          "Schwung holen",
          "Unten nicht voll strecken"
        ]
      }
    }
  },
  {
    "id": "hammer_curl",
    "name": "Hammer Curl",
    "name_de": "Hammer-Curls",
    "type": "strength",
    "primaryMuscles": [
      "biceps"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "biceps"
    ],
    "equipment": [
      "dumbbell"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Stand holding dumbbells with palms facing each other (neutral grip)",
      "Curl dumbbells up toward shoulders keeping neutral grip",
      "Squeeze at the top",
      "Lower with control"
    ],
    "cues": [
      "Thumbs point up throughout",
      "No wrist rotation"
    ],
    "commonMistakes": [
      "Swinging the weights",
      "Rotating wrists during curl"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stehen, Kurzhanteln mit neutralem Griff (Handflächen zueinander)",
          "Hanteln zu den Schultern curlen, Griff neutral lassen",
          "Oben anspannen",
          "Kontrolliert ablassen"
        ],
        "cues": [
          "Daumen zeigen durchgehend nach oben",
          "Keine Handgelenksdrehung"
        ],
        "commonMistakes": [
          "Gewichte schwingen",
          "Handgelenke drehen beim Curlen"
        ]
      }
    }
  },
  {
    "id": "tricep_pushdown",
    "name": "Tricep Pushdown",
    "name_de": "Trizepsdrücken am Kabel",
    "type": "strength",
    "primaryMuscles": [
      "triceps"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "triceps"
    ],
    "equipment": [
      "machine"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Stand at cable machine with high pulley, grip bar or rope",
      "Keep elbows pinned at your sides",
      "Push the weight down until arms are fully extended",
      "Return to starting position with control"
    ],
    "cues": [
      "Only forearms move",
      "Squeeze triceps at full extension"
    ],
    "commonMistakes": [
      "Elbows flaring out",
      "Leaning over the weight"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Am Kabelzug stehen, obere Rolle, Stange oder Seil greifen",
          "Ellbogen fest an den Seiten",
          "Gewicht nach unten drücken bis Arme voll gestreckt",
          "Kontrolliert in Ausgangsposition zurück"
        ],
        "cues": [
          "Nur Unterarme bewegen sich",
          "Trizeps bei voller Streckung anspannen"
        ],
        "commonMistakes": [
          "Ellbogen gehen nach außen",
          "Über das Gewicht lehnen"
        ]
      }
    }
  },
  {
    "id": "skull_crusher",
    "name": "Skull Crusher",
    "name_de": "Stirndrücken",
    "type": "strength",
    "primaryMuscles": [
      "triceps"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "triceps"
    ],
    "equipment": [
      "barbell",
      "bench"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Lie on a bench holding barbell or EZ-bar with arms extended above chest",
      "Keep upper arms vertical and bend elbows to lower bar toward forehead",
      "Extend arms back to starting position by flexing triceps",
      "Keep elbows pointing toward ceiling throughout"
    ],
    "cues": [
      "Upper arms stay still",
      "Control the descent"
    ],
    "commonMistakes": [
      "Elbows flaring out",
      "Moving upper arms"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Auf der Bank liegen, Lang- oder SZ-Hantel mit gestreckten Armen über der Brust",
          "Oberarme senkrecht, Ellbogen beugen, Stange zur Stirn senken",
          "Arme zurück strecken durch Trizeps-Kontraktion",
          "Ellbogen zeigen durchgehend zur Decke"
        ],
        "cues": [
          "Oberarme bleiben ruhig",
          "Abstieg kontrollieren"
        ],
        "commonMistakes": [
          "Ellbogen gehen auseinander",
          "Oberarme bewegen sich"
        ]
      }
    }
  },
  {
    "id": "overhead_tricep_extension",
    "name": "Overhead Tricep Extension",
    "name_de": "Trizepsdrücken über Kopf",
    "type": "strength",
    "primaryMuscles": [
      "triceps"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "triceps"
    ],
    "equipment": [
      "dumbbell"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Hold a dumbbell with both hands above your head, arms extended",
      "Lower the dumbbell behind your head by bending elbows",
      "Keep upper arms close to ears throughout",
      "Extend arms back up to starting position"
    ],
    "cues": [
      "Elbows point forward",
      "Full stretch at the bottom"
    ],
    "commonMistakes": [
      "Elbows flaring wide",
      "Arching the back"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Kurzhantel mit beiden Händen über dem Kopf halten, Arme gestreckt",
          "Hantel hinter den Kopf senken durch Ellbogenbeugung",
          "Oberarme bleiben nah an den Ohren",
          "Arme zurück in Ausgangsposition strecken"
        ],
        "cues": [
          "Ellbogen zeigen nach vorne",
          "Volle Dehnung unten"
        ],
        "commonMistakes": [
          "Ellbogen gehen weit auseinander",
          "Hohlkreuz"
        ]
      }
    }
  },
  {
    "id": "back_squat",
    "name": "Back Squat",
    "name_de": "Kniebeuge mit Langhantel",
    "type": "strength",
    "primaryMuscles": [
      "quads",
      "glutes"
    ],
    "secondaryMuscles": [
      "core",
      "hamstrings"
    ],
    "muscleGroups": [
      "quads",
      "glutes",
      "core",
      "hamstrings"
    ],
    "equipment": [
      "barbell"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Position barbell on upper back/traps, grip wider than shoulders",
      "Stand with feet shoulder-width, toes slightly out",
      "Lower by bending knees and pushing hips back until thighs are parallel",
      "Drive through heels to stand back up"
    ],
    "cues": [
      "Chest up, core braced",
      "Knees track over toes"
    ],
    "commonMistakes": [
      "Knees caving in",
      "Rounding the back"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Langhantel auf dem oberen Rücken/Nacken positionieren, breit greifen",
          "Schulterbreit stehen, Zehen leicht nach außen",
          "Knie beugen, Hüfte zurückschieben bis Oberschenkel parallel",
          "Über die Fersen nach oben drücken"
        ],
        "cues": [
          "Brust hoch, Core angespannt",
          "Knie folgen den Zehen"
        ],
        "commonMistakes": [
          "Knie fallen nach innen",
          "Rücken rundet sich"
        ]
      }
    }
  },
  {
    "id": "front_squat",
    "name": "Front Squat",
    "name_de": "Frontkniebeuge",
    "type": "strength",
    "primaryMuscles": [
      "quads"
    ],
    "secondaryMuscles": [
      "glutes",
      "core"
    ],
    "muscleGroups": [
      "quads",
      "glutes",
      "core"
    ],
    "equipment": [
      "barbell"
    ],
    "difficulty": 3,
    "source": "curated",
    "instructionsSteps": [
      "Rest barbell on front delts with elbows high in a front rack position",
      "Stand with feet shoulder-width apart",
      "Lower into a deep squat keeping torso upright",
      "Drive up through heels maintaining the upright position"
    ],
    "cues": [
      "Elbows high throughout",
      "Stay as upright as possible"
    ],
    "commonMistakes": [
      "Elbows dropping",
      "Leaning forward"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Langhantel auf den vorderen Schultern in Front-Rack-Position, Ellbogen hoch",
          "Schulterbreit stehen",
          "Tief in die Kniebeuge, Oberkörper aufrecht",
          "Über die Fersen hochdrücken, aufrecht bleiben"
        ],
        "cues": [
          "Ellbogen durchgehend hoch",
          "So aufrecht wie möglich"
        ],
        "commonMistakes": [
          "Ellbogen sinken ab",
          "Nach vorne lehnen"
        ]
      }
    }
  },
  {
    "id": "goblet_squat",
    "name": "Goblet Squat",
    "name_de": "Goblet-Kniebeuge",
    "type": "strength",
    "primaryMuscles": [
      "quads"
    ],
    "secondaryMuscles": [
      "glutes"
    ],
    "muscleGroups": [
      "quads",
      "glutes"
    ],
    "equipment": [
      "kettlebell"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Hold a kettlebell or dumbbell at chest height with both hands",
      "Stand with feet slightly wider than shoulder-width",
      "Squat down keeping weight at chest and torso upright",
      "Drive through heels to stand back up"
    ],
    "cues": [
      "Elbows inside knees at bottom",
      "Keep chest up"
    ],
    "commonMistakes": [
      "Leaning forward",
      "Knees caving in"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Kettlebell oder Kurzhantel mit beiden Händen vor der Brust halten",
          "Etwas breiter als schulterbreit stehen",
          "In die Hocke gehen, Gewicht an der Brust, Oberkörper aufrecht",
          "Über die Fersen nach oben drücken"
        ],
        "cues": [
          "Ellbogen zwischen den Knien unten",
          "Brust oben halten"
        ],
        "commonMistakes": [
          "Nach vorne lehnen",
          "Knie fallen nach innen"
        ]
      }
    }
  },
  {
    "id": "bulgarian_split_squat",
    "name": "Bulgarian Split Squat",
    "name_de": "Bulgarische Kniebeuge",
    "type": "strength",
    "primaryMuscles": [
      "quads"
    ],
    "secondaryMuscles": [
      "glutes"
    ],
    "muscleGroups": [
      "quads",
      "glutes"
    ],
    "equipment": [
      "dumbbell",
      "bench"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Stand about 2 feet in front of a bench, place rear foot on bench",
      "Hold dumbbells at sides or at shoulders",
      "Lower until front thigh is parallel to floor",
      "Drive through front heel to stand back up"
    ],
    "cues": [
      "Front knee tracks over toes",
      "Torso stays upright"
    ],
    "commonMistakes": [
      "Front foot too close to bench",
      "Leaning forward excessively"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Ca. 60 cm vor einer Bank stehen, hinteren Fuß auf die Bank",
          "Kurzhanteln seitlich oder an den Schultern halten",
          "Absenken bis vorderer Oberschenkel parallel zum Boden",
          "Über die vordere Ferse hochdrücken"
        ],
        "cues": [
          "Vorderes Knie folgt den Zehen",
          "Oberkörper bleibt aufrecht"
        ],
        "commonMistakes": [
          "Vorderer Fuß zu nah an der Bank",
          "Zu weit nach vorne lehnen"
        ]
      }
    }
  },
  {
    "id": "leg_press",
    "name": "Leg Press",
    "name_de": "Beinpresse",
    "type": "strength",
    "primaryMuscles": [
      "quads"
    ],
    "secondaryMuscles": [
      "glutes"
    ],
    "muscleGroups": [
      "quads",
      "glutes"
    ],
    "equipment": [
      "machine"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Sit in the leg press machine with back flat against pad",
      "Place feet shoulder-width on the platform",
      "Lower the platform by bending knees to about 90 degrees",
      "Press through feet to extend legs back to starting position"
    ],
    "cues": [
      "Don't lock knees fully at top",
      "Keep lower back flat on pad"
    ],
    "commonMistakes": [
      "Going too deep causing back to round",
      "Locking out knees"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "In der Beinpresse sitzen, Rücken flach am Polster",
          "Füße schulterbreit auf der Plattform",
          "Plattform senken, Knie auf ca. 90 Grad beugen",
          "Durch die Füße drücken, Beine zurück strecken"
        ],
        "cues": [
          "Knie oben nicht komplett durchstrecken",
          "Unteren Rücken am Polster lassen"
        ],
        "commonMistakes": [
          "Zu tief gehen, Rücken rundet",
          "Knie durchstrecken"
        ]
      }
    }
  },
  {
    "id": "leg_extension",
    "name": "Leg Extension",
    "name_de": "Beinstrecker",
    "type": "strength",
    "primaryMuscles": [
      "quads"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "quads"
    ],
    "equipment": [
      "machine"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Sit on the machine with back against pad and ankles behind roller",
      "Extend legs until fully straight",
      "Squeeze quads at the top",
      "Lower with control back to starting position"
    ],
    "cues": [
      "Squeeze hard at full extension",
      "Control the negative"
    ],
    "commonMistakes": [
      "Using momentum",
      "Not reaching full extension"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "An der Maschine sitzen, Rücken am Polster, Knöchel hinter der Rolle",
          "Beine strecken bis sie vollständig gerade sind",
          "Oberschenkel oben anspannen",
          "Kontrolliert in Ausgangsposition zurück"
        ],
        "cues": [
          "Bei voller Streckung fest anspannen",
          "Negative Phase kontrollieren"
        ],
        "commonMistakes": [
          "Schwung nutzen",
          "Nicht voll strecken"
        ]
      }
    }
  },
  {
    "id": "leg_curl",
    "name": "Leg Curl",
    "name_de": "Beinbeuger",
    "type": "strength",
    "primaryMuscles": [
      "hamstrings"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "hamstrings"
    ],
    "equipment": [
      "machine"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Lie face down or sit on the leg curl machine",
      "Position ankles under the roller pad",
      "Curl heels toward glutes by bending knees",
      "Lower back to starting position with control"
    ],
    "cues": [
      "Squeeze hamstrings at top",
      "Don't lift hips off pad"
    ],
    "commonMistakes": [
      "Using momentum to swing weight",
      "Lifting hips"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Bäuchlings oder sitzend an der Beinbeuge-Maschine",
          "Knöchel unter dem Rollenpolster positionieren",
          "Fersen zum Gesäß curlen durch Kniebeugung",
          "Kontrolliert zurück in Ausgangsposition"
        ],
        "cues": [
          "Hamstrings oben anspannen",
          "Hüfte nicht vom Polster heben"
        ],
        "commonMistakes": [
          "Schwung nutzen",
          "Hüfte hebt ab"
        ]
      }
    }
  },
  {
    "id": "deadlift",
    "name": "Deadlift",
    "name_de": "Kreuzheben",
    "type": "strength",
    "primaryMuscles": [
      "glutes",
      "hamstrings"
    ],
    "secondaryMuscles": [
      "back",
      "quads",
      "core"
    ],
    "muscleGroups": [
      "glutes",
      "hamstrings",
      "back",
      "quads",
      "core"
    ],
    "equipment": [
      "barbell"
    ],
    "difficulty": 3,
    "source": "curated",
    "instructionsSteps": [
      "Stand with feet hip-width, barbell over mid-foot",
      "Hinge at hips, grip bar just outside knees",
      "Lift by driving through heels, extending hips and knees together",
      "Stand tall at the top, then lower bar back to floor with control"
    ],
    "cues": [
      "Keep bar close to body",
      "Back stays flat throughout"
    ],
    "commonMistakes": [
      "Rounding the lower back",
      "Bar drifting away from body"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Hüftbreit stehen, Langhantel über der Fußmitte",
          "In der Hüfte beugen, Stange knapp außerhalb der Knie greifen",
          "Über die Fersen heben, Hüfte und Knie gleichzeitig strecken",
          "Oben aufrecht stehen, dann Stange kontrolliert zurück zum Boden"
        ],
        "cues": [
          "Stange nah am Körper",
          "Rücken bleibt durchgehend gerade"
        ],
        "commonMistakes": [
          "Unteren Rücken runden",
          "Stange driftet vom Körper weg"
        ]
      }
    }
  },
  {
    "id": "romanian_deadlift",
    "name": "Romanian Deadlift",
    "name_de": "Rumänisches Kreuzheben",
    "type": "strength",
    "primaryMuscles": [
      "hamstrings",
      "glutes"
    ],
    "secondaryMuscles": [
      "back",
      "core"
    ],
    "muscleGroups": [
      "hamstrings",
      "glutes",
      "back",
      "core"
    ],
    "equipment": [
      "barbell"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Stand holding barbell at hip height with straight arms",
      "Push hips back while lowering bar along legs with slight knee bend",
      "Lower until you feel a deep stretch in hamstrings",
      "Drive hips forward to return to standing"
    ],
    "cues": [
      "Push hips back, not down",
      "Keep bar close to legs"
    ],
    "commonMistakes": [
      "Rounding the back",
      "Bending knees too much"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Stehend, Langhantel auf Hüfthöhe mit gestreckten Armen halten",
          "Hüfte nach hinten schieben, Stange an den Beinen entlang senken, Knie leicht gebeugt",
          "Senken bis tiefe Dehnung in den Hamstrings",
          "Hüfte nach vorne drücken zum Aufrichten"
        ],
        "cues": [
          "Hüfte nach hinten, nicht nach unten",
          "Stange nah an den Beinen"
        ],
        "commonMistakes": [
          "Rücken runden",
          "Knie zu stark beugen"
        ]
      }
    }
  },
  {
    "id": "hip_thrust",
    "name": "Hip Thrust",
    "type": "strength",
    "primaryMuscles": [
      "glutes"
    ],
    "secondaryMuscles": [
      "hamstrings",
      "core"
    ],
    "muscleGroups": [
      "glutes",
      "hamstrings",
      "core"
    ],
    "equipment": [
      "barbell",
      "bench"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Sit on the ground with upper back against a bench, barbell over hips",
      "Drive through heels to lift hips until body is parallel to floor",
      "Squeeze glutes hard at the top",
      "Lower hips back down with control"
    ],
    "cues": [
      "Chin tucked at the top",
      "Full glute squeeze"
    ],
    "commonMistakes": [
      "Overextending lower back",
      "Feet too far forward"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Am Boden sitzen, oberer Rücken an einer Bank, Langhantel über der Hüfte",
          "Über die Fersen die Hüfte heben bis Körper parallel zum Boden",
          "Gesäß oben fest anspannen",
          "Hüfte kontrolliert wieder absenken"
        ],
        "cues": [
          "Kinn oben einziehen",
          "Volle Gesäß-Kontraktion"
        ],
        "commonMistakes": [
          "Unteren Rücken überstrecken",
          "Füße zu weit vorne"
        ]
      }
    }
  },
  {
    "id": "barbell_lunge",
    "name": "Barbell Lunge",
    "name_de": "Langhantel-Ausfallschritt",
    "type": "strength",
    "primaryMuscles": [
      "quads"
    ],
    "secondaryMuscles": [
      "glutes"
    ],
    "muscleGroups": [
      "quads",
      "glutes"
    ],
    "equipment": [
      "barbell"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Position barbell on upper back like a squat",
      "Step forward with one leg into a lunge",
      "Lower until both knees are at 90 degrees",
      "Push through front heel to return to standing"
    ],
    "cues": [
      "Keep torso upright",
      "Front knee over ankle"
    ],
    "commonMistakes": [
      "Leaning forward",
      "Knee going past toes"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Langhantel wie bei der Kniebeuge auf dem oberen Rücken",
          "Mit einem Bein nach vorne in den Ausfallschritt",
          "Absenken bis beide Knie 90 Grad",
          "Über die vordere Ferse zurück zum Stand drücken"
        ],
        "cues": [
          "Oberkörper aufrecht",
          "Vorderes Knie über dem Knöchel"
        ],
        "commonMistakes": [
          "Nach vorne lehnen",
          "Knie geht über die Zehen"
        ]
      }
    }
  },
  {
    "id": "kettlebell_swing",
    "name": "Kettlebell Swing",
    "type": "strength",
    "primaryMuscles": [
      "glutes",
      "hamstrings"
    ],
    "secondaryMuscles": [
      "core",
      "back",
      "shoulders"
    ],
    "muscleGroups": [
      "glutes",
      "hamstrings",
      "core",
      "back",
      "shoulders"
    ],
    "equipment": [
      "kettlebell"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Stand with feet wider than shoulder-width, kettlebell on the floor in front",
      "Hinge at hips, grip kettlebell with both hands",
      "Swing kettlebell back between legs, then drive hips forward explosively",
      "Let the kettlebell swing to chest height, then let it swing back"
    ],
    "cues": [
      "Power comes from hips, not arms",
      "Snap hips forward"
    ],
    "commonMistakes": [
      "Squatting instead of hinging",
      "Using arms to lift"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Breiter als schulterbreit stehen, Kettlebell auf dem Boden davor",
          "In der Hüfte beugen, Kettlebell mit beiden Händen greifen",
          "Kettlebell zwischen den Beinen nach hinten schwingen, dann Hüfte explosiv nach vorne",
          "Kettlebell auf Brusthöhe schwingen lassen, dann zurückschwingen"
        ],
        "cues": [
          "Kraft kommt aus der Hüfte, nicht den Armen",
          "Hüfte nach vorne schnappen"
        ],
        "commonMistakes": [
          "Kniebeuge statt Hüftbeugung",
          "Mit den Armen heben"
        ]
      }
    }
  },
  {
    "id": "farmers_walk",
    "name": "Farmer's Walk",
    "type": "strength",
    "primaryMuscles": [
      "core"
    ],
    "secondaryMuscles": [
      "shoulders",
      "glutes",
      "quads"
    ],
    "muscleGroups": [
      "core",
      "shoulders",
      "glutes",
      "quads"
    ],
    "equipment": [
      "dumbbell"
    ],
    "difficulty": 2,
    "source": "curated",
    "instructionsSteps": [
      "Pick up heavy dumbbells or kettlebells, one in each hand",
      "Stand tall with shoulders back and core braced",
      "Walk forward with controlled, even steps",
      "Maintain upright posture for the target distance or time"
    ],
    "cues": [
      "Shoulders down and back",
      "Short, quick steps"
    ],
    "commonMistakes": [
      "Leaning to one side",
      "Rounding shoulders"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Schwere Kurzhanteln oder Kettlebells aufnehmen, eine pro Hand",
          "Aufrecht stehen, Schultern zurück, Core angespannt",
          "Mit kontrollierten, gleichmäßigen Schritten vorwärts gehen",
          "Aufrechte Haltung für Zieldistanz oder -zeit beibehalten"
        ],
        "cues": [
          "Schultern unten und zurück",
          "Kurze, schnelle Schritte"
        ],
        "commonMistakes": [
          "Zur Seite lehnen",
          "Schultern runden"
        ]
      }
    }
  },
  {
    "id": "cable_fly",
    "name": "Cable Fly",
    "name_de": "Kabelzug-Fliegende",
    "type": "strength",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "chest"
    ],
    "equipment": [
      "machine"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Stand between cable towers, pulleys at desired height",
      "Grip handles and step forward with slight forward lean",
      "Bring hands together in front of chest in an arc",
      "Return slowly to stretched position"
    ],
    "cues": [
      "Slight elbow bend throughout",
      "Squeeze chest together"
    ],
    "commonMistakes": [
      "Straightening arms fully",
      "Too much shoulder involvement"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "Zwischen den Kabeltürmen stehen, Rollen auf gewünschter Höhe",
          "Griffe fassen, nach vorne treten, leicht vorlehnen",
          "Hände in einem Bogen vor der Brust zusammenführen",
          "Langsam in die gedehnte Position zurück"
        ],
        "cues": [
          "Leichte Ellbogenbeugung durchgehend",
          "Brust zusammendrücken"
        ],
        "commonMistakes": [
          "Arme komplett strecken",
          "Zu viel Schulter"
        ]
      }
    }
  },
  {
    "id": "machine_chest_press",
    "name": "Machine Chest Press",
    "name_de": "Brustpresse",
    "type": "strength",
    "primaryMuscles": [
      "chest"
    ],
    "secondaryMuscles": [
      "triceps"
    ],
    "muscleGroups": [
      "chest",
      "triceps"
    ],
    "equipment": [
      "machine"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Sit in the machine with back flat against pad",
      "Grip handles at chest height",
      "Press handles forward until arms are extended",
      "Return with control to starting position"
    ],
    "cues": [
      "Keep shoulder blades retracted",
      "Controlled movement"
    ],
    "commonMistakes": [
      "Rounding shoulders forward",
      "Locking elbows"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "In der Maschine sitzen, Rücken am Polster",
          "Griffe auf Brusthöhe fassen",
          "Griffe nach vorne drücken bis Arme gestreckt",
          "Kontrolliert in Ausgangsposition zurück"
        ],
        "cues": [
          "Schulterblätter zusammengezogen lassen",
          "Kontrollierte Bewegung"
        ],
        "commonMistakes": [
          "Schultern nach vorne runden",
          "Ellbogen durchstrecken"
        ]
      }
    }
  },
  {
    "id": "seated_calf_raise",
    "name": "Seated Calf Raise",
    "name_de": "Wadenheben sitzend",
    "type": "strength",
    "primaryMuscles": [
      "calves"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "calves"
    ],
    "equipment": [
      "machine"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Sit at the machine with knees under the pad and balls of feet on platform",
      "Lower heels as far as possible for a full stretch",
      "Push up onto toes as high as possible",
      "Pause at the top, then lower with control"
    ],
    "cues": [
      "Full range of motion",
      "Pause at top and bottom"
    ],
    "commonMistakes": [
      "Bouncing reps",
      "Partial range of motion"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "An der Maschine sitzen, Knie unter dem Polster, Fußballen auf der Plattform",
          "Fersen so tief wie möglich für volle Dehnung",
          "Auf die Zehen so hoch wie möglich drücken",
          "Oben pausieren, dann kontrolliert senken"
        ],
        "cues": [
          "Voller Bewegungsumfang",
          "Oben und unten pausieren"
        ],
        "commonMistakes": [
          "Wiederholungen federn",
          "Halber Bewegungsumfang"
        ]
      }
    }
  },
  {
    "id": "standing_calf_raise",
    "name": "Standing Calf Raise",
    "name_de": "Wadenheben stehend",
    "type": "strength",
    "primaryMuscles": [
      "calves"
    ],
    "secondaryMuscles": [],
    "muscleGroups": [
      "calves"
    ],
    "equipment": [
      "machine"
    ],
    "difficulty": 1,
    "source": "curated",
    "instructionsSteps": [
      "Stand in the calf raise machine with shoulders under pads",
      "Balls of feet on the platform, heels hanging off",
      "Rise up as high as possible onto toes",
      "Lower heels below the platform for full stretch"
    ],
    "cues": [
      "Pause at top for 1-2 seconds",
      "Control the eccentric"
    ],
    "commonMistakes": [
      "Bouncing at the bottom",
      "Bending knees"
    ],
    "i18n": {
      "de": {
        "instructionsSteps": [
          "In der Wadenheben-Maschine stehen, Schultern unter den Polstern",
          "Fußballen auf der Plattform, Fersen hängen über",
          "So hoch wie möglich auf die Zehen drücken",
          "Fersen unter die Plattform für volle Dehnung senken"
        ],
        "cues": [
          "Oben 1-2 Sekunden pausieren",
          "Exzentrik kontrollieren"
        ],
        "commonMistakes": [
          "Unten federn",
          "Knie beugen"
        ]
      }
    }
  }
];

// ========================================
// INITIALIZE / RESEED CURATED EXERCISES
// ========================================
// Idempotent: seeds the global exercises_curated collection with stable,
// human-readable ids. On a version bump it wipes the previously-seeded curated
// docs (which had random ids / cardio entries) and writes the fresh dataset.
async function initializeDefaultExercises() {
  try {
    const installed = parseInt(localStorage.getItem(CURATED_SEED_KEY) || '0', 10);
    const existing = await getAllDocs(exercisesCuratedCollection);

    // Already current and present → nothing to do.
    if (installed >= CURATED_SEED_VERSION && existing.length > 0) return;

    // Clean slate: drop any previously-seeded curated docs.
    for (const ex of existing) {
      await deleteDoc(exercisesCuratedCollection, ex.id);
    }

    // Seed fresh with stable ids.
    for (const exercise of defaultExercises) {
      await setCuratedExercise(exercise.id, exercise);
    }

    localStorage.setItem(CURATED_SEED_KEY, String(CURATED_SEED_VERSION));
  } catch (error) {
    console.error('Error initializing exercises:', error);
  }
}
