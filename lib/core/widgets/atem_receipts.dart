import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Die drei Stufen der Bewegungsgrammatik (Board 18b, B).
enum AtemReceiptStage {
  /// Alle Bildschirme: die Grammatik, wie in Board 18b A.
  standard,

  /// Der Runner: Jede Quittung ist ein Zustand, keine Bewegung. Gedrückt,
  /// Häkchen, zurücktretende Zeile, Haptik und Uhr — kein Licht.
  focus,

  /// „Animationen reduzieren": Zustände springen, Inhalt läuft weiter.
  still,
}

/// Die Arten von Licht, die eine Quittung sein können.
enum AtemReceipt { bloom, edge, scan }

/// Das Gedächtnis der Quittungen einer Route.
///
/// ## Kein Baustein entscheidet selbst, ob er leuchtet
///
/// Ein Chip weiss nicht, ob gerade ein anderer geblüht hat, ob man im Runner
/// ist oder ob dieselbe Disclosure vorhin schon ihre Kante hatte. Das weiss
/// nur die Route. Deshalb fragt jede Quittung hier, bevor sie läuft — und
/// hält sich an die Antwort (Board 18b, B und Lichtbudget).
///
/// ## Die jüngste Berührung gewinnt
///
/// Jede Quittung meldet sich mit [start] an und bekommt die Nummer der
/// Berührung, zu der sie gehört. Was binnen [_sameTouch] startet, gehört zur
/// selben — so laufen Bloom und Scan derselben Wahl zusammen. Kommt eine neue
/// Berührung, steigt [touch], und alles Ältere springt in seine Ruhelage,
/// statt auszublenden (Lichtbudget 02).
class AtemReceipts {
  AtemReceipts({this.stage = AtemReceiptStage.standard, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  AtemReceiptStage stage;
  final DateTime Function() _clock;

  static const _sameTouch = Duration(milliseconds: 120);

  /// Die Nummer der jüngsten Berührung. Laufende Quittungen hören darauf.
  final touch = ValueNotifier<int>(0);

  DateTime? _touchAt;
  final _lastOf = <AtemReceipt, DateTime>{};
  DateTime? _bloomAt;
  final _seenEdges = <Object>{};

  bool get lit => stage == AtemReceiptStage.standard;

  /// Meldet eine Quittung an. Rückgabe: die Nummer ihrer Berührung — oder
  /// `null`, wenn sie nicht leuchten darf. [key] macht eine Kante einmalig je
  /// Gegenstand und Besuch; eine zweite wird verworfen, nicht vertagt.
  int? start(AtemReceipt kind, {Object? key}) {
    if (!lit) return null;
    final now = _clock();
    final last = _lastOf[kind];
    _lastOf[kind] = now;

    // Je schneller, desto stiller (Lichtbudget 03): dieselbe Art binnen
    // 700 ms nach der letzten Auslösung → nur Kern / Häkchen und Raste.
    if (kind == AtemReceipt.bloom &&
        last != null &&
        now.difference(last) < AtemMotion.tempoWindow) {
      _join(now);
      return null;
    }
    if (kind == AtemReceipt.edge && key != null && !_seenEdges.add(key)) {
      return null;
    }
    if (kind == AtemReceipt.bloom) _bloomAt = now;
    return _join(now);
  }

  /// Wie lange ein Scan warten soll: 280 ms, wenn ein Bloom derselben
  /// Handlung gerade blüht — zwei Aussagen an zwei Orten, nacheinander.
  Duration scanDelay() {
    final at = _bloomAt;
    if (at == null) return Duration.zero;
    return _clock().difference(at) < _sameTouch
        ? AtemMotion.dScanAfterBloom
        : Duration.zero;
  }

  /// Hat diese Kante hier schon einmal geleuchtet?
  bool seen(Object key) => _seenEdges.contains(key);

  int _join(DateTime now) {
    final at = _touchAt;
    if (at == null || now.difference(at) > _sameTouch) touch.value++;
    _touchAt = now;
    return touch.value;
  }

  void dispose() => touch.dispose();
}

/// Setzt die Stufe für eine Route und hält ihr Gedächtnis.
///
/// Ohne Scope gilt eine gemeinsame Standard-Instanz — Bausteine
/// funktionieren also auch in Tests und Vorschauen ohne Aufbau. Die Stufe
/// **Still** setzt sich aus „Animationen reduzieren" selbst, jede andere
/// Angabe wird dann überstimmt.
class AtemReceiptScope extends StatefulWidget {
  const AtemReceiptScope({
    super.key,
    this.stage = AtemReceiptStage.standard,
    required this.child,
  });

  final AtemReceiptStage stage;
  final Widget child;

  static final _fallback = AtemReceipts();

  /// Das Gedächtnis der umgebenden Route, mit der Stufe, die jetzt gilt.
  static AtemReceipts of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ReceiptInherited>();
    final receipts = scope?.receipts ?? _fallback;
    receipts.stage = AtemMotion.reduced(context)
        ? AtemReceiptStage.still
        : (scope?.stage ?? AtemReceiptStage.standard);
    return receipts;
  }

  @override
  State<AtemReceiptScope> createState() => _AtemReceiptScopeState();
}

class _AtemReceiptScopeState extends State<AtemReceiptScope> {
  final _receipts = AtemReceipts();

  @override
  void dispose() {
    _receipts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ReceiptInherited(
        receipts: _receipts,
        stage: widget.stage,
        child: widget.child,
      );
}

class _ReceiptInherited extends InheritedWidget {
  const _ReceiptInherited({
    required this.receipts,
    required this.stage,
    required super.child,
  });

  final AtemReceipts receipts;
  final AtemReceiptStage stage;

  @override
  bool updateShouldNotify(_ReceiptInherited old) => old.stage != stage;
}

/// Hilfe für Quittungen mit eigenem Controller: springt in die Ruhelage,
/// sobald eine jüngere Berührung kommt.
mixin AtemReceiptListener<T extends StatefulWidget> on State<T> {
  AtemReceipts? _receipts;
  int? _mine;

  /// Aufrufen, wenn die Quittung startet.
  void listenForNewerTouch(AtemReceipts receipts, int touch) {
    _receipts?.touch.removeListener(_onTouch);
    _receipts = receipts;
    _mine = touch;
    receipts.touch.addListener(_onTouch);
  }

  void _onTouch() {
    if (_receipts!.touch.value != _mine) {
      _receipts!.touch.removeListener(_onTouch);
      _receipts = null;
      onNewerTouch();
    }
  }

  /// Die Quittung in ihre Ruhelage setzen.
  void onNewerTouch();

  @override
  void dispose() {
    _receipts?.touch.removeListener(_onTouch);
    super.dispose();
  }
}
