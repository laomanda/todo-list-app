import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/app_colors.dart';
import '../core/date_utils.dart';
import '../models/task_model.dart';
import 'task_progress.dart';
import 'task_visuals.dart';

class KanbanBoard extends StatefulWidget {
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
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  late final ScrollController _scrollController;
  int _cardsPerColumn = 5;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.slate200),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.tableColumns,
                  size: 13,
                  color: AppColors.royalBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Papan Kanban Alur Kerja',
                      style: TextStyle(
                        color: AppColors.slate900,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${widget.tasks.length} tugas terbagi dalam 4 status',
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Batas kolom:',
                style: TextStyle(
                  color: AppColors.slate600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _cardsPerColumn,
                    isDense: true,
                    icon: const FaIcon(
                      FontAwesomeIcons.chevronDown,
                      size: 10,
                      color: AppColors.slate500,
                    ),
                    items: const <DropdownMenuItem<int>>[
                      DropdownMenuItem<int>(
                        value: 5,
                        child: Text(
                          '5 kartu / status',
                          style: TextStyle(
                            color: AppColors.slate900,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DropdownMenuItem<int>(
                        value: 10,
                        child: Text(
                          '10 kartu / status',
                          style: TextStyle(
                            color: AppColors.slate900,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DropdownMenuItem<int>(
                        value: 0,
                        child: Text(
                          'Tampilkan semua',
                          style: TextStyle(
                            color: AppColors.slate900,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _cardsPerColumn = value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.maxWidth;
            final columnWidth = available >= 1280
                ? (available - 36) / 4
                : 310.0;
            return Scrollbar(
              controller: _scrollController,
              thumbVisibility: false,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: TaskStatus.values.map((status) {
                    final columnTasks = widget.tasks
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
                          cardsPerPage: _cardsPerColumn,
                          onEdit: widget.onEdit,
                          onDelete: widget.onDelete,
                          onStatusChanged: widget.onStatusChanged,
                          onSubTaskToggle: widget.onSubTaskToggle,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _KanbanColumn extends StatefulWidget {
  const _KanbanColumn({
    required this.status,
    required this.tasks,
    required this.cardsPerPage,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
    required this.onSubTaskToggle,
  });

  final TaskStatus status;
  final List<TaskModel> tasks;
  final int cardsPerPage;
  final ValueChanged<TaskModel> onEdit;
  final ValueChanged<TaskModel> onDelete;
  final void Function(TaskModel task, TaskStatus status) onStatusChanged;
  final void Function(TaskModel task, int index) onSubTaskToggle;

  @override
  State<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<_KanbanColumn> {
  int _page = 0;

  @override
  void didUpdateWidget(covariant _KanbanColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cardsPerPage > 0 && widget.tasks.isNotEmpty) {
      final maxPage = (widget.tasks.length - 1) ~/ widget.cardsPerPage;
      if (_page > maxPage) {
        setState(() => _page = maxPage);
      }
    } else {
      if (_page != 0) {
        setState(() => _page = 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(widget.status);
    final totalTasks = widget.tasks.length;
    final isPaged = widget.cardsPerPage > 0 && totalTasks > widget.cardsPerPage;
    final totalPages = isPaged
        ? ((totalTasks - 1) ~/ widget.cardsPerPage) + 1
        : 1;
    final safePage = isPaged ? _page.clamp(0, totalPages - 1) : 0;
    final startIndex = isPaged ? safePage * widget.cardsPerPage : 0;
    final endIndex = isPaged
        ? (startIndex + widget.cardsPerPage > totalTasks
              ? totalTasks
              : startIndex + widget.cardsPerPage)
        : totalTasks;
    final displayedTasks = totalTasks == 0
        ? const <TaskModel>[]
        : widget.tasks.sublist(startIndex, endIndex);

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
                    color: statusSoftColor(widget.status),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: FaIcon(
                    statusIcon(widget.status),
                    size: 13,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.status.label,
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
                    color: statusSoftColor(widget.status),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    totalTasks.toString(),
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
            child: totalTasks == 0
                ? _EmptyColumn(status: widget.status)
                : Column(
                    children: <Widget>[
                      ...displayedTasks.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _KanbanCard(
                            task: task,
                            onEdit: () => widget.onEdit(task),
                            onDelete: () => widget.onDelete(task),
                            onStatusChanged: (value) =>
                                widget.onStatusChanged(task, value),
                            onSubTaskToggle: (index) =>
                                widget.onSubTaskToggle(task, index),
                          ),
                        ),
                      ),
                      if (isPaged)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.slate200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                '${startIndex + 1}–$endIndex dari $totalTasks',
                                style: const TextStyle(
                                  color: AppColors.slate500,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _MiniColumnPageButton(
                                    tooltip: 'Halaman sebelumnya',
                                    icon: FontAwesomeIcons.chevronLeft,
                                    onPressed: safePage > 0
                                        ? () => setState(
                                            () => _page = safePage - 1,
                                          )
                                        : null,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Text(
                                      '${safePage + 1}/$totalPages',
                                      style: const TextStyle(
                                        color: AppColors.slate700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  _MiniColumnPageButton(
                                    tooltip: 'Halaman berikutnya',
                                    icon: FontAwesomeIcons.chevronRight,
                                    onPressed: safePage < totalPages - 1
                                        ? () => setState(
                                            () => _page = safePage + 1,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MiniColumnPageButton extends StatelessWidget {
  const _MiniColumnPageButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final FaIconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? AppColors.white : AppColors.slate100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: enabled ? AppColors.slate300 : AppColors.slate200,
            ),
          ),
          child: FaIcon(
            icon,
            size: 9,
            color: enabled ? AppColors.slate700 : AppColors.slate300,
          ),
        ),
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
