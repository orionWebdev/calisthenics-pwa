import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../auth/application/auth_providers.dart';
import '../domain/account_export_format.dart';
import 'settings_providers.dart';

enum ExportFormat { json, csv }

/// Was am Ende dasteht: **eine Datei mit Namen**, nicht nur eine Zahl.
///
/// Der Name ist die Auskunft, nach der man später sucht — „110 Dokumente"
/// sagt nichts darüber, was im Teilen-Blatt ankam.
class ExportResult {
  const ExportResult({
    required this.documentCount,
    required this.fileName,
    required this.path,
  });

  final int documentCount;
  final String fileName;
  final String path;
}

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
class AccountExportController extends AsyncNotifier<ExportResult?> {
  @override
  ExportResult? build() => null;

  /// Der Dateiname trägt das Datum: `atem-daten-2026-08-27.json`.
  ///
  /// Board 08, A5/2. Zwei Ausgaben am selben Tag überschreiben sich — das
  /// ist gewollt; ein Zeitstempel auf die Minute genau häbe Kopien an, die
  /// niemand angefordert hat.
  static String fileNameFor(ExportFormat format, DateTime day) {
    final extension = format == ExportFormat.json ? 'json' : 'csv';
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return 'atem-daten-${day.year}-$month-$dayOfMonth.$extension';
  }

  /// Gibt die Datei noch einmal ans Teilen-Blatt — ohne sie neu zu bauen.
  Future<void> shareAgain() async {
    final result = state.value;
    if (result == null) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(result.path)]));
  }

  /// Liefert die erstellte Datei, oder `null` bei Abbruch.
  Future<ExportResult?> run(ExportFormat format) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return null;

    state = const AsyncLoading();

    try {
      final export = await ref.read(accountRepositoryProvider).export(userId);

      final content = switch (format) {
        ExportFormat.json => AccountExportFormat.toJson(export),
        ExportFormat.csv => AccountExportFormat.sessionsToCsv(export),
      };

      final directory = await getTemporaryDirectory();
      final name = fileNameFor(format, ref.read(exportDayProvider));
      final file = File('${directory.path}/$name');
      await file.writeAsString(content);

      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));

      final result = ExportResult(
        documentCount: export.documentCount,
        fileName: name,
        path: file.path,
      );
      state = AsyncData(result);
      return result;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      return null;
    }
  }

  void reset() => state = const AsyncData(null);
}

/// Der Tag im Dateinamen — überschreibbar, damit Tests einen festen Namen
/// bekommen.
final exportDayProvider = Provider<DateTime>((ref) => DateTime.now());

final accountExportProvider =
    AsyncNotifierProvider<AccountExportController, ExportResult?>(
  AccountExportController.new,
);
