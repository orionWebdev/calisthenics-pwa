import 'package:atem/core/widgets/atem_receipts.dart';
import 'package:flutter_test/flutter_test.dart';

/// Das Lichtbudget aus Board 18b, B — ohne Bildschirm geprüft.
void main() {
  late DateTime now;
  late AtemReceipts r;

  setUp(() {
    now = DateTime(2026, 9, 23, 12);
    r = AtemReceipts(clock: () => now);
  });

  void wait(int ms) => now = now.add(Duration(milliseconds: ms));

  test('je schneller, desto stiller: binnen 700 ms kein zweiter Bloom', () {
    expect(r.start(AtemReceipt.bloom), isNotNull);
    wait(300);
    expect(r.start(AtemReceipt.bloom), isNull);
    // Gemessen ab der letzten Auslösung, nicht ab dem letzten Bloom:
    // 500 ms nach der stillen Wahl ist es noch still, 800 ms danach nicht.
    wait(500);
    expect(r.start(AtemReceipt.bloom), isNull);
    wait(800);
    expect(r.start(AtemReceipt.bloom), isNotNull);
  });

  test('eine Kante je Gegenstand und Besuch', () {
    expect(r.start(AtemReceipt.edge, key: 'aufwärmen'), isNotNull);
    wait(5000);
    expect(r.start(AtemReceipt.edge, key: 'aufwärmen'), isNull);
    expect(r.start(AtemReceipt.edge, key: 'abkühlen'), isNotNull);
  });

  test('Bloom und Scan derselben Handlung gehören zur selben Berührung', () {
    final a = r.start(AtemReceipt.bloom);
    final b = r.start(AtemReceipt.scan);
    expect(a, b);
    expect(r.scanDelay(), const Duration(milliseconds: 280));
  });

  test('eine neue Berührung ist eine neue Nummer', () {
    final a = r.start(AtemReceipt.bloom);
    wait(900);
    final b = r.start(AtemReceipt.scan);
    expect(b, isNot(a));
    expect(r.scanDelay(), Duration.zero);
  });

  test('Fokus und Still: kein Licht', () {
    r.stage = AtemReceiptStage.focus;
    expect(r.start(AtemReceipt.bloom), isNull);
    expect(r.start(AtemReceipt.scan), isNull);
    r.stage = AtemReceiptStage.still;
    expect(r.start(AtemReceipt.edge, key: 'x'), isNull);
    // Eine im Still verworfene Kante ist nicht verbraucht.
    r.stage = AtemReceiptStage.standard;
    expect(r.start(AtemReceipt.edge, key: 'x'), isNotNull);
  });
}
