import 'package:flutter/widgets.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/gen/app_l10n.dart';
import '../../../cardio/presentation/cardio_ui.dart' show activityLabel;
import '../../../history/domain/training_session.dart' show CardioActivity;
import '../../../plans/domain/plan.dart';
import '../../application/week_plan_providers.dart';
import '../../domain/week_plan.dart';
import '../week_ui.dart';

/// Was das Blatt entschieden hat.
sealed class WeekSheetResult {
  const WeekSheetResult();
}

/// Angelegt oder geändert.
final class WeekSheetSaved extends WeekSheetResult {
  const WeekSheetSaved(this.entry);
  final WeekEntry entry;
}

/// Auf einen anderen Tag verschoben — ein Tipp auf den Tag-Chip.
final class WeekSheetMoved extends WeekSheetResult {
  const WeekSheetMoved(this.weekday);
  final int weekday;
}

final class WeekSheetRemoved extends WeekSheetResult {
  const WeekSheetRemoved();
}

/// **Ein Blatt für alles, was einen Eintrag betrifft** (Board 19, C).
///
/// Anlegen am Plus eines Tages, Ändern, Verschieben ohne Ziehen und
/// Entfernen am Eintrag. Jede Wahl ist lokal, bis „Hinzufügen" oder
/// „Übernehmen" — ein Eintrag besteht aus mehreren Angaben, deshalb gibt es
/// hier als einzige Stelle der Woche einen Knopf. Verschieben dagegen ist
/// eine Angabe und schliesst das Blatt sofort.
class WeekEntrySheet {
  static Future<WeekSheetResult?> show(
    BuildContext context, {
    required int weekday,
    required List<Plan> plans,
    required bool dayHasOtherEntries,
    WeekEntry? entry,
  }) {
    final l10n = AppL10n.of(context);
    final words = WeekWords(context);
    final day = words.dayLong(weekday);
    return AtemSheet.show<WeekSheetResult>(
      context,
      title: entry == null
          ? l10n.weekSheetAddTitle(day)
          : l10n.weekSheetEditTitle(day),
      closeLabel: l10n.commonCancel,
      child: _Body(
        weekday: weekday,
        plans: plans,
        entry: entry,
        dayHasOtherEntries: dayHasOtherEntries,
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({
    required this.weekday,
    required this.plans,
    required this.entry,
    required this.dayHasOtherEntries,
  });

  final int weekday;
  final List<Plan> plans;
  final WeekEntry? entry;
  final bool dayHasOtherEntries;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late WeekKind? _kind = widget.entry?.kind;
  late String? _planId = widget.entry?.planId;
  late CardioActivity? _activity = widget.entry?.activity;
  late int? _minutes = widget.entry?.durationMin;
  late WeekDaypart? _daypart = widget.entry?.daypart;

  static const _activities = [
    CardioActivity.run,
    CardioActivity.bike,
    CardioActivity.swim,
    CardioActivity.row,
    CardioActivity.hike,
    CardioActivity.other,
  ];
  static const _durations = [20, 30, 40, 45, 60, 90];

  bool get _complete =>
      _kind != null && (_kind != WeekKind.cardio || _activity != null);

  void _close(WeekSheetResult result) =>
      Navigator.of(context, rootNavigator: true).pop(result);

  WeekEntry _build() {
    final kind = _kind!;
    final plan = kind == WeekKind.strength && _planId != null
        ? widget.plans.where((p) => p.id == _planId).firstOrNull
        : null;
    return WeekEntry(
      id: widget.entry?.id ?? WeekPlanController.newId(),
      weekday: widget.weekday,
      kind: kind,
      planId: kind == WeekKind.strength ? _planId : null,
      // Den Schnappschuss nur neu setzen, wenn der Plan auflösbar ist; ein
      // unveränderter gelöschter Plan behält seinen alten Namen.
      planName: kind != WeekKind.strength || _planId == null
          ? null
          : plan?.name ?? widget.entry?.planName,
      activity: kind == WeekKind.cardio ? _activity : null,
      durationMin: kind == WeekKind.cardio ? _minutes : null,
      daypart: kind == WeekKind.off ? null : _daypart,
      order: widget.entry?.order ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final words = WeekWords(context);
    final editing = widget.entry != null;
    final offBlocked = widget.dayHasOtherEntries;
    final action = editing ? l10n.weekSheetApply : l10n.weekSheetAdd;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.weekSheetAddSub(words.dayLong(widget.weekday)),
            style: AtemType.labelSmall.of(context).copyWith(fontSize: 12.5)),
        _Group(l10n.weekSheetGroupKind),
        AtemAnswerTileGrid(
          basis: 88,
          children: [
            for (final k in WeekKind.values)
              _KindTile(
                kind: k,
                label: words.kind(k),
                blockedReason: k == WeekKind.off && offBlocked
                    ? l10n.weekSheetOffDisabled
                    : null,
                selected: _kind == k,
                onTap: () => setState(() => _kind = k),
              ),
          ],
        ),
        AtemRevealGroup(
          visible: _kind == WeekKind.strength,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Group(l10n.weekSheetGroupPlan),
              for (final (i, option) in [
                (null, l10n.weekSheetPlanNone, null),
                for (final p in widget.plans)
                  (p.id, p.name, l10n.exerciseCountShort(p.exerciseCount)),
              ].indexed) ...[
                if (i > 0) const SizedBox(height: 8),
                AtemAnswerOption(
                  label: option.$3 == null
                      ? option.$2
                      : '${option.$2} · ${option.$3}',
                  selected: _planId == option.$1,
                  onTap: () => setState(() => _planId = option.$1),
                ),
              ],
            ],
          ),
        ),
        AtemRevealGroup(
          visible: _kind == WeekKind.cardio,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Group(l10n.weekSheetGroupActivity),
              _Chips([
                for (final a in _activities)
                  AtemAnswerChip(
                    label: activityLabel(l10n, a),
                    semanticLabel: activityLabel(l10n, a),
                    selected: _activity == a,
                    onTap: () => setState(() => _activity = a),
                  ),
              ]),
              _Group(l10n.weekSheetGroupDuration),
              _Chips([
                for (final m in _durations)
                  AtemAnswerChip(
                    label: l10n.weekCardioMinutes(m),
                    semanticLabel: l10n.weekCardioMinutes(m),
                    exclusive: false,
                    selected: _minutes == m,
                    onTap: () =>
                        setState(() => _minutes = _minutes == m ? null : m),
                  ),
              ]),
            ],
          ),
        ),
        AtemRevealGroup(
          visible: _kind != null && _kind != WeekKind.off,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Group(l10n.weekSheetGroupDaypart),
              _Chips([
                for (final d in WeekDaypart.values)
                  AtemAnswerChip(
                    label: words.daypart(d),
                    semanticLabel: words.daypart(d),
                    exclusive: false,
                    selected: _daypart == d,
                    onTap: () =>
                        setState(() => _daypart = _daypart == d ? null : d),
                  ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ConfirmButton(
          label: action,
          semanticLabel: _complete
              ? action
              : l10n.weekSheetIncompleteA11y(action),
          enabled: _complete,
          onTap: () => _close(WeekSheetSaved(_build())),
        ),
        if (editing) ...[
          _Group(l10n.weekSheetMoveLabel),
          Semantics(
            container: true,
            label: l10n.weekSheetMoveLabel,
            explicitChildNodes: true,
            child: _Chips([
              for (final d in WeekWords.weekdays)
                AtemAnswerChip(
                  label: words.dayShort(d),
                  semanticLabel: d == widget.weekday
                      ? l10n.weekSheetCurrentDay(words.dayLong(d))
                      : words.dayLong(d),
                  selected: d == widget.weekday,
                  onTap: d == widget.weekday
                      ? () {}
                      : () => _close(WeekSheetMoved(d)),
                ),
            ]),
          ),
          const SizedBox(height: 6),
          Text(l10n.weekSheetMoveHint, style: AtemType.meta.of(context)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              container: true,
              child: AtemTappable(
                semanticLabel: l10n.weekSheetRemove,
                alignment: Alignment.centerLeft,
                onTap: () => _close(const WeekSheetRemoved()),
                child: Text(
                  l10n.weekSheetRemove,
                  style: AtemType.labelSmall.of(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: AtemColors.magenta,
                      ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(label.toUpperCase(),
            style: AtemType.labelMicro.of(context)),
      );
}

class _Chips extends StatelessWidget {
  const _Chips(this.children);
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        // Luft für die Häkchen-Ecke, die 6 dp herausragt.
        padding: const EdgeInsets.only(top: 6, right: 6),
        child: Wrap(spacing: 8, runSpacing: 12, children: children),
      );
}

/// Eine Art-Kachel. „Frei" ist an einem belegten Tag gesperrt und nennt den
/// Grund — sichtbar und im Label, nie nur ausgegraut.
class _KindTile extends StatelessWidget {
  const _KindTile({
    required this.kind,
    required this.label,
    required this.selected,
    required this.onTap,
    this.blockedReason,
  });

  final WeekKind kind;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? blockedReason;

  @override
  Widget build(BuildContext context) {
    final tone = WeekWords.tone(kind);
    final blocked = blockedReason != null;
    final tile = AtemAnswerTile(
      label: blocked ? '$label\n$blockedReason' : label,
      semanticLabel: blocked ? '$label, $blockedReason' : label,
      glyph: WeekWords.glyph(kind),
      glyphFill: tone.fill,
      glyphColor: tone.glyph,
      selected: selected,
      onTap: blocked ? () {} : onTap,
    );
    return blocked ? Opacity(opacity: 0.55, child: tile) : tile;
  }
}

/// „Hinzufügen" / „Übernehmen": Cyan-Rand, unvollständig gedämpft — mit dem
/// Grund im Label, nie nur grau.
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.label,
    required this.semanticLabel,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        child: AtemTappable(
          semanticLabel: semanticLabel,
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: AtemMotion.duration(context, AtemMotion.dPress),
            height: 52,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled
                  ? AtemColors.cyan.withValues(alpha: 0.10)
                  : AtemColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AtemRadii.statBox),
              border: Border.all(
                color: enabled ? AtemColors.cyan : AtemColors.border,
              ),
            ),
            child: Text(
              label,
              style: AtemType.labelMedium.of(context).copyWith(
                    color: enabled
                        ? AtemColors.cyan
                        : AtemColors.textSecondary,
                  ),
            ),
          ),
        ),
      );
}
