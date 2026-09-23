import 'package:meta/meta.dart';

/// Die Trainingsangaben — was jemand über sein Training sagt (Board 18).
///
/// ## Es gibt kein Briefing als Ganzes
///
/// Nur einzelne Antworten, jede mit eigenem Datum (Board 18, F1). Kein
/// „vollständig", keine Schwelle, kein Status: Eine Antwort gilt ab dem
/// Moment, in dem sie gegeben ist, eine offene gilt nicht.
///
/// ## Offen ist keine Null
///
/// Jedes Feld ist `null`, solange es nicht beantwortet ist — auch die
/// Mengen: Eine leere Menge gibt es nicht, sie wird zu `null`. Die einzige
/// Null, die das Briefing erzeugt, ist die gesagte: Wer „nur Kraft" wählt,
/// hat kein Cardio angegeben, und [lanes] enthält es nicht.
///
/// ## Geschrieben wird die Differenz
///
/// Jede Handlung berechnet einen neuen Zustand; gespeichert wird genau, was
/// sich gegenüber dem alten unterscheidet ([diff]). Zurücknehmen, abhängiges
/// Entfernen und „Rückgängig" sind damit derselbe Weg — keiner braucht eine
/// eigene Schreiblogik, die mit den anderen auseinanderlaufen kann.
@immutable
class TrainingGoal {
  const TrainingGoal({
    this.lanes,
    this.weekPattern,
    this.anchorWeekStart,
    this.perWeek = const Lanes(),
    this.perWeekB = const Lanes(),
    this.schedule,
    this.days = const Lanes(),
    this.multiPerDay,
    this.dayparts = const Lanes(),
    this.places,
    this.goals,
    this.describes,
    this.answeredAt = const {},
    this.updatedAt,
  });

  static const empty = TrainingGoal();

  /// Liest das gespeicherte Dokument — verschachtelt wie in Firestore, die
  /// Zeitstempel schon als [DateTime].
  ///
  /// **Unbekanntes wird übergangen, nie repariert.** Ein Wert aus einer
  /// späteren Fassung („`weekPattern: 'seasonal'`") liest sich als offen;
  /// solange niemand die Frage anfasst, schreibt [diff] ihn auch nicht weg.
  /// Eine Anzahl ausserhalb 1–8 ist keine Antwort, eine leere Liste auch
  /// nicht.
  factory TrainingGoal.fromStored(Map<String, Object?> data) {
    E? one<E extends Enum>(List<E> values, Object? raw) =>
        raw is String ? values.asNameMap()[raw] : null;
    Set<E>? many<E extends Enum>(List<E> values, Object? raw) {
      if (raw is! List) return null;
      final out = <E>{
        for (final r in raw)
          if (one(values, r) case final e?) e,
      };
      return out.isEmpty ? null : out;
    }

    Map<String, Object?> sub(String key) {
      final raw = data[key];
      return raw is Map ? raw.cast<String, Object?>() : const {};
    }

    int? count(Object? raw) {
      if (raw is! num) return null;
      final n = raw.toInt();
      return n >= 1 && n <= 8 ? n : null;
    }

    Set<int>? weekdays(Object? raw) {
      if (raw is! List) return null;
      final out = {
        for (final r in raw)
          if (r is num && r >= 1 && r <= 7) r.toInt(),
      };
      return out.isEmpty ? null : out;
    }

    Lanes<T> lanes<T>(String key, T? Function(Object?) read) {
      final m = sub(key);
      return Lanes(strength: read(m['strength']), cardio: read(m['cardio']));
    }

    final answered = <String, DateTime>{};
    void flatten(String prefix, Object? node) {
      if (node is DateTime) {
        answered[prefix] = node;
      } else if (node is Map) {
        for (final e in node.entries) {
          flatten(prefix.isEmpty ? '${e.key}' : '$prefix.${e.key}', e.value);
        }
      }
    }

    flatten('', data['answeredAt']);

    final anchorRaw = data['anchorWeekStart'];
    final anchor = anchorRaw is String ? DateTime.tryParse(anchorRaw) : null;
    final updated = data['updatedAt'];

    return TrainingGoal(
      lanes: many(Lane.values, data['modalities']),
      weekPattern: one(WeekPattern.values, data['weekPattern']),
      anchorWeekStart: anchor == null ? null : mondayOf(anchor),
      perWeek: lanes('perWeek', count),
      perWeekB: lanes('perWeekB', count),
      schedule: one(DaySchedule.values, data['schedule']),
      days: lanes('days', weekdays),
      multiPerDay: one(MultiPerDay.values, data['multiPerDay']),
      dayparts: lanes('dayparts', (r) => many(Daypart.values, r)),
      places: many(Place.values, data['places']),
      goals: many(TrainingAim.values, data['goals']),
      describes: one(Describes.values, data['describes']),
      answeredAt: answered,
      updatedAt: updated is DateTime ? updated : null,
    );
  }

  /// Frage 1. `null` = offen.
  final Set<Lane>? lanes;

  /// Frage 2.
  final WeekPattern? weekPattern;

  /// Der Montag einer Woche A. Nur bei [WeekPattern.alternating].
  final DateTime? anchorWeekStart;

  /// Frage 3: Einheiten je Woche, 1–8, `8` heisst „8+". Keine 0: Wer 0
  /// meint, hat die Art in Frage 1 nicht gewählt.
  final Lanes<int> perWeek;

  /// Dasselbe für Woche B.
  final Lanes<int> perWeekB;

  /// Frage 4.
  final DaySchedule? schedule;

  /// ISO-Wochentage 1–7 je Art. Nur bei [DaySchedule.fixed].
  final Lanes<Set<int>> days;

  /// Frage 5.
  final MultiPerDay? multiPerDay;

  /// Tageszeiten je Art. Nur bei [MultiPerDay.some] oder [MultiPerDay.most].
  final Lanes<Set<Daypart>> dayparts;

  /// Frage 6, Mehrfachwahl.
  final Set<Place>? places;

  /// Frage 7, Mehrfachwahl. **Ungeordnet** — die Reihenfolge ist keine
  /// Rangfolge (Board 18, Entscheidung 19).
  final Set<TrainingAim>? goals;

  /// Frage 8.
  final Describes? describes;

  /// Wann welche Antwort gegeben wurde, je Feldpfad aus [paths].
  final Map<String, DateTime> answeredAt;

  /// Wann zuletzt irgendetwas geschrieben wurde.
  final DateTime? updatedAt;

  bool get hasStrength => lanes?.contains(Lane.strength) ?? false;
  bool get hasCardio => lanes?.contains(Lane.cardio) ?? false;

  bool includes(Lane lane) => lanes?.contains(lane) ?? false;

  /// Ob irgendeine Frage beantwortet ist.
  bool get hasAny => fields.isNotEmpty;

  /// Alle Feldpfade, die es geben kann, in Schreibreihenfolge.
  static const paths = [
    'modalities',
    'weekPattern',
    'anchorWeekStart',
    'perWeek.strength',
    'perWeek.cardio',
    'perWeekB.strength',
    'perWeekB.cardio',
    'schedule',
    'days.strength',
    'days.cardio',
    'multiPerDay',
    'dayparts.strength',
    'dayparts.cardio',
    'places',
    'goals',
    'describes',
  ];

  /// Die beantworteten Felder als Pfad → Wert in Speicherform.
  ///
  /// Mengen werden sortiert geschrieben, damit derselbe Inhalt immer
  /// dieselbe Liste ist und [diff] keinen Unterschied erfindet.
  Map<String, Object> get fields {
    final out = <String, Object>{};
    void put(String path, Object? value) {
      if (value != null) out[path] = value;
    }

    put('modalities', lanes == null ? null : _sortedNames(lanes!, Lane.values));
    put('weekPattern', weekPattern?.name);
    put('anchorWeekStart',
        anchorWeekStart == null ? null : formatDay(anchorWeekStart!));
    for (final lane in Lane.values) {
      put('perWeek.${lane.name}', perWeek[lane]);
      put('perWeekB.${lane.name}', perWeekB[lane]);
      final d = days[lane];
      put('days.${lane.name}', d == null ? null : (d.toList()..sort()));
      final p = dayparts[lane];
      put('dayparts.${lane.name}',
          p == null ? null : _sortedNames(p, Daypart.values));
    }
    put('schedule', schedule?.name);
    put('multiPerDay', multiPerDay?.name);
    put('places', places == null ? null : _sortedNames(places!, Place.values));
    put('goals',
        goals == null ? null : _sortedNames(goals!, TrainingAim.values));
    put('describes', describes?.name);
    return out;
  }

  /// Was geschrieben werden muss, um von `this` nach [next] zu kommen.
  ///
  /// Ein Pfad mit `null` wird gelöscht — **samt seinem `answeredAt`**
  /// (Board 18, Schreibregel 1). Unveränderte Pfade fehlen.
  Map<String, Object?> diff(TrainingGoal next) {
    final before = fields;
    final after = next.fields;
    final out = <String, Object?>{};
    for (final path in paths) {
      final a = before[path];
      final b = after[path];
      if (b == null) {
        if (a != null) out[path] = null;
      } else if (!_same(a, b)) {
        out[path] = b;
      }
    }
    return out;
  }

  // --- Antworten -----------------------------------------------------------
  //
  // Jede Methode gibt den vollständigen nächsten Zustand zurück, samt allem,
  // was mit der Antwort wegfällt (Schreibregel 2). Was weggefallen ist,
  // meldet [removedBy].

  /// Frage 1. `null` nimmt die Antwort zurück.
  TrainingGoal withLanes(Set<Lane>? value) {
    var next = _copy(lanes: _orNull(value));
    for (final lane in Lane.values) {
      if (!next.includes(lane)) next = next._withoutLane(lane);
    }
    // Ohne Art hängt auch „feste Tage" in der Luft: Die Frage ist dann
    // nicht sichtbar, und eine unsichtbare Antwort sickerte in eine spätere
    // Ableitung durch.
    if (next.lanes == null) next = next._copy(schedule: _clear);
    return next;
  }

  /// Frage 2.
  TrainingGoal withWeekPattern(WeekPattern? value) {
    var next = _copy(weekPattern: value ?? _clear);
    if (value != WeekPattern.alternating) {
      next = next._copy(anchorWeekStart: _clear, perWeekB: const Lanes());
    }
    return next;
  }

  /// „Diese Woche ist A" oder „B". Gespeichert wird der Montag einer Woche A.
  TrainingGoal withCurrentWeek({required bool isA, required DateTime today}) {
    final monday = mondayOf(today);
    final anchor = isA ? monday : monday.subtract(const Duration(days: 7));
    return _copy(anchorWeekStart: anchor);
  }

  TrainingGoal withPerWeek(Lane lane, int? n, {bool weekB = false}) {
    assert(n == null || (n >= 1 && n <= 8));
    return weekB
        ? _copy(perWeekB: perWeekB.put(lane, n))
        : _copy(perWeek: perWeek.put(lane, n));
  }

  /// Frage 3 zurücknehmen: alle Anzahlen, Woche A und B.
  TrainingGoal withoutPerWeek() =>
      _copy(perWeek: const Lanes(), perWeekB: const Lanes());

  /// Frage 4.
  TrainingGoal withSchedule(DaySchedule? value) {
    var next = _copy(schedule: value ?? _clear);
    if (value != DaySchedule.fixed) next = next._copy(days: const Lanes());
    return next;
  }

  TrainingGoal withDays(Lane lane, Set<int>? value) =>
      _copy(days: days.put(lane, _orNull(value)));

  /// Frage 5.
  TrainingGoal withMultiPerDay(MultiPerDay? value) {
    var next = _copy(multiPerDay: value ?? _clear);
    if (value == null || value == MultiPerDay.no) {
      next = next._copy(dayparts: const Lanes());
    }
    return next;
  }

  TrainingGoal withDayparts(Lane lane, Set<Daypart>? value) =>
      _copy(dayparts: dayparts.put(lane, _orNull(value)));

  TrainingGoal withPlaces(Set<Place>? value) =>
      _copy(places: _orNull(value) ?? _clear);

  TrainingGoal withGoals(Set<TrainingAim>? value) =>
      _copy(goals: _orNull(value) ?? _clear);

  TrainingGoal withDescribes(Describes? value) =>
      _copy(describes: value ?? _clear);

  /// Was eine Antwort mitgenommen hat — für die Snackbar. `null`, wenn
  /// nichts weggefallen ist: Dann gibt es keine Snackbar (Board 18, C 2).
  static Removal? removedBy(TrainingGoal before, TrainingGoal after) {
    final gone = <Lane>[
      for (final lane in Lane.values)
        if (before.includes(lane) &&
            !after.includes(lane) &&
            before._laneHasDetails(lane))
          lane,
    ];
    if (gone.isNotEmpty) return LaneRemoval(gone);
    if (before.perWeekB.any && after.perWeekB.isEmpty ||
        before.anchorWeekStart != null && after.anchorWeekStart == null) {
      return const WeekBRemoval();
    }
    if (before.days.any && after.days.isEmpty) return const DaysRemoval();
    if (before.dayparts.any && after.dayparts.isEmpty) {
      return const DaypartsRemoval();
    }
    return null;
  }

  // --- Ableitungen für die Anzeige ----------------------------------------

  /// Ob diese Kalenderwoche nach dem Anker eine Woche A ist.
  bool? isWeekA(DateTime today) {
    final anchor = anchorWeekStart;
    if (weekPattern != WeekPattern.alternating || anchor == null) return null;
    final weeks = mondayOf(today).difference(mondayOf(anchor)).inDays ~/ 7;
    return weeks.isEven;
  }

  /// Wann das Feld hinter [path] zuletzt beantwortet wurde. Für eine Frage
  /// mit mehreren Pfaden der jüngste.
  DateTime? answeredAtOf(Iterable<String> pathsOfQuestion) {
    DateTime? latest;
    for (final p in pathsOfQuestion) {
      final t = answeredAt[p];
      if (t != null && (latest == null || t.isAfter(latest))) latest = t;
    }
    return latest;
  }

  bool _laneHasDetails(Lane lane) =>
      perWeek[lane] != null ||
      perWeekB[lane] != null ||
      days[lane] != null ||
      dayparts[lane] != null;

  TrainingGoal _withoutLane(Lane lane) => _copy(
        perWeek: perWeek.put(lane, null),
        perWeekB: perWeekB.put(lane, null),
        days: days.put(lane, null),
        dayparts: dayparts.put(lane, null),
      );

  TrainingGoal _copy({
    Object? lanes = _keep,
    Object? weekPattern = _keep,
    Object? anchorWeekStart = _keep,
    Lanes<int>? perWeek,
    Lanes<int>? perWeekB,
    Object? schedule = _keep,
    Lanes<Set<int>>? days,
    Object? multiPerDay = _keep,
    Lanes<Set<Daypart>>? dayparts,
    Object? places = _keep,
    Object? goals = _keep,
    Object? describes = _keep,
  }) {
    T? pick<T>(Object? v, T? old) =>
        identical(v, _keep) ? old : (identical(v, _clear) ? null : v as T?);
    return TrainingGoal(
      lanes: pick(lanes, this.lanes),
      weekPattern: pick(weekPattern, this.weekPattern),
      anchorWeekStart: pick(anchorWeekStart, this.anchorWeekStart),
      perWeek: perWeek ?? this.perWeek,
      perWeekB: perWeekB ?? this.perWeekB,
      schedule: pick(schedule, this.schedule),
      days: days ?? this.days,
      multiPerDay: pick(multiPerDay, this.multiPerDay),
      dayparts: dayparts ?? this.dayparts,
      places: pick(places, this.places),
      goals: pick(goals, this.goals),
      describes: pick(describes, this.describes),
      answeredAt: answeredAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TrainingGoal && diff(other).isEmpty;

  @override
  int get hashCode => Object.hashAll(
      [for (final e in fields.entries) '${e.key}=${e.value}']);

  @override
  String toString() => 'TrainingGoal($fields)';
}

/// Die beiden Spuren, nach denen gefragt wird.
enum Lane { strength, cardio }

enum WeekPattern { same, alternating, irregular }

enum DaySchedule { fixed, free }

enum MultiPerDay { no, some, most }

enum Daypart { morning, midday, evening }

enum Place { home, gym, outdoor }

/// Worauf jemand hintrainiert. Kein `Goal`, weil das nach Sollwert klingt —
/// es ist ein Wort des Nutzers (Board 18, Entscheidung 19).
enum TrainingAim { weight, endurance, mobility, fitness, health, strength, muscle }

enum Describes { current, intended }

/// Ein Wert je Spur, jeder für sich offen.
@immutable
class Lanes<T> {
  const Lanes({this.strength, this.cardio});

  final T? strength;
  final T? cardio;

  T? operator [](Lane lane) => switch (lane) {
        Lane.strength => strength,
        Lane.cardio => cardio,
      };

  Lanes<T> put(Lane lane, T? value) => switch (lane) {
        Lane.strength => Lanes(strength: value, cardio: cardio),
        Lane.cardio => Lanes(strength: strength, cardio: value),
      };

  bool get any => strength != null || cardio != null;
  bool get isEmpty => !any;
}

/// Was eine Antwort mitgenommen hat.
sealed class Removal {
  const Removal();
}

/// Alles unter einer oder beiden Spuren.
final class LaneRemoval extends Removal {
  const LaneRemoval(this.lanes);
  final List<Lane> lanes;
}

final class WeekBRemoval extends Removal {
  const WeekBRemoval();
}

final class DaysRemoval extends Removal {
  const DaysRemoval();
}

final class DaypartsRemoval extends Removal {
  const DaypartsRemoval();
}

/// Der Montag der Woche, in der [day] liegt — lokale Mitternacht.
DateTime mondayOf(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

/// `yyyy-MM-dd`, wie die Dokument-IDs der Gewichtsreihe.
String formatDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

const Object _keep = Object();
const Object _clear = _Clear();

class _Clear {
  const _Clear();
}

/// Eine leere Menge ist keine Antwort.
Set<T>? _orNull<T>(Set<T>? s) => (s == null || s.isEmpty) ? null : s;

List<String> _sortedNames<E extends Enum>(Set<E> set, List<E> order) =>
    [for (final e in order) if (set.contains(e)) e.name];

bool _same(Object? a, Object? b) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  return a == b;
}
