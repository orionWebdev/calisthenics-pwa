# Vertrag 1c — Architektur

**Status:** verbindlich ab Stufe 1

## Ordnerstruktur

```
lib/
├── app/
│   ├── app.dart              MaterialApp, Router, Lokalisierung
│   └── router.dart           go_router, StatefulShellRoute für die Nav
├── core/
│   ├── i18n/                 AtemFormat
│   ├── services/             Haptik, Audio, Health Connect (später)
│   ├── theme/                atem_colors, atem_gradients, atem_geometry,
│   │                         atem_motion, atem_type, atem_theme
│   ├── utils/
│   └── widgets/              Die Primitive. Nur hier.
├── features/
│   └── <feature>/
│       ├── data/             Repository-Implementierungen
│       ├── domain/           Modelle, Repository-Verträge. KEIN Flutter-Import.
│       ├── application/      Riverpod-Provider und Notifier
│       └── presentation/
│           ├── screens/
│           └── widgets/      Feature-eigene Bausteine
├── l10n/
│   ├── arb/                  app_de.arb, app_en.arb
│   └── gen/                  erzeugt, eingecheckt
└── main.dart                 Initialisierung, ProviderScope-Overrides
```

**`lib/theme/` verschwindet.** Eine Theme-Datei hält Token und `ThemeData` — keine Widgets.
`GlassCard`, `GradientBorderGlassCard` und `GlassBar` ziehen nach `core/widgets/`.

## Schichtregeln

| Schicht | Darf importieren | Darf **nicht** |
|---|---|---|
| `domain/` | `package:meta`, andere `domain/`-Dateien | **`package:flutter/*`**, Riverpod, `data/`, `presentation/` |
| `application/` | `domain/`, Riverpod | `presentation/`, `package:flutter/material.dart` |
| `data/` | `domain/`, Firebase | `presentation/` |
| `presentation/` | alles | — |

Die Domänenregel ist die wichtigste und wird vom Analyzer erzwungen. Sie ist heute in beiden
Features verletzt, weil die Enums `Color`-Werte tragen.

## Riverpod

**Version 3.4.2.** In 3.x liegen `StateProvider`, `StateNotifierProvider` und
`ChangeNotifierProvider` in `package:flutter_riverpod/legacy.dart` — wir nutzen zwei davon.
Zudem pinnt `riverpod_lint` exakt auf 3.4.2, ist ohne Upgrade also nicht verfügbar.

### Notifier statt StateNotifier

Kein Stilfrage, sondern Korrektheit:

- `WorkoutSessionController extends StateNotifier<AsyncValue<ActiveWorkout>>` baut
  `AsyncValue.guard` im Konstruktor nach. Fehler beim Laden landen im Zustand, bevor ein
  Zuhörer existiert, und es gibt keinen `ref`-Lebenszyklus. Als `AsyncNotifier<ActiveWorkout>`
  mit `build()` gibt es Laden, Fehler und Wiederholen (`ref.invalidateSelf()`) geschenkt.
- `SessionTimerController` hält `DateTime? _startedAt` **außerhalb** von `state`. Der
  eigentliche Zustand ist damit für Riverpod unsichtbar und nicht testbar — und der
  `Timer.periodic` liegt im Screen, weshalb `_onToggleSession` diesen brüchigen
  Abbrechen-und-neu-starten-Tanz um `Navigator.pushNamed` braucht. Als `Notifier` mit eigenem
  Timer und `ref.onDispose(timer.cancel)` löst sich beides auf.
- `activeNavIndexProvider` entfällt ersatzlos — der aktive Tab gehört zum Router.

### Kein riverpod_generator

Bei absehbar rund 15 Providern spart Codegen etwa 60 Zeilen und kostet dauerhaft einen
`build_runner watch` neben dem Analyzer, eine `.g.dart` je Datei und eine ganze Klasse von
Fehlern durch veraltete Generate, die sich als verwirrende Typfehler zeigen.

**Revisionsauslöser, schriftlich festgehalten, damit die Frage nicht monatlich neu
aufkommt:** Codegen wird erneut geprüft, wenn die Zahl der Provider **40** überschreitet oder
untypisierte `family`-Argumente nachweislich einen Fehler verursacht haben.

`riverpod_lint ^3.1.8` wird dagegen übernommen — es funktioniert ohne Codegen und fängt
`missing_provider_scope`, `avoid_ref_inside_state_dispose` und
`avoid_public_notifier_properties`.

### Konventionen

- Eine Datei `application/<feature>_providers.dart` je Feature
- Repository-Provider sind `Provider<T>`, die `UnimplementedError` werfen und im
  `ProviderScope` überschrieben werden. **Das bestehende Muster bleibt** — es ist gut, und die
  Preview-Repositories bleiben dauerhaft als Test- und Entwicklungsschicht erhalten.
- Kein `ref.read` in `build()`
- Kein `BuildContext` in Providern
- Timer und Abonnements leben im Notifier mit `ref.onDispose`
- Screens sind `ConsumerWidget`; `ConsumerStatefulWidget` nur, wo ein `AnimationController`
  besessen wird

## Routing

`go_router ^18` mit `StatefulShellRoute` für die fünf Nav-Bereiche. Jeder Tab bekommt seinen
eigenen Navigationsstapel, und der aktive Index kommt vom Router.

Heute nutzt `main.dart` `onGenerateRoute` mit `settings.arguments as String? ?? ''` — das ist
untypisiert und überlebt weder fünf Tabs noch Deep Links. Der Umbau kostet rund 150 Zeilen und
bestimmt die Form jedes danach gebauten Screens, gehört also ins Fundament.

## Dateigröße

Presentation-Widgets bleiben unter **200 Zeilen**. Die heutigen 1.871 und 1.043 Zeilen werden
in Stufe 5 nach `presentation/widgets/` aufgeteilt.

Keine harte Regel für andere Schichten — aber eine Datei, die man nicht am Stück lesen kann,
wird nicht gelesen.

## Benennung

- Widgets im Baukasten: Präfix `Atem` (`AtemTappable`, `AtemPill`)
- Feature-eigene Widgets ohne Präfix, privat wo möglich
- Dateien `snake_case`, ein öffentliches Widget je Datei bei den Primitiven
- Token-Halter sind `abstract final class`, keine `ThemeExtension` — die App ist dauerhaft
  dunkel, statische Halter sind korrekt und billiger

## Analyzer

Regeln laufen über `analysis_server_plugin` und den **top-level** `plugins:`-Block in
`analysis_options.yaml` — **nicht** über `custom_lint`, das auf Dart 3.13 nicht mehr auflöst.

```yaml
plugins:
  atem_lints:
    path: tool/atem_lints
    diagnostics:
      atem_no_small_font_size: true
      atem_no_raw_gesture_detector: false        # → true ab Stufe 4
      atem_no_flutter_import_in_domain: false    # → true ab Stufe 3
      atem_no_text_string_literal: false         # → true ab Stufe 3
      atem_violet_not_text: true
      atem_decorative_label_needs_semantics: true
      atem_no_fitted_box: true
  riverpod_lint: ^3.1.8
```

Regeln mit Altlast starten auf `false` und werden je Stufe auf `true` geflippt. Der `git diff`
dieses Blocks ist damit der maschinenlesbare Nachweis jeder Fertig-Definition.

### `dart analyze`, nicht `flutter analyze`

**Verifiziert am 26.08.2026:** `flutter analyze` führt Analyzer-Plugins **nicht** aus.
`dart analyze` tut es. Ein absichtlich eingebauter Verstoß gegen
`avoid_public_notifier_properties` wurde von `dart analyze` gemeldet und von
`flutter analyze` stillschweigend übersehen.

Für die CI und jede lokale Prüfung gilt deshalb `dart analyze`. `flutter analyze` bleibt
nützlich für flutter-spezifische Meldungen, ist aber **kein** vollständiges Tor.

Nebenbefund: Etwa die Hälfte der `riverpod_lint`-Regeln ist als „riverpod_generator only"
markiert und greift ohne Codegen nicht. Wirksam bleiben unter anderem
`avoid_public_notifier_properties`, `missing_provider_scope`,
`avoid_ref_inside_state_dispose`, `provider_parameters` und `async_value_nullable_pattern`.

**Risiko:** `analysis_server_plugin` steht bei 0.3.x, die offizielle Dokumentation zeigt noch
`^0.2.2`. **Zeitbox: ein Tag.** Fällt es durch, greift ein rund 60-zeiliges
`dart run tool/check_conventions.dart` mit Regex über `lib/`, in die CI verdrahtet. Es fängt
dieselben Muster; verloren geht nur die Anzeige im Editor. Eine Woche hier zu versenken ist
nicht vertretbar.

## CI

Billige Tore zuerst:

1. `dart format --output=none --set-exit-if-changed .`
2. `dart analyze --fatal-infos --fatal-warnings` — **`dart`, nicht `flutter`**, sonst laufen
   die Plugins nicht (siehe oben)
3. `flutter gen-l10n && git diff --exit-code lib/l10n/gen`
4. `l10n/untranslated.json` muss leer sein
5. `flutter test --exclude-tags a11y` — muss grün sein
6. `flutter test --tags a11y` — das Tor. **Bis Stufe 5 erwartet rot**, danach
   blockierend. Der Ausschluss oben verschwindet dann.
7. `flutter test --tags golden`

**`flutter test` liest `exclude-tags` aus `dart_test.yaml` nicht** (verifiziert 26.08.2026).
Der Ausschluss muss als Flag übergeben werden, sonst läuft das Tor still mit und färbt die
CI rot.
8. `dart run tool/check_conventions.dart` — die gestaffelten Konventionsregeln
9. `flutter build appbundle --release` (nur auf Tags)

## Goldens

**Nur für die Primitive**, bei 1.0× und 2.0× auf flachem Grund. Rund 22 stabile Dateien.

**Nicht für die zwei Neon-Screens.** `BackdropFilter`, `MaskFilter.blur`, `SweepGradient` und
Unterschiede zwischen Impeller und Skia erzeugen dort Rauschen, das das Wartungsbudget
auffrisst. Was auf diesem Design tatsächlich bricht, ist Layout — und das fängt die
3×3-Matrix aus dem A11y-Vertrag.

## Bewusst nicht gebaut

Kein generischer Button mit acht Varianten · keine `ThemeExtension` · kein `AtemText`-Wrapper ·
keine Token-Generierung aus dem HTML-Design-System · kein `AtemAnimatedNumber`, bevor ein
zweiter Screen ihn braucht.
