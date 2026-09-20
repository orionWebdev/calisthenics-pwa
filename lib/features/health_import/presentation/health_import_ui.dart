import 'package:intl/intl.dart';

import '../../../l10n/gen/app_l10n.dart';
import '../../cardio/presentation/cardio_ui.dart';
import '../domain/health_session.dart';
import '../domain/import_action.dart';

/// Die Texte, die eine Uhr-Einheit in der Oberfläche trägt.
///
/// An einer Stelle, weil Eingangszeile, Prüfblatt und Vorlesetext dieselben
/// Angaben in derselben Reihenfolge nennen müssen — sonst hört man etwas
/// anderes, als man sieht.
abstract final class HealthImportUi {
  /// „Laufen · 42 min" — oder „Aus der Uhr · 42 min", wenn die Uhr eine Art
  /// nennt, die ATEM nicht kennt.
  ///
  /// Eine blosse Dauer als Titel wäre keine Auskunft: Sie steht in der Zeile
  /// darunter ohnehin, und „58 min" sagt nicht, was es war.
  static String title(AppL10n l10n, HealthSession session) {
    final minutes = l10n.durationMinutes(session.duration.inMinutes);
    final activity = activityName(l10n, session.activity) ?? l10n.hcPairWatchRow;
    return '$activity · $minutes';
  }

  /// Nur der Tag — „So 20. Sep".
  ///
  /// Die Zeile in der Liste trägt daneben schon „Ungeprüft · zählt noch
  /// nicht"; Zeitspanne und Gerät stehen im Prüfblatt, wo man sie braucht.
  /// Drei Angaben mehr machten aus der Zeile bei 115 % Schrift einen
  /// dreizeiligen Block.
  static String day(HealthSession session, String languageTag) =>
      DateFormat('EEE d. MMM', languageTag)
          .format(session.start)
          .replaceAll('.,', '');

  /// „So 20. Sep · 09:14–09:56 · Garmin".
  static String meta(
    AppL10n l10n,
    HealthSession session,
    String languageTag,
  ) {
    final day = DateFormat('EEE d. MMM', languageTag)
        .format(session.start)
        .replaceAll('.,', '');
    final clock = DateFormat.Hm(languageTag);
    final span = '${clock.format(session.start)}–${clock.format(session.end)}';
    final device = session.deviceName;
    return [day, span, if (device != null && device.isNotEmpty) device]
        .join(' · ');
  }

  /// Die Aktivität in der Sprache der App — oder `null`, wenn ATEM sie nicht
  /// kennt. **Nicht geraten**: Eine Uhr meldet „Andere" so oft, dass ein
  /// erfundener Name mehr verwirrt als hilft. Dieselbe Zuordnung wie beim
  /// Übernehmen ([ImportAction.activityOf]) — sonst hiesse die Einheit im
  /// Blatt anders als danach im Verlauf.
  static String? activityName(AppL10n l10n, String? raw) {
    final activity = ImportAction.activityOf(raw);
    return activity == null ? null : activityLabel(l10n, activity);
  }
}
