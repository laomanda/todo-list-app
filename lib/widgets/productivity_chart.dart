import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/app_colors.dart';
import '../core/date_utils.dart';
import '../models/task_model.dart';

class DayProductivityData {
  DayProductivityData({
    required this.date,
    required this.tasks,
  });

  final DateTime date;
  final List<TaskModel> tasks;

  int get totalTasks => tasks.length;
  int get completedTasks =>
      tasks.where((t) => t.status == TaskStatus.completed).length;
  int get inProgressTasks =>
      tasks.where((t) => t.status == TaskStatus.inProgress).length;
  int get reviewTasks =>
      tasks.where((t) => t.status == TaskStatus.review).length;
  int get pendingTasks =>
      tasks.where((t) => t.status == TaskStatus.pending).length;

  int get totalSubTasks =>
      tasks.fold(0, (sum, t) => sum + t.rincianTindakLanjut.length);
  int get completedSubTasks =>
      tasks.fold(0, (sum, t) => sum + t.completedSubTaskCount);

  double get taskCompletionRatio =>
      totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

  int get productivityScore {
    if (totalTasks == 0) return 0;
    final totalWeight = tasks.fold<double>(0.0, (sum, t) {
      if (t.status == TaskStatus.completed) return sum + 1.0;
      if (t.rincianTindakLanjut.isNotEmpty) {
        return sum + (t.progress * 0.75);
      }
      if (t.status == TaskStatus.review) return sum + 0.65;
      if (t.status == TaskStatus.inProgress) return sum + 0.35;
      return sum;
    });
    return math.min(100, (totalWeight / totalTasks * 100).round());
  }
}

class ProductivityChart extends StatefulWidget {
  const ProductivityChart({
    super.key,
    required this.tasks,
    this.onAddTaskForDate,
    this.onSelectDay,
  });

  final List<TaskModel> tasks;
  final ValueChanged<DateTime>? onAddTaskForDate;
  final ValueChanged<DateTime>? onSelectDay;

  @override
  State<ProductivityChart> createState() => _ProductivityChartState();
}

class _ProductivityChartState extends State<ProductivityChart> {
  late DateTime _anchorDate;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _anchorDate = _resolveInitialAnchor(widget.tasks);
  }

  @override
  void didUpdateWidget(covariant ProductivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If tasks changed and current anchor has 0 tasks while today or other active tasks exist, keep anchor updated
    if (oldWidget.tasks != widget.tasks) {
      final currentHasTasks = _tasksForDate(_anchorDate).isNotEmpty;
      if (!currentHasTasks && widget.tasks.isNotEmpty) {
        setState(() {
          _anchorDate = _resolveInitialAnchor(widget.tasks);
        });
      }
    }
  }

  DateTime _resolveInitialAnchor(List<TaskModel> tasks) {
    final now = dateOnly(DateTime.now());
    final hasTodayTasks = tasks.any((t) => dateOnly(t.tanggal) == now);
    if (hasTodayTasks || tasks.isEmpty) {
      return now;
    }
    // If today is empty, find the most recent task date
    DateTime latest = tasks.first.tanggal;
    for (final t in tasks) {
      if (t.tanggal.isAfter(latest)) {
        latest = t.tanggal;
      }
    }
    return dateOnly(latest);
  }

  List<TaskModel> _tasksForDate(DateTime date) {
    final target = dateOnly(date);
    return widget.tasks.where((t) => dateOnly(t.tanggal) == target).toList();
  }

  void _shiftAnchor(int days) {
    setState(() {
      _anchorDate = _anchorDate.add(Duration(days: days));
    });
  }

  void _resetToToday() {
    setState(() {
      _anchorDate = dateOnly(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final day3 = _anchorDate;
    final day2 = _anchorDate.subtract(const Duration(days: 1));
    final day1 = _anchorDate.subtract(const Duration(days: 2));

    final data1 = DayProductivityData(date: day1, tasks: _tasksForDate(day1));
    final data2 = DayProductivityData(date: day2, tasks: _tasksForDate(day2));
    final data3 = DayProductivityData(date: day3, tasks: _tasksForDate(day3));
    final threeDayList = <DayProductivityData>[data1, data2, data3];

    final totalTasks = threeDayList.fold(0, (sum, d) => sum + d.totalTasks);
    final totalCompleted =
        threeDayList.fold(0, (sum, d) => sum + d.completedTasks);
    final totalSubTasks =
        threeDayList.fold(0, (sum, d) => sum + d.totalSubTasks);
    final totalCompletedSubTasks =
        threeDayList.fold(0, (sum, d) => sum + d.completedSubTasks);

    final avgScore = totalTasks == 0
        ? 0
        : (threeDayList.fold(0, (sum, d) => sum + d.productivityScore) / 3)
            .round();

    final isTodayAnchor = dateOnly(_anchorDate) == dateOnly(DateTime.now());

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.slate200),
      ),
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Card Header
            _buildHeader(
              day1: day1,
              day3: day3,
              isTodayAnchor: isTodayAnchor,
            ),

            if (!_isCollapsed) ...<Widget>[
              const SizedBox(height: 16),
              // Aggregate KPI Highlights Bar
              _buildHighlights(
                avgScore: avgScore,
                totalTasks: totalTasks,
                totalCompleted: totalCompleted,
                totalSubTasks: totalSubTasks,
                totalCompletedSubTasks: totalCompletedSubTasks,
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: AppColors.slate100),
              const SizedBox(height: 20),

              // 3-Day Visual Diagram Columns
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 820;
                  if (isCompact) {
                    return Column(
                      children: threeDayList
                          .map(
                            (data) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _DayCard(
                                data: data,
                                isToday: dateOnly(data.date) ==
                                    dateOnly(DateTime.now()),
                                onAddTask: widget.onAddTaskForDate == null
                                    ? null
                                    : () => widget.onAddTaskForDate!(data.date),
                                onSelect: widget.onSelectDay == null
                                    ? null
                                    : () => widget.onSelectDay!(data.date),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (int i = 0; i < threeDayList.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(width: 14),
                        Expanded(
                          child: _DayCard(
                            data: threeDayList[i],
                            isToday: dateOnly(threeDayList[i].date) ==
                                dateOnly(DateTime.now()),
                            onAddTask: widget.onAddTaskForDate == null
                                ? null
                                : () => widget.onAddTaskForDate!(
                                      threeDayList[i].date,
                                    ),
                            onSelect: widget.onSelectDay == null
                                ? null
                                : () => widget.onSelectDay!(
                                      threeDayList[i].date,
                                    ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required DateTime day1,
    required DateTime day3,
    required bool isTodayAnchor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 740;
        final titleWidget = Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const FaIcon(
                FontAwesomeIcons.chartSimple,
                size: 16,
                color: AppColors.royalBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: <Widget>[
                      const Text(
                        'Diagram Produktivitas (3 Hari)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '3-Day Window',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${formatShortDate(day1)} – ${formatDate(day3)}',
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: 'Geser 1 hari sebelumnya',
              icon: const FaIcon(FontAwesomeIcons.chevronLeft, size: 12),
              onPressed: () => _shiftAnchor(-1),
              visualDensity: VisualDensity.compact,
            ),
            if (!isTodayAnchor)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextButton.icon(
                  onPressed: _resetToToday,
                  icon: const FaIcon(FontAwesomeIcons.rotateLeft, size: 10),
                  label: const Text(
                    'Hari Ini',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Geser 1 hari berikutnya',
              icon: const FaIcon(FontAwesomeIcons.chevronRight, size: 12),
              onPressed: () => _shiftAnchor(1),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: _isCollapsed ? 'Tampilkan diagram' : 'Sembunyikan diagram',
              icon: FaIcon(
                _isCollapsed
                    ? FontAwesomeIcons.chevronDown
                    : FontAwesomeIcons.chevronUp,
                size: 12,
                color: AppColors.slate500,
              ),
              onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
              visualDensity: VisualDensity.compact,
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              titleWidget,
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerRight, child: controls),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: titleWidget),
            controls,
          ],
        );
      },
    );
  }

  Widget _buildHighlights({
    required int avgScore,
    required int totalTasks,
    required int totalCompleted,
    required int totalSubTasks,
    required int totalCompletedSubTasks,
  }) {
    Color scoreColor;
    String scoreStatus;
    if (avgScore >= 80) {
      scoreColor = AppColors.success;
      scoreStatus = 'Sangat Produktif';
    } else if (avgScore >= 50) {
      scoreColor = AppColors.royalBlue;
      scoreStatus = 'Produktif';
    } else if (avgScore > 0) {
      scoreColor = AppColors.warning;
      scoreStatus = 'Cukup';
    } else {
      scoreColor = AppColors.slate400;
      scoreStatus = 'Belum Ada Aktivitas';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final items = <Widget>[
          _HighlightPill(
            label: 'Rata-rata Produktivitas',
            value: '$avgScore%',
            badge: scoreStatus,
            badgeColor: scoreColor,
            icon: FontAwesomeIcons.gaugeHigh,
            iconColor: scoreColor,
          ),
          _HighlightPill(
            label: 'Tugas Selesai (3 Hari)',
            value: '$totalCompleted / $totalTasks',
            badge: totalTasks > 0
                ? '${((totalCompleted / totalTasks) * 100).round()}% tuntas'
                : '0 tugas',
            badgeColor: AppColors.royalBlue,
            icon: FontAwesomeIcons.circleCheck,
            iconColor: AppColors.success,
          ),
          _HighlightPill(
            label: 'Sub-tugas Selesai',
            value: '$totalCompletedSubTasks / $totalSubTasks',
            badge: totalSubTasks > 0
                ? '${((totalCompletedSubTasks / totalSubTasks) * 100).round()}% rampung'
                : 'Tanpa sub-tugas',
            badgeColor: AppColors.purple,
            icon: FontAwesomeIcons.listCheck,
            iconColor: AppColors.purple,
          ),
        ];

        if (compact) {
          return Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: item,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: <Widget>[
            for (int i = 0; i < items.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: items[i]),
            ],
          ],
        );
      },
    );
  }
}

class _HighlightPill extends StatelessWidget {
  const _HighlightPill({
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final String badge;
  final Color badgeColor;
  final FaIconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: <Widget>[
          FaIcon(icon, size: 14, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.data,
    required this.isToday,
    this.onAddTask,
    this.onSelect,
  });

  final DayProductivityData data;
  final bool isToday;
  final VoidCallback? onAddTask;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final score = data.productivityScore;
    final total = data.totalTasks;
    final completed = data.completedTasks;
    final inProgress = data.inProgressTasks;
    final review = data.reviewTasks;
    final pending = data.pendingTasks;

    Color scoreColor;
    if (score >= 80) {
      scoreColor = AppColors.success;
    } else if (score >= 50) {
      scoreColor = AppColors.royalBlue;
    } else if (score > 0) {
      scoreColor = AppColors.warning;
    } else {
      scoreColor = AppColors.slate400;
    }

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isToday ? const Color(0xFFF0F7FF) : AppColors.slate50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isToday ? AppColors.royalBlue : AppColors.slate200,
            width: isToday ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Day Label Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      relativeDayLabel(data.date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isToday ? AppColors.navy : AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dayName(data.date)}, ${formatShortDate(data.date)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    total == 0 ? '0%' : '$score%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bar Chart Visual Column
            SizedBox(
              height: 110,
              child: total == 0
                  ? _buildEmptyDay(context)
                  : _buildBarChart(
                      total: total,
                      completed: completed,
                      inProgress: inProgress,
                      review: review,
                      pending: pending,
                    ),
            ),

            const SizedBox(height: 14),

            // Bottom Task Breakdown
            if (total > 0) ...<Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '$completed dari $total tugas tuntas',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate700,
                    ),
                  ),
                  if (data.totalSubTasks > 0)
                    Text(
                      '${data.completedSubTasks}/${data.totalSubTasks} sub-task',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.slate500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: <Widget>[
                  if (completed > 0)
                    _StatusBadge(
                      label: '$completed Selesai',
                      color: AppColors.success,
                      bgColor: AppColors.successSoft,
                    ),
                  if (inProgress > 0)
                    _StatusBadge(
                      label: '$inProgress Proses',
                      color: AppColors.royalBlue,
                      bgColor: const Color(0xFFDBEAFE),
                    ),
                  if (review > 0)
                    _StatusBadge(
                      label: '$review Review',
                      color: AppColors.purple,
                      bgColor: AppColors.purpleSoft,
                    ),
                  if (pending > 0)
                    _StatusBadge(
                      label: '$pending Pending',
                      color: AppColors.warning,
                      bgColor: AppColors.warningSoft,
                    ),
                ],
              ),
            ] else if (onAddTask != null) ...<Widget>[
              OutlinedButton.icon(
                onPressed: onAddTask,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  foregroundColor: AppColors.royalBlue,
                ),
                icon: const FaIcon(FontAwesomeIcons.plus, size: 10),
                label: const Text(
                  'Tambah Tugas',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDay(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FaIcon(
            FontAwesomeIcons.calendarDay,
            size: 22,
            color: AppColors.slate300,
          ),
          const SizedBox(height: 6),
          const Text(
            'Tidak ada tugas',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.slate400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart({
    required int total,
    required int completed,
    required int inProgress,
    required int review,
    required int pending,
  }) {
    // A segmented vertical stacked bar representing the status composition
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        final completedH = (completed / total) * height;
        final inProgressH = (inProgress / total) * height;
        final reviewH = (review / total) * height;
        final pendingH = (pending / total) * height;

        return Row(
          children: <Widget>[
            // The Main Stacked Vertical Bar
            Container(
              width: 32,
              height: height,
              decoration: BoxDecoration(
                color: AppColors.slate200,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                verticalDirection: VerticalDirection.up,
                children: <Widget>[
                  if (completedH > 0)
                    Container(
                      height: completedH,
                      color: AppColors.success,
                    ),
                  if (inProgressH > 0)
                    Container(
                      height: inProgressH,
                      color: AppColors.royalBlue,
                    ),
                  if (reviewH > 0)
                    Container(
                      height: reviewH,
                      color: AppColors.purple,
                    ),
                  if (pendingH > 0)
                    Container(
                      height: pendingH,
                      color: AppColors.slate300,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Progress details next to the bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _ChartLegendItem(
                    label: 'Selesai',
                    count: completed,
                    color: AppColors.success,
                  ),
                  _ChartLegendItem(
                    label: 'Dalam Proses',
                    count: inProgress,
                    color: AppColors.royalBlue,
                  ),
                  _ChartLegendItem(
                    label: 'Review',
                    count: review,
                    color: AppColors.purple,
                  ),
                  _ChartLegendItem(
                    label: 'Pending',
                    count: pending,
                    color: AppColors.slate400,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: count > 0 ? color : AppColors.slate300,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: count > 0 ? FontWeight.w700 : FontWeight.w500,
              color: count > 0 ? AppColors.slate700 : AppColors.slate400,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: count > 0 ? color : AppColors.slate400,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
