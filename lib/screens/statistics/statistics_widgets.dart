// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../utils/statistics.dart';

// ─── Section header ───────────────────────────────────────────────────────────

class StatsSectionHeader extends StatelessWidget {
  const StatsSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
  });
  final String title;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.md,
        left: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs, left: 28),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Card container ───────────────────────────────────────────────────────────

/// Flat, outlined card holding one block of the screen.
class StatsPanel extends StatelessWidget {
  const StatsPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

// ─── Overview tiles ───────────────────────────────────────────────────────────

class StatsDataItem {
  const StatsDataItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int value;
  final Color color;
}

/// Tiles in 2 columns (4 when wide).
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.items});
  final List<StatsDataItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 600 ? 4 : 2;
        const spacing = 10.0;
        final cellW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(width: cellW, child: StatCard(item: item)),
          ],
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.item});
  final StatsDataItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '${item.label}: ${item.value}',
      excludeSemantics: true,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: item.color.withAlpha(28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: item.color, size: 22),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${item.value}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                item.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Task completion ring ─────────────────────────────────────────────────────

class CompletionRing extends StatelessWidget {
  const CompletionRing({super.key, required this.rate, required this.color});
  final double rate;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.square(
      dimension: 112,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: rate,
            strokeWidth: 10,
            strokeCap: StrokeCap.round,
            color: color,
            backgroundColor: color.withAlpha(40),
          ),
          Center(
            child: Text(
              '${(rate * 100).round()}%',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of the task breakdown: a colored dot, a label and a count.
class StatsCountRow extends StatelessWidget {
  const StatsCountRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.emphasize = false,
  });
  final String label;
  final int value;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: emphasize ? FontWeight.bold : null,
      color: emphasize ? color : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: style)),
          Text('$value', style: style?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Activity chart ───────────────────────────────────────────────────────────

class StatsSeries {
  const StatsSeries(this.label, this.color);
  final String label;
  final Color color;
}

/// Stacked bars of the items created per week: notes, tasks, events in the
/// order of [series].
class ActivityChart extends StatelessWidget {
  const ActivityChart({super.key, required this.weeks, required this.series});
  final List<WeekActivity> weeks;
  final List<StatsSeries> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = weeks.fold(0, (m, w) => w.total > m ? w.total : m);
    final dayMonth = DateFormat.MMMd();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: (maxY * 1.15).ceilToDouble().clamp(1, double.infinity),
              alignment: BarChartAlignment.spaceBetween,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                  getTooltipItem:
                      (group, _, _, _) => BarTooltipItem(
                        '${dayMonth.format(weeks[group.x].weekStart)}\n'
                        '${context.l10n.statsItemsCount(weeks[group.x].total)}',
                        TextStyle(
                          color: theme.colorScheme.onInverseSurface,
                          fontSize: 12,
                        ),
                      ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < weeks.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [_rod(weeks[i], theme.colorScheme)],
                  ),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      // A label every 3 weeks, ending on this week.
                      if ((weeks.length - 1 - i) % 3 != 0) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          dayMonth.format(weeks[i].weekStart),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine:
                    (_) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 0.5,
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            for (final s in series)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(s.label, style: theme.textTheme.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }

  BarChartRodData _rod(WeekActivity w, ColorScheme cs) {
    final values = [w.notes, w.tasks, w.events];
    final stack = <BarChartRodStackItem>[];
    var from = 0.0;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final to = from + values[i];
      stack.add(BarChartRodStackItem(from, to, series[i].color));
      from = to;
    }
    return BarChartRodData(
      toY: w.total.toDouble(),
      width: 14,
      color: cs.surfaceContainerHighest,
      rodStackItems: stack,
      borderRadius: BorderRadius.circular(3),
    );
  }
}

// ─── Top labels ───────────────────────────────────────────────────────────────

/// Horizontal bars of the most used labels, relative to the first.
class TopLabelsList extends StatelessWidget {
  const TopLabelsList({super.key, required this.labels, required this.color});
  final List<LabelUsage> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = labels.first.count;
    return Column(
      children: [
        for (final l in labels)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.label,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${l.count}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: l.count / max,
                    minHeight: 8,
                    color: color,
                    backgroundColor: color.withAlpha(36),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Summary table ────────────────────────────────────────────────────────────

class SummaryRow {
  const SummaryRow(this.icon, this.label, this.counts, this.color);
  final IconData icon;
  final String label;
  final StateCounts counts;
  final Color color;
}

/// Active / archived / trashed counts per kind of item.
class SummaryTable extends StatelessWidget {
  const SummaryTable({super.key, required this.rows});
  final List<SummaryRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final head = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final cell = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    TableRow row(List<Widget> cells) => TableRow(
      children: [
        for (final c in cells)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: c,
          ),
      ],
    );
    Widget num(int v) => Text('$v', style: cell, textAlign: TextAlign.end);

    return Table(
      columnWidths: const {0: FlexColumnWidth(2)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        row([
          const SizedBox.shrink(),
          Text(l10n.statsActive, style: head, textAlign: TextAlign.end),
          Text(l10n.statsArchived, style: head, textAlign: TextAlign.end),
          Text(l10n.statsTrashed, style: head, textAlign: TextAlign.end),
        ]),
        for (final r in rows)
          row([
            Row(
              children: [
                Icon(r.icon, size: 18, color: r.color),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    r.label,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            num(r.counts.active),
            num(r.counts.archived),
            num(r.counts.trashed),
          ]),
      ],
    );
  }
}

// ─── Empty placeholder ────────────────────────────────────────────────────────

class StatsEmpty extends StatelessWidget {
  const StatsEmpty({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Icon(icon, size: 32, color: outline),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: outline),
          ),
        ],
      ),
    );
  }
}
