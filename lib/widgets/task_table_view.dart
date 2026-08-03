import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/app_colors.dart';
import '../core/date_utils.dart';
import '../models/task_model.dart';
import 'task_progress.dart';
import 'task_visuals.dart';

class TaskTableView extends StatelessWidget {
  const TaskTableView({
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            color: AppColors.navy,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: <Widget>[
                const FaIcon(
                  FontAwesomeIcons.tableList,
                  size: 16,
                  color: AppColors.white,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'DAILY WORK 2026',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${tasks.length} tugas',
                  style: const TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (tasks.isEmpty)
            const _EmptyTable()
          else
            Scrollbar(
              thumbVisibility: false,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.slate100),
                  headingTextStyle: const TextStyle(
                    color: AppColors.slate700,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  dataTextStyle: const TextStyle(
                    color: AppColors.slate700,
                    fontSize: 12,
                  ),
                  horizontalMargin: 18,
                  columnSpacing: 24,
                  dataRowMinHeight: 106,
                  dataRowMaxHeight: 150,
                  dividerThickness: 1,
                  columns: const <DataColumn>[
                    DataColumn(label: Text('TANGGAL')),
                    DataColumn(label: Text('URAIAN PEKERJAAN')),
                    DataColumn(label: Text('KETERANGAN')),
                    DataColumn(label: Text('PIC')),
                    DataColumn(label: Text('RINCIAN TINDAK LANJUT')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('AKSI')),
                  ],
                  rows: tasks.map((task) => _buildRow(context, task)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  DataRow _buildRow(BuildContext context, TaskModel task) {
    return DataRow(
      cells: <DataCell>[
        DataCell(
          SizedBox(
            width: 82,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const FaIcon(
                  FontAwesomeIcons.calendarDays,
                  size: 12,
                  color: AppColors.slate500,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    formatDate(task.tanggal),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 230,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  task.uraianPekerjaan,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                PriorityChip(priority: task.prioritas),
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 220,
            child: Text(
              task.keterangan.isEmpty ? '-' : task.keterangan,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.45),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 100,
            child: Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDBEAFE),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.user,
                    size: 11,
                    color: AppColors.royalBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.pic.isEmpty ? '-' : task.pic,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ...task.rincianTindakLanjut
                    .take(2)
                    .toList()
                    .asMap()
                    .entries
                    .map(
                      (entry) => _SubTaskLine(
                        text: entry.value.text,
                        isCompleted: entry.value.isCompleted,
                        onTap: () => onSubTaskToggle(task, entry.key),
                      ),
                    ),
                if (task.rincianTindakLanjut.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      '+${task.rincianTindakLanjut.length - 2} rincian lainnya',
                      style: const TextStyle(
                        color: AppColors.royalBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                TaskProgress(task: task, compact: true),
              ],
            ),
          ),
        ),
        DataCell(
          PopupMenuButton<TaskStatus>(
            tooltip: 'Ubah status',
            onSelected: (status) => onStatusChanged(task, status),
            itemBuilder: (context) => TaskStatus.values
                .map(
                  (status) => PopupMenuItem<TaskStatus>(
                    value: status,
                    child: StatusChip(status: status, compact: true),
                  ),
                )
                .toList(),
            child: StatusChip(status: task.status),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ActionButton(
                tooltip: 'Edit tugas',
                icon: FontAwesomeIcons.penToSquare,
                color: AppColors.royalBlue,
                onTap: () => onEdit(task),
              ),
              const SizedBox(width: 6),
              _ActionButton(
                tooltip: 'Hapus tugas',
                icon: FontAwesomeIcons.trashCan,
                color: AppColors.danger,
                onTap: () => onDelete(task),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubTaskLine extends StatelessWidget {
  const _SubTaskLine({
    required this.text,
    required this.isCompleted,
    required this.onTap,
  });

  final String text;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: <Widget>[
            FaIcon(
              isCompleted
                  ? FontAwesomeIcons.solidSquareCheck
                  : FontAwesomeIcons.square,
              size: 14,
              color: isCompleted ? AppColors.success : AppColors.slate400,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isCompleted ? AppColors.slate500 : AppColors.slate700,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String tooltip;
  final FaIconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(icon, size: 13, color: color),
        ),
      ),
    );
  }
}

class _EmptyTable extends StatelessWidget {
  const _EmptyTable();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: <Widget>[
          FaIcon(
            FontAwesomeIcons.clipboardList,
            size: 32,
            color: AppColors.slate300,
          ),
          SizedBox(height: 14),
          Text(
            'Belum ada tugas yang ditampilkan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.slate700,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Tambahkan tugas baru atau sesuaikan filter pencarian.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
