import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/gen/app_l10n.dart';
import '../../../cardio/presentation/cardio_ui.dart';
import '../../domain/session_detail.dart';
import '../../domain/training_session.dart';
import '../session_ui.dart';

/// Die Wörter des Kopfes — aus den Zahlen der Domäne gebaut.
///
/// Getrennt vom Widget, weil dieselben Sätze an zwei Stellen gebraucht werden:
/// sichtbar im Kopf und **vorgelesen als ein Knoten** („Kraft, Push A.
/// Mittwoch 18. September … 24 Sätze. 5 Übungen, 52 Minuten, Anstrengung 4
/// von 5."). Zwei getrennt gebaute Fassungen liefen auseinander.
class DetailHeaderText {
  const DetailHeaderText({
    required this.kind,
    required this.title,
    required this.time,
    required this.basis,
    required this.spoken,
    this.leadValue,
    this.leadUnit,
  });

  /// Die Art als Wort — auch für die Glyphe.
  final String kind;

  /// „Kraft · Push A", oder nur die Art.
  final String title;

  /// „MI 18. SEP · 18:42–19:34".
  final String time;

  /// Die Zahl, die sagt, was das war — `null`, wenn die Kette leer läuft.
  /// **Kein „0", kein „—".**
  final String? leadValue;
  final String? leadUnit;

  /// Ein Satz Grundlage. Bei leerer Kette: „Nur Art und Tag sind bekannt."
  final String basis;

  final String spoken;

  bool get hasLead => leadValue != null;

  static DetailHeaderText of(
    BuildContext context,
    TrainingSession session, {
    required SessionLead? lead,
  }) {
    final l10n = AppL10n.of(context);
    final tag = languageTag(context);

    // ---- Art und Name -------------------------------------------------
    final kind = switch (session) {
      StrengthSession(bodyweight: true) => l10n.detailKindBodyweight,
      StrengthSession() => l10n.detailKindStrength,
      CardioSession(activity: final a?) => activityLabel(l10n, a),
      CardioSession() => l10n.detailKindEndurance,
      RecoverySession() => l10n.detailKindRecovery,
      // Ein Typ, den die PWA neu erfunden hat: neutral, nicht geraten.
      UnknownSession() => sessionKindLabel(l10n, session),
    };
    final name = switch (session) {
      StrengthSession(planName: final n) => n,
      CardioSession(name: final n) => n,
      RecoverySession(name: final n) => n,
      UnknownSession() => null,
    };
    final title = name == null || name.trim().isEmpty || name == kind
        ? kind
        : '$kind · $name';

    // ---- Zeit ---------------------------------------------------------
    final day = DateFormat.E(tag).format(session.date).replaceAll('.', '');
    final date = DateFormat.MMMd(tag).format(session.date).replaceAll('.,', '');
    final start = session.startedAt;
    final duration = session.duration;
    final hasSpan =
        start != null && duration != null && duration > Duration.zero;
    final clock = DateFormat.Hm(tag);

    // **Keine erfundene Uhrzeit.** Ohne gespeicherte Startzeit steht der Tag
    // da und sonst nichts — „00:00–00:52" wäre keine ungenaue, sondern eine
    // falsche Angabe.
    final time = (hasSpan
            ? l10n.detailTimeRange(day, date, clock.format(start),
                clock.format(start.add(duration)))
            : duration == null || duration <= Duration.zero
                ? l10n.detailTimeNoDuration(day, date)
                : l10n.detailTimeDayOnly(day, date))
        .toUpperCase();

    // ---- Leitzahl -----------------------------------------------------
    String? leadValue;
    String? leadUnit;
    switch (lead) {
      case SessionLead(kind: LeadKind.sets, :final value):
        leadValue = '${value.toInt()}';
        leadUnit = l10n.detailLeadSets;
      case SessionLead(kind: LeadKind.volume, :final value):
        leadValue = groupedInt(value.round());
        leadUnit = l10n.detailLeadVolume;
      case SessionLead(kind: LeadKind.distance, :final value):
        leadValue = NumberFormat('0.00', tag).format(value);
        leadUnit = l10n.detailLeadDistance;
      case SessionLead(kind: LeadKind.duration, :final value):
        leadValue = '${value.toInt()}';
        leadUnit = l10n.detailLeadDuration;
      case null:
        break;
    }

    // ---- Grundlage ----------------------------------------------------
    final basis = _basis(context, l10n, session, lead);

    final spoken = [
      title,
      DateFormat.yMMMMEEEEd(tag).format(session.date) +
          (hasSpan
              ? ', ${clock.format(start)} – ${clock.format(start.add(duration))}'
              : ''),
      if (leadValue != null) '$leadValue $leadUnit',
      basis,
    ].join('. ');

    return DetailHeaderText(
      kind: kind,
      title: title,
      time: time,
      leadValue: leadValue,
      leadUnit: leadUnit,
      basis: basis,
      spoken: spoken,
    );
  }

  static String _basis(
    BuildContext context,
    AppL10n l10n,
    TrainingSession session,
    SessionLead? lead,
  ) {
    // **Die Lücke steht im Satz**, nicht als Aufruf: Für 16 von 63
    // Krafteinheiten ist „Nur Art und Tag sind bekannt" eine Tatsache, kein
    // Mangel, den jemand nachtragen müsste.
    if (lead == null) return l10n.detailBasisEmpty;

    final minutes = session.duration?.inMinutes;
    final rpe = session.rpe;
    // Ohne Anstrengung an einer Einheit **aus der Uhr**: Die Uhr kann sie
    // nicht messen. Bei einer App-Einheit hat man sie nur nicht angegeben, und
    // das gehört nicht in jeden Satz.
    final noEffort = session.origin != SessionOrigin.app && rpe == null;

    switch (session) {
      case StrengthSession():
        final sets = <String>[];
        final exercises = session.exercises
            .where((e) => e.sets.any((s) => !s.isEmpty))
            .length;
        if (exercises > 0) sets.add(l10n.detailBasisExercises(exercises));
        if (minutes != null) sets.add(l10n.durationMinutes(minutes));
        if (rpe != null) sets.add(l10n.detailBasisEffort(rpe));
        if (exercises > 0 && minutes != null && rpe != null) {
          return l10n.detailBasisStrength(exercises, minutes, rpe);
        }
        return sets.join(' · ');

      case CardioSession():
        final tempo = session.tempo;
        final parts = <String>[
          // Pace als „5:42 /km im Schnitt"; Radfahren zählt in km/h, und das
          // Board-Muster „/km" gälte dort nicht.
          if (minutes != null && tempo != null && !tempo.usesSpeed)
            l10n.detailBasisRun(minutes, formatMinPerKm(tempo.minutesPerKm))
          else if (minutes != null && tempo != null)
            '${l10n.durationMinutes(minutes)} · ${formatTempo(context, tempo)}'
          else if (minutes != null)
            l10n.durationMinutes(minutes),
          if (rpe != null) l10n.detailBasisEffort(rpe),
          if (noEffort) l10n.detailNoEffort,
        ];
        return parts.join(' · ');

      case RecoverySession():
        final kind = recoveryKindLabel(l10n, session);
        return kind.isEmpty
            ? l10n.detailBasisNoLoad
            : l10n.detailBasisRecovery(kind);

      case UnknownSession():
        return minutes == null ? '' : l10n.durationMinutes(minutes);
    }
  }

  /// „4 180" — mit schmalem Leerzeichen, wie im Board, in beiden Sprachen.
  static String groupedInt(int n) {
    final digits = n.abs().toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(' ');
      out.write(digits[i]);
    }
    return '${n < 0 ? '-' : ''}$out';
  }
}
