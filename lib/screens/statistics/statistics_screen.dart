// Taskenda — Copyright © 2026 Nicola De Nicolais — All Rights Reserved.
// Licensed under a source-available, non-commercial license. See LICENSE.
//
// Commercial use, including publishing or monetizing on any app store,
// requires explicit written permission from the copyright holder.
//
// Author: Nicola De Nicolais
// Contact: ndn21dev@gmail.com
// GitHub: https://github.com/ndenicolais

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../l10n/l10n.dart';
import '../../providers/statistics_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/statistics.dart';
import '../../widgets/nav_scaffold.dart';
import 'statistics_widgets.dart';

// Colors of the three kinds of items, shared by every block.
const _notesColor = AppColors.amber;
const _tasksColor = AppColors.teal;
const _eventsColor = AppColors.blue;

/// Overview, tasks, activity over time, most used labels and a summary of
/// active / archived / trashed items, all from [statisticsProvider]. Uses the
/// full width: from [_twoColumnWidth] the blocks after the overview pair up
/// in two columns.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  static const _twoColumnWidth = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    const gap = SizedBox(height: AppSpacing.xl, width: AppSpacing.xl);
    return NavScaffold(
      section: DrawerSection.statistics,
      titleWidget: Text(context.l10n.statsTitle),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _twoColumnWidth;
          Widget pair(Widget a, Widget b) =>
              wide
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Expanded(child: a), gap, Expanded(child: b)],
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [a, gap, b],
                  );
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _OverviewSection(stats),
              gap,
              pair(_TasksSection(stats), _ActivitySection(stats)),
              gap,
              pair(_LabelsSection(stats), _SummarySection(stats)),
              gap,
            ],
          );
        },
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection(this.stats);
  final StatisticsData stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatsSectionHeader(
          title: l10n.statsOverview,
          icon: Icons.dashboard_outlined,
        ),
        StatsGrid(
          items: [
            StatsDataItem(
              icon: Icons.lightbulb_outline,
              label: l10n.navNotes,
              value: stats.notes.active,
              color: _notesColor,
            ),
            StatsDataItem(
              icon: Icons.check_circle_outline,
              label: l10n.statsOpenTasks,
              value: stats.openTasks,
              color: _tasksColor,
            ),
            StatsDataItem(
              icon: Icons.calendar_today_outlined,
              label: l10n.statsEventsThisWeek,
              value: stats.eventsThisWeek,
              color: _eventsColor,
            ),
            StatsDataItem(
              icon: Icons.auto_awesome_outlined,
              label: l10n.statsCreatedThisWeek,
              value: stats.createdThisWeek,
              color: AppColors.violet,
            ),
          ],
        ),
      ],
    );
  }
}

class _TasksSection extends StatelessWidget {
  const _TasksSection(this.stats);
  final StatisticsData stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final total = stats.openTasks + stats.completedTasks;
    final breakdown = Column(
      children: [
        StatsCountRow(
          label: l10n.statsOverdue,
          value: stats.overdueTasks,
          color: cs.error,
          emphasize: stats.overdueTasks > 0,
        ),
        StatsCountRow(
          label: l10n.statsDueToday,
          value: stats.dueTodayTasks,
          color: AppColors.amber,
        ),
        StatsCountRow(
          label: l10n.statsDueThisWeek,
          value: stats.dueThisWeekTasks,
          color: _eventsColor,
        ),
        StatsCountRow(
          label: l10n.statsNoDueDate,
          value: stats.noDueDateTasks,
          color: cs.outline,
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatsSectionHeader(
          title: l10n.statsTaskCompletion,
          icon: Icons.task_alt,
          subtitle:
              total == 0
                  ? null
                  : l10n.statsCompletedOf(stats.completedTasks, total),
        ),
        StatsPanel(
          child:
              total == 0
                  ? StatsEmpty(icon: Icons.task_alt, message: l10n.statsNoTasks)
                  : Row(
                    children: [
                      CompletionRing(
                        rate: stats.completionRate,
                        color: _tasksColor,
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(child: breakdown),
                    ],
                  ),
        ),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection(this.stats);
  final StatisticsData stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final empty = stats.weeks.every((w) => w.total == 0);
    final weekday = stats.mostActiveWeekday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatsSectionHeader(
          title: l10n.statsActivity,
          icon: Icons.insights_outlined,
          subtitle: l10n.statsActivitySubtitle,
        ),
        StatsPanel(
          child:
              empty
                  ? StatsEmpty(
                    icon: Icons.insights_outlined,
                    message: l10n.statsNoActivity,
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ActivityChart(
                        weeks: stats.weeks,
                        series: [
                          StatsSeries(l10n.navNotes, _notesColor),
                          StatsSeries(l10n.commonTabTasks, _tasksColor),
                          StatsSeries(l10n.commonTabEvents, _eventsColor),
                        ],
                      ),
                      if (weekday != null) ...[
                        const Divider(height: AppSpacing.xl),
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_outlined,
                              size: 20,
                              color: AppColors.coral,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                l10n.statsMostActiveDay(_weekdayName(weekday)),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
        ),
      ],
    );
  }

  /// Localized name of [weekday] (1 = Monday), from a known Monday.
  static String _weekdayName(int weekday) =>
      DateFormat.EEEE().format(DateTime(2024, 1, weekday));
}

class _LabelsSection extends StatelessWidget {
  const _LabelsSection(this.stats);
  final StatisticsData stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatsSectionHeader(
          title: l10n.statsTopLabels,
          icon: Icons.label_outline,
        ),
        StatsPanel(
          child:
              stats.topLabels.isEmpty
                  ? StatsEmpty(
                    icon: Icons.label_off_outlined,
                    message: l10n.statsNoLabelsUsed,
                  )
                  : TopLabelsList(
                    labels: stats.topLabels,
                    color: AppColors.coral,
                  ),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection(this.stats);
  final StatisticsData stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatsSectionHeader(
          title: l10n.statsSummary,
          icon: Icons.table_rows_outlined,
        ),
        StatsPanel(
          child: SummaryTable(
            rows: [
              SummaryRow(
                Icons.calendar_today_outlined,
                l10n.commonTabEvents,
                stats.events,
                _eventsColor,
              ),
              SummaryRow(
                Icons.check_circle_outline,
                l10n.commonTabTasks,
                stats.tasks,
                _tasksColor,
              ),
              SummaryRow(
                Icons.lightbulb_outline,
                l10n.navNotes,
                stats.notes,
                _notesColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
