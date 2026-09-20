package com.atemhybrid.app

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * **FlutterFragmentActivity, nicht FlutterActivity.**
 *
 * Health Connect fragt seine Berechtigungen über die AndroidX-Activity-Result-
 * Schnittstelle. Das Paket `health` registriert den Launcher beim Anhängen mit
 * `(activity as ComponentActivity).registerForActivityResult(...)` —
 * `FlutterActivity` erbt aber von `android.app.Activity` und ist keine
 * `ComponentActivity`.
 *
 * Die Folge war nicht ein stiller Fehlschlag beim Fragen, sondern gar keine
 * Registrierung: `GeneratedPluginRegistrant` fing eine `ClassCastException`,
 * und das ganze Plugin fehlte. Auf dem Gerät hiess das: „Freigeben" tat
 * nichts, und der Gewichtsabgleich aus Modul 14 hätte ebenso wenig
 * funktioniert.
 *
 * Gefunden am 20.09.2026 im Logcat des Honor, nicht im Test — ein Widget-Test
 * sieht die Android-Seite nicht.
 */
class MainActivity : FlutterFragmentActivity()
