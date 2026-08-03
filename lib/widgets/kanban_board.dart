import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/app_colors.dart';
import '../core/date_utils.dart';
import '../models/task_model.dart';
import 'task_progress.dart';
import 'task_visuals.dart';

class KanbanBoard extends StatelessWidget {
  const KanbanBoard({
    super.key,
    required this.tasks,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
    required this.onSubTaskToggle,
  });

  final List<TaskModel> tasks;
  final ValueChanged<TaskModel> onEdit;
  final ValueChanged<TaskModel> onDelete;
  final void Function(TaskModel task, TaskStatus status) onStatusChanged;
  final void Function(TaskModel task, int index) onSubTaskToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final columnWidth = available >= 1280 ? (available - 36) / 4 : 310.0;
        return Scrollbar(
          thumbVisibility: false,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: TaskStatus.values.map((status) {
                final columnTasks = tasks
                    .where((task) => task.status == status)
                    .toList();
                return Padding(
                  padding: EdgeInsets.only(
                    right: status == TaskStatus.completed ? 0 : 12,
                  ),
                  child: SizedBox(
                    width: columnWidth,
                    child: _KanbanColumn(
                      status: status,
                      tasks: columnTasks,
                      onEdit: onEdit,
                      onDelete: onDelete,
                      onStatusChanged: onStatusChanged,
                      onSubTaskToggle: onSubTaskToggle,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.status,
    required this.tasks,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
    required this.onSubTaskToggle,
  });

  final TaskStatus status;
  final List<TaskModel> tasks;
  final ValueChanged<TaskModel> onEdit;
  final ValueChanged<TaskModel> onDelete;
  final void Function(TaskModel task, TaskStatus status) onStatusChanged;
  final void Function(TaskModel task, int index) onSubTaskToggle;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate100,
        border: Border.all(color: AppColors.slate200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              border: Border(bottom: BorderSide(color: color, width: 3)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusSoftColor(status),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: FaIcon(statusIcon(status), size: 13, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    status.label,
                    style: const TextStyle(
                      color: AppColors.slate900,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusSoftColor(status),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tasks.length.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: tasks.isEmpty
                ? _EmptyColumn(status: status)
                : Column(
                    children: tasks
                        .map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _KanbanCard(
                              task: task,
                              onEdit: () => onEdit(task),
                              onDelete: () => onDelete(task),
                              onStatusChanged: (value) =>
                                  onStatusChanged(task, value),
                              onSubTaskToggle: (index) =>
                                  onSubTaskToggle(task, index),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
    required this.onSubTaskToggle,
  });

  final TaskModel task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<TaskStatus> onStatusChanged;
  final ValueChanged<int> onSubTaskToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: AppColors.slate200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: PriorityChip(priority: task.prioritas)),
                PopupMenuButton<String>(
                  tooltip: 'Aksi tugas',
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: _MenuLine(
                        icon: FontAwesomeIcons.penToSquare,
                        label: 'Edit tugas',
                        color: AppColors.royalBlue,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: _MenuLine(
                        icon: FontAwesomeIcons.trashCan,
                        label: 'Hapus tugas',
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: FaIcon(
                      FontAwesomeIcons.ellipsisVertical,
                      size: 14,
                      color: AppColors.slate500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              task.uraianPekerjaan,
              style: const TextStyle(
                color: AppColors.slate900,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
            if (task.keterangan.isNotEmpty) ...<Widget>[
              const SizedBox(height: 7),
              Text(
                task.keterangan,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.slate500,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 13),
            Row(
              children: <Widget>[
                const FaIcon(
                  FontAwesomeIcons.calendarDays,
                  size: 11,
                  color: AppColors.slate500,
                ),
                const SizedBox(width: 6),
                Text(
                  formatDate(task.tanggal),
                  style: const TextStyle(
                    color: AppColors.slate600,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const FaIcon(
                  FontAwesomeIcons.user,
                  size: 11,
                  color: AppColors.slate500,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    task.pic.isEmpty ? '-' : task.pic,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.slate600,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (task.rincianTindakLanjut.isNotEmpty) ...<Widget>[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              ...task.rincianTindakLanjut
                  .take(3)
                  .toList()
                  .asMap()
                  .entries
                  .map(
                    (entry) => InkWell(
                      onTap: () => onSubTaskToggle(entry.key),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: <Widget>[
                            FaIcon(
                              entry.value.isCompleted
                                  ? FontAwesomeIcons.solidSquareCheck
                                  : FontAwesomeIcons.square,
                              size: 14,
                              color: entry.value.isCompleted
                                  ? AppColors.success
                                  : AppColors.slate400,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.value.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: entry.value.isCompleted
                                      ? AppColors.slate500
                                      : AppColors.slate700,
                                  decoration: entry.value.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              if (task.rincianTindakLanjut.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${task.rincianTindakLanjut.length - 3} rincian lainnya',
                    style: const TextStyle(
                      color: AppColors.royalBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 14),
            TaskProgress(task: task, compact: true),
            const SizedBox(height: 13),
            PopupMenuButton<TaskStatus>(
              tooltip: 'Ubah status',
              onSelected: onStatusChanged,
              itemBuilder: (context) => TaskStatus.values
                  .map(
                    (status) => PopupMenuItem<TaskStatus>(
                      value: status,
                      child: StatusChip(status: status, compact: true),
                    ),
                  )
                  .toList(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: statusSoftColor(task.status),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: StatusChip(status: task.status, compact: true),
                    ),
                    FaIcon(
                      FontAwesomeIcons.chevronDown,
                      size: 10,
                      color: statusColor(task.status),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuLine extends StatelessWidget {
  const _MenuLine({
    required this.icon,
    required this.label,
    required this.color,
  });

  final FaIconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        FaIcon(icon, size: 13, color: color),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: <Widget>[
          FaIcon(statusIcon(status), size: 22, color: AppColors.slate300),
          const SizedBox(height: 10),
          const Text(
            'Belum ada tugas',
            style: TextStyle(
              color: AppColors.slate500,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
