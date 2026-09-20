import '../../history/domain/history_timeline.dart';
import '../domain/health_session.dart';

/// Ein Eintrag der Verlaufsliste **oder** eine wartende Uhr-Einheit.
///
/// ## Warum kein weiterer Fall im `TimelineEntry`
///
/// Die naheliegende Lösung wäre ein `TimelinePending` in der versiegelten
/// Klasse. Sie schiede die Verlaufs-Domäne an die Import-Domäne — und der
/// Import liest den Verlauf bereits (`SessionPairing`). Zwei Feature-Domänen,
/// die sich gegenseitig kennen, sind ein Kreis, den man später nicht mehr
/// aufbekommt.
///
/// Die Mischung ist ohnehin eine Frage der Darstellung, nicht des Modells:
/// **Eine wartende Einheit ist kein Verlaufseintrag** — sie zählt in keiner
/// Monatssumme, in keiner Last und in keiner Lücke. Sie steht nur an
/// derselben Stelle.
sealed class ListedEntry {
  const ListedEntry();
}

final class ListedTimeline extends ListedEntry {
  const ListedTimeline(this.entry);
  final TimelineEntry entry;
}

final class ListedPending extends ListedEntry {
  const ListedPending(this.session);
  final HealthSession session;
}

/// Mischt die wartenden Uhr-Einheiten an ihrem Datum in die Verlaufsliste.
///
/// Die Liste läuft von neu nach alt. Eine wartende Einheit steht deshalb vor
/// dem ersten Eintrag, der älter ist als sie — und **nie vor einem
/// Monatskopf**: Der Kopf eröffnet seinen Monat, und eine Zeile davor gehörte
/// optisch zum Monat darüber.
///
/// Monatsköpfe bleiben unberührt. Ihre Zahlen zählen Einheiten, und eine
/// ungeprüfte ist keine.
List<ListedEntry> mergePendingIntoTimeline(
  List<TimelineEntry> entries,
  List<HealthSession> pending,
) {
  if (pending.isEmpty) {
    return [for (final e in entries) ListedTimeline(e)];
  }

  final queue = [...pending]..sort((a, b) => b.start.compareTo(a.start));
  final result = <ListedEntry>[];

  for (final entry in entries) {
    final at = _dateOf(entry);
    if (at != null) {
      while (queue.isNotEmpty && queue.first.start.isAfter(at)) {
        result.add(ListedPending(queue.removeAt(0)));
      }
    }
    result.add(ListedTimeline(entry));
  }

  // Was älter ist als jeder Eintrag — oder alles, wenn die Liste leer war.
  for (final rest in queue) {
    result.add(ListedPending(rest));
  }
  return result;
}

/// Das Datum, an dem ein Eintrag steht — `null` für alles, wovor nicht
/// eingefügt werden darf.
DateTime? _dateOf(TimelineEntry entry) => switch (entry) {
      TimelineSession(:final session) => session.date,
      // Die Lücke beginnt am Tag nach der jüngeren Einheit; eine wartende
      // Einheit innerhalb der Lücke gehört davor.
      TimelineGap(:final to) => to,
      MonthHeader() || TimelineEnd() => null,
    };
