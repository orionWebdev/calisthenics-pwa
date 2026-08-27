import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/account_export_format.dart';
import 'settings_providers.dart';

enum ExportFormat { json, csv }

/// Gibt den Bestand als Datei aus.
///
/// ## Warum über das Teilen-Blatt und nicht in einen Ordner
///
/// Android gibt einer App keinen Ordner, auf den der Nutzer verlässlich
/// zugreifen kann — was in `getApplicationDocumentsDirectory()` landet, ist
/// für ihn unsichtbar. Das Teilen-Blatt überlässt ihm die Wahl: Drive,
/// E-Mail an sich selbst, Dateien-App. Eine Datei, die niemand findet, ist
/// keine Datenausgabe.
///
/// Die Datei wird ins temporäre Verzeichnis geschrieben. Sie überlebt das
/// Teilen; das System räumt sie später weg. Sie dauerhaft liegenzulassen wäre
/// eine zweite Kopie der Daten auf dem Gerät, die niemand angefordert hat.
class AccountExportController extends AsyncNotifier<int?> {
  @override
  int? build() => null;

  /// Liefert die Anzahl ausgegebener Dokumente, oder `null` bei Abbruch.
  Future<int?> run(ExportFormat format) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return null;

    state = const AsyncLoading();

    try {
      final export = await ref.read(accountRepositoryProvider).export(userId);

      final (content, extension) = switch (format) {
        ExportFormat.json => (AccountExportFormat.toJson(export), 'json'),
        ExportFormat.csv => (
            AccountExportFormat.sessionsToCsv(export),
            'csv',
          ),
      };

      final directory = await getTemporaryDirectory();
      // Ein fester Name, kein Zeitstempel: Der Zeitpunkt steht ohnehin an der
      // Datei, und zwei Ausgaben am selben Tag sollen sich überschreiben
      // statt sich anzuhäufen.
      final file = File('${directory.path}/atem-export.$extension');
      await file.writeAsString(content);

      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));

      state = AsyncData(export.documentCount);
      return export.documentCount;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      return null;
    }
  }

  void reset() => state = const AsyncData(null);
}

final accountExportProvider =
    AsyncNotifierProvider<AccountExportController, int?>(
  AccountExportController.new,
);
