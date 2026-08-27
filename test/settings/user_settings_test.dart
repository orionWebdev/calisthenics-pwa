import 'package:atem/features/settings/data/firestore_settings_repository.dart';
import 'package:atem/features/settings/domain/user_settings.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreSettingsRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreSettingsRepository(db);
  });

  Future<Map<String, dynamic>?> profile(String uid) async =>
      (await db.collection('userProfiles').doc(uid).get()).data();

  group('Einheiten', () {
    test('imperial rechnet hin und zurück', () {
      const kg = 78.0;
      final lb = UnitSystem.imperial.fromKilograms(kg);
      expect(lb, closeTo(171.96, 0.01));
      expect(UnitSystem.imperial.toKilograms(lb), closeTo(kg, 0.0001));
    });

    test('metrisch lässt die Zahl unberührt', () {
      expect(UnitSystem.metric.fromKilograms(78), 78);
      expect(UnitSystem.metric.toKilograms(78), 78);
    });

    test('Unbekanntes ist metrisch', () {
      expect(UnitSystem.fromWire(null), UnitSystem.metric);
      expect(UnitSystem.fromWire('kg'), UnitSystem.metric);
      expect(UnitSystem.fromWire('imperial'), UnitSystem.imperial);
    });
  });

  group('Sprache', () {
    test('kennt genau zwei Werte', () {
      expect(AppLanguage.values, hasLength(2));
    });

    test('Unbekanntes wird Englisch, nicht Deutsch', () {
      expect(AppLanguage.forSystem('fr'), AppLanguage.english);
      expect(AppLanguage.forSystem('de'), AppLanguage.german);
      expect(AppLanguage.forSystem('en'), AppLanguage.english);
    });

    test('ein unbekannter gespeicherter Wert zählt als nichts gewählt', () {
      expect(AppLanguage.fromCode('fr'), isNull);
      expect(AppLanguage.fromCode(null), isNull);
    });
  });

  group('Lesen', () {
    test('ein leeres Profil liefert die Vorgaben', () async {
      final settings = await repo.fetch('u1');
      expect(settings.bodyWeightKg, isNull);
      expect(settings.unitSystem, UnitSystem.metric);
      expect(settings.language, isNull, reason: 'noch nie gewählt');
      expect(settings.restSeconds, UserSettings.defaultRestSeconds);
      expect(settings.hapticsEnabled, isTrue);
    });

    test('Gewicht als Ganzzahl und als Kommazahl', () async {
      // Vertrag 4, R1: Im Bestand steht beides.
      await db.collection('userProfiles').doc('a').set({'bodyWeight': 70});
      await db.collection('userProfiles').doc('b').set({'bodyWeight': 68.5});
      expect((await repo.fetch('a')).bodyWeightKg, 70);
      expect((await repo.fetch('b')).bodyWeightKg, 68.5);
    });

    test('ein Gewicht von null zählt als nicht hinterlegt', () async {
      await db.collection('userProfiles').doc('a').set({'bodyWeight': 0});
      expect((await repo.fetch('a')).bodyWeightKg, isNull);
    });

    test('eine unsinnige Pausenzeit wird auf die Grenzen gezogen', () async {
      await db.collection('userProfiles').doc('a').set({
        'defaultRestTimer': 9999,
      });
      expect((await repo.fetch('a')).restSeconds, UserSettings.maxRestSeconds);
    });

    test('Haptik ist an, solange sie nicht ausdrücklich aus ist', () async {
      await db.collection('userProfiles').doc('a').set({'name': 'x'});
      expect((await repo.fetch('a')).hapticsEnabled, isTrue);
      await db.collection('userProfiles').doc('b')
          .set({'hapticsEnabled': false});
      expect((await repo.fetch('b')).hapticsEnabled, isFalse);
    });
  });

  group('Schreiben', () {
    test('lässt fremde Felder stehen', () async {
      await db.collection('userProfiles').doc('u1').set({
        'bodyHeight': 182,
        'trainingStyle': 'hybrid',
        'integrations': {'garmin': true},
      });

      await repo.save('u1', const UserSettings(bodyWeightKg: 78));

      final data = (await profile('u1'))!;
      expect(data['bodyWeight'], 78);
      expect(data['bodyHeight'], 182,
          reason: 'ein set ohne merge löschte die zwanzig Felder der PWA');
      expect(data['trainingStyle'], 'hybrid');
      expect(data['integrations'], {'garmin': true});
    });

    test('schreibt kein null-Gewicht', () async {
      await repo.save('u1', const UserSettings());
      expect((await profile('u1'))!.containsKey('bodyWeight'), isFalse,
          reason: 'Vertrag 4, R2: fehlend statt null');
    });

    test('schreibt keine Sprache, solange keine gewählt ist', () async {
      await repo.save('u1', const UserSettings());
      expect((await profile('u1'))!.containsKey('language'), isFalse);
    });

    test('schreibt die Feldnamen der Vorgänger-App', () async {
      await repo.save(
        'u1',
        const UserSettings(
          bodyWeightKg: 78,
          unitSystem: UnitSystem.imperial,
          language: AppLanguage.english,
          restSeconds: 120,
          hapticsEnabled: false,
        ),
      );

      final data = (await profile('u1'))!;
      expect(data['bodyWeight'], 78);
      expect(data['unitSystem'], 'imperial');
      expect(data['language'], 'en');
      expect(data['defaultRestTimer'], 120);
      expect(data['hapticsEnabled'], false);
    });

    test('geschrieben und wieder gelesen ergibt dasselbe', () async {
      const settings = UserSettings(
        bodyWeightKg: 82.5,
        unitSystem: UnitSystem.imperial,
        language: AppLanguage.german,
        restSeconds: 45,
        hapticsEnabled: false,
      );
      await repo.save('u1', settings);
      final read = await repo.fetch('u1');
      expect(read.bodyWeightKg, 82.5);
      expect(read.unitSystem, UnitSystem.imperial);
      expect(read.language, AppLanguage.german);
      expect(read.restSeconds, 45);
      expect(read.hapticsEnabled, isFalse);
    });
  });

  group('Grenzen des Gewichts', () {
    test('fangen den Vertipper', () {
      expect(UserSettings.isPlausibleWeight(780), isFalse);
      expect(UserSettings.isPlausibleWeight(7.8), isFalse);
      expect(UserSettings.isPlausibleWeight(78), isTrue);
    });
  });
}
