import 'package:meta/meta.dart';

import '../../history/domain/training_session.dart' show CardioActivity;
import 'training_goal.dart';

/// Die Woche von Hand — ein Vorhaben in **Wochentagen** (Board 19).
///
/// ## Kein Datum, kein Heute
///
/// Das Dokument kennt nur Wochentage. „Heute" ist [todayPlan] und wird nie
/// gespeichert; es gibt keine vorab angelegten Termine (Schreibregel 2).
///
/// ## Zwei Wochen, wenn das Briefing es sagt
///
/// [a] gilt immer. [b] gibt es nur, wenn die Trainingsangaben
/// „zwei Wochen im Wechsel" sagen; welche Kalenderwoche A oder B ist, liest
/// die Woche aus dem Anker im Briefing — sie spiegelt ihn nie (Regel 6).
/// Geht das Briefing zurück auf „jede Woche gleich", bleibt [b] gespeichert,
/// gilt aber nicht (Board 19, Entscheidung 10).
@immutable
class WeekPlan {
  const WeekPlan({
    this.a = const {},
    this.b = const {},
    this.updatedAt,
  });

  static const empty = WeekPlan();

  /// Woche A, je Eintragskennung.
  final Map<String, WeekEntry> a;

  /// Woche B — nur bei Wechselwochen in Gebrauch.
  final Map<String, WeekEntry> b;

  final DateTime? updatedAt;

  bool get isEmpty => a.isEmpty && b.isEmpty;

  Map<String, WeekEntry> of(WeekSide side) => side == WeekSide.a ? a : b;

  /// Die Einträge eines Tages in ihrer Reihenfolge: nach Tageszeit (morgens →
  /// mittags → abends → ohne), dann nach [WeekEntry.order].
  List<WeekEntry> day(WeekSide side, int weekday) {
    final list = [
      for (final e in of(side).values)
        if (e.weekday == weekday) e,
    ]..sort(WeekEntry.compare);
    return list;
  }

  WeekPlan put(WeekSide side, WeekEntry entry) =>
      _with(side, {...of(side), entry.id: entry});

  WeekPlan remove(WeekSide side, String id) =>
      _with(side, {...of(side)}..remove(id));

  WeekPlan clear(WeekSide side) => _with(side, const {});

  WeekPlan _with(WeekSide side, Map<String, WeekEntry> entries) =>
      side == WeekSide.a
          ? WeekPlan(a: entries, b: b, updatedAt: updatedAt)
          : WeekPlan(a: a, b: entries, updatedAt: updatedAt);

  // --- Handlungen ----------------------------------------------------------
  //
  // Jede gibt den nächsten Stand zurück und die Feldpfade, die dafür
  // geschrieben werden müssen (Schreibregel 1: Feld-Update, kein Array).

  /// Legt [entry] an. **„Frei" ist exklusiv** (Regel 3): Ein Training auf
  /// einem freien Tag löscht das „Frei" im selben Schreibvorgang; ein
  /// „Frei" auf einem belegten Tag gibt es nicht.
  WeekChange add(WeekSide side, WeekEntry entry) {
    final sameDay = day(side, entry.weekday);
    if (entry.kind == WeekKind.off && sameDay.isNotEmpty) {
      throw StateError('„Frei" nur an Tagen ohne Eintrag');
    }
    final replaced = [
      for (final e in sameDay)
        if (e.kind == WeekKind.off) e,
    ];
    var next = this;
    for (final off in replaced) {
      next = next.remove(side, off.id);
    }
    final ordered = entry.copyWith(order: _nextOrder(next, side, entry));
    next = next.put(side, ordered);
    return WeekChange(
      next: next,
      writes: {
        _path(side, ordered.id): ordered.toStored(),
        for (final off in replaced) _path(side, off.id): null,
      },
      replacedOff: replaced.isNotEmpty,
    );
  }

  /// Verschiebt auf einen anderen Wochentag. Schreibt nur `weekday` und
  /// `order` — sonst nichts (Regel 1). Ein „Frei" am Zieltag weicht.
  WeekChange move(WeekSide side, String id, int weekday) {
    final entry = of(side)[id];
    if (entry == null || entry.weekday == weekday) {
      return WeekChange(next: this, writes: const {});
    }
    final target = day(side, weekday);
    if (entry.kind == WeekKind.off && target.isNotEmpty) {
      throw StateError('„Frei" nur an Tagen ohne Eintrag');
    }
    final replaced = [
      for (final e in target)
        if (e.kind == WeekKind.off) e,
    ];
    var next = this;
    for (final off in replaced) {
      next = next.remove(side, off.id);
    }
    final moved = entry.copyWith(
      weekday: weekday,
      order: _nextOrder(next, side, entry.copyWith(weekday: weekday)),
    );
    next = next.put(side, moved);
    return WeekChange(
      next: next,
      writes: {
        '${_path(side, id)}.weekday': weekday,
        '${_path(side, id)}.order': moved.order,
        for (final off in replaced) _path(side, off.id): null,
      },
      replacedOff: replaced.isNotEmpty,
    );
  }

  /// Ändert einen Eintrag an seinem Platz.
  WeekChange edit(WeekSide side, WeekEntry entry) => WeekChange(
        next: put(side, entry),
        writes: _entryWrites(side, of(side)[entry.id], entry),
      );

  /// Was geschrieben werden muss, um [old] zu [now] zu machen — **Feld für
  /// Feld**. Ein ganzer Eintrag mit `merge` löschte keine Felder, die
  /// wegfallen: Wer den Plan von einem Eintrag nimmt, behielte sonst die
  /// alte `planId`. Neue Einträge werden als Ganzes geschrieben.
  static Map<String, Object?> _entryWrites(
      WeekSide side, WeekEntry? old, WeekEntry? now) {
    final id = (now ?? old)!.id;
    if (now == null) return {_path(side, id): null};
    if (old == null) return {_path(side, id): now.toStored()};
    final before = old.toStored();
    final after = now.toStored();
    return {
      for (final k in {...before.keys, ...after.keys})
        if (before[k] != after[k]) '${_path(side, id)}.$k': after[k],
    };
  }

  WeekChange delete(WeekSide side, String id) => WeekChange(
        next: remove(side, id),
        writes: {_path(side, id): null},
      );

  /// „Woche leeren": die sichtbare Woche, ein Vorgang (Regel 5).
  ///
  /// Geschrieben wird die Löschung der ganzen Map — ein leeres `{}` mit
  /// `merge` entfernte in Firestore nichts.
  WeekChange clearAll(WeekSide side) => WeekChange(
        next: clear(side),
        writes: {'${side.name}.entries': null},
      );

  /// Stellt einen früheren Stand eines Tages wieder her — für „Rückgängig".
  WeekChange restore(WeekSide side, WeekPlan before, Iterable<String> ids) {
    var next = this;
    final writes = <String, Object?>{};
    for (final id in ids) {
      final old = before.of(side)[id];
      if (of(side)[id] != null || old != null) {
        writes.addAll(_entryWrites(side, of(side)[id], old));
      }
      next = old == null ? next.remove(side, id) : next.put(side, old);
    }
    return WeekChange(next: next, writes: writes);
  }

  static String _path(WeekSide side, String id) =>
      '${side.name}.entries.$id';

  /// Hinten anhängen: innerhalb derselben Tageszeit ans Ende.
  static int _nextOrder(WeekPlan plan, WeekSide side, WeekEntry entry) {
    var max = -1;
    for (final e in plan.day(side, entry.weekday)) {
      if (e.id != entry.id && e.daypart == entry.daypart && e.order > max) {
        max = e.order;
      }
    }
    return max + 1;
  }

  /// Liest das gespeicherte Dokument; Zeitstempel schon als [DateTime].
  /// Unbekanntes wird übergangen, nie repariert.
  factory WeekPlan.fromStored(Map<String, Object?> data) {
    Map<String, WeekEntry> side(Object? raw) {
      if (raw is! Map) return const {};
      final entries = raw['entries'];
      if (entries is! Map) return const {};
      return {
        for (final e in entries.entries)
          if (e.value is Map)
            if (WeekEntry.fromStored('${e.key}',
                    (e.value as Map).cast<String, Object?>())
                case final entry?)
              entry.id: entry,
      };
    }

    final updated = data['updatedAt'];
    return WeekPlan(
      a: side(data['a']),
      b: side(data['b']),
      updatedAt: updated is DateTime ? updated : null,
    );
  }
}

/// Woche A oder B.
enum WeekSide { a, b }

/// Was ein Eintrag ist. „Frei" ist eine Aussage, eine Lücke nicht
/// (Board 19, F3).
enum WeekKind { strength, cardio, off }

enum WeekDaypart { morning, midday, evening }

/// Ein Eintrag der Woche.
@immutable
class WeekEntry {
  const WeekEntry({
    required this.id,
    required this.weekday,
    required this.kind,
    this.planId,
    this.planName,
    this.activity,
    this.durationMin,
    this.daypart,
    this.order = 0,
    this.createdAt,
  });

  final String id;

  /// ISO-Wochentag, Montag = 1.
  final int weekday;
  final WeekKind kind;

  /// Nur Kraft. Fehlt: ohne Plan.
  final String? planId;

  /// Schnappschuss des Plannamens — damit ein gelöschter Plan nicht
  /// namenlos wird (Regel 4).
  final String? planName;

  /// Nur Cardio, dort Pflicht.
  final CardioActivity? activity;

  /// Nur Cardio, 10–240.
  final int? durationMin;

  /// Nicht bei „Frei".
  final WeekDaypart? daypart;

  final int order;
  final DateTime? createdAt;

  static int compare(WeekEntry x, WeekEntry y) {
    int dp(WeekEntry e) => e.daypart?.index ?? 3;
    final byDaypart = dp(x).compareTo(dp(y));
    return byDaypart != 0 ? byDaypart : x.order.compareTo(y.order);
  }

  WeekEntry copyWith({int? weekday, int? order}) => WeekEntry(
        id: id,
        weekday: weekday ?? this.weekday,
        kind: kind,
        planId: planId,
        planName: planName,
        activity: activity,
        durationMin: durationMin,
        daypart: daypart,
        order: order ?? this.order,
        createdAt: createdAt,
      );

  Map<String, Object?> toStored() => {
        'weekday': weekday,
        'kind': kind.name,
        if (planId != null) 'planId': planId,
        if (planName != null) 'planName': planName,
        if (activity != null) 'activity': activity!.wire,
        if (durationMin != null) 'durationMin': durationMin,
        if (daypart != null) 'daypart': daypart!.name,
        'order': order,
      };

  static WeekEntry? fromStored(String id, Map<String, Object?> d) {
    final weekday = d['weekday'];
    final kind = WeekKind.values.asNameMap()[d['kind']];
    if (weekday is! num || weekday < 1 || weekday > 7 || kind == null) {
      return null;
    }
    final activity = CardioActivity.values
        .where((a) => a.wire == d['activity'])
        .firstOrNull;
    if (kind == WeekKind.cardio && activity == null) return null;
    final minutes = d['durationMin'];
    final created = d['createdAt'];
    return WeekEntry(
      id: id,
      weekday: weekday.toInt(),
      kind: kind,
      planId: kind == WeekKind.strength && d['planId'] is String
          ? d['planId'] as String
          : null,
      planName: d['planName'] is String ? d['planName'] as String : null,
      activity: kind == WeekKind.cardio ? activity : null,
      durationMin: kind == WeekKind.cardio &&
              minutes is num &&
              minutes >= 10 &&
              minutes <= 240
          ? minutes.toInt()
          : null,
      daypart: kind == WeekKind.off
          ? null
          : WeekDaypart.values.asNameMap()[d['daypart']],
      order: d['order'] is num ? (d['order'] as num).toInt() : 0,
      createdAt: created is DateTime ? created : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WeekEntry &&
      other.id == id &&
      _mapEq(other.toStored(), toStored());

  @override
  int get hashCode => Object.hash(id, weekday, kind, planId, order);

  static bool _mapEq(Map<String, Object?> x, Map<String, Object?> y) =>
      x.length == y.length && x.keys.every((k) => x[k] == y[k]);
}

/// Ergebnis einer Handlung: der nächste Stand und was zu schreiben ist.
@immutable
class WeekChange {
  const WeekChange({
    required this.next,
    required this.writes,
    this.replacedOff = false,
  });

  final WeekPlan next;

  /// Feldpfad → Wert; `null` löscht.
  final Map<String, Object?> writes;

  /// Ein „Frei" ist gewichen — die Snackbar sagt es.
  final bool replacedOff;

}

/// Welche Woche an [date] gilt: B nur bei Wechselwochen, sonst A.
WeekSide weekSideOn(DateTime date, TrainingGoal goal) =>
    goal.isWeekA(date) == false ? WeekSide.b : WeekSide.a;

/// Ein Element von „heute".
@immutable
class TodayItem {
  const TodayItem({
    required this.kind,
    required this.source,
    this.entry,
    this.appointmentId,
    this.appointmentTitle,
    this.appointmentPlanId,
  });

  final WeekKind kind;

  /// Woher es kommt — steht bei jedem Element dabei (Board 19, F2).
  final TodaySource source;

  /// Der Eintrag der Woche, wenn [source] die Woche ist.
  final WeekEntry? entry;

  /// Der Termin aus dem Bestand, wenn [source] ein Termin ist.
  final String? appointmentId;
  final String? appointmentTitle;
  final String? appointmentPlanId;
}

enum TodaySource { week, appointment }

/// Ein Termin aus dem Bestand (`schedule`) für heute — nur Kraft.
@immutable
class TodayAppointment {
  const TodayAppointment({required this.id, required this.title, this.planId});

  final String id;
  final String title;
  final String? planId;
}

/// **Die eine Ableitung von „heute"** (Board 19, E).
///
/// Hybrid-Widget und Kraft-Tab lesen dieselbe Liste; der Kraft-Tab filtert
/// nur auf Kraft. Am ersten Tag mit beiden Quellen sagen sie dasselbe, weil
/// sie dieselbe Liste lesen — nicht zwei ähnliche.
///
/// **Termin schlägt Rhythmus — je Spur, nicht je Tag** (Entscheidung 7):
/// `schedule` kennt nur Kraft. Ein Termin ersetzt die Kraft-Einträge und ein
/// „Frei"; der Morgenlauf bleibt.
List<TodayItem> todayPlan(
  DateTime date, {
  required WeekPlan week,
  required TrainingGoal goal,
  List<TodayAppointment> appointments = const [],
}) {
  final rhythm = week.day(weekSideOn(date, goal), date.weekday);
  if (appointments.isEmpty) {
    return [
      for (final e in rhythm)
        TodayItem(kind: e.kind, source: TodaySource.week, entry: e),
    ];
  }
  return [
    for (final e in rhythm)
      if (e.kind == WeekKind.cardio)
        TodayItem(kind: e.kind, source: TodaySource.week, entry: e),
    for (final a in appointments)
      TodayItem(
        kind: WeekKind.strength,
        source: TodaySource.appointment,
        appointmentId: a.id,
        appointmentTitle: a.title,
        appointmentPlanId: a.planId,
      ),
  ];
}
