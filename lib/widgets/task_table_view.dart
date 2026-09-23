import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/app_colors.dart';
import '../core/date_utils.dart';
import '../models/task_model.dart';
import 'task_progress.dart';
import 'task_visuals.dart';

class TaskTableView extends StatefulWidget {
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
  State<TaskTableView> createState() => _TaskTableViewState();
}

class _TaskTableViewState extends State<TaskTableView> {
  int _currentPage = 0;
  int _pageSize = 10;
  static const List<int> _pageSizeOptions = <int>[5, 10, 25, 50];
  late final ScrollController _scrollController;

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
  void didUpdateWidget(covariant TaskTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final total = widget.tasks.length;
    final maxPage = total == 0 ? 0 : (total - 1) ~/ _pageSize;
    if (_currentPage > maxPage) {
      setState(() {
        _currentPage = maxPage;
      });
    }
  }

  void _setPageSize(int newSize) {
    setState(() {
      _pageSize = newSize;
      final maxPage = widget.tasks.isEmpty ? 0 : (widget.tasks.length - 1) ~/ newSize;
      if (_currentPage > maxPage) {
        _currentPage = maxPage;
      }
    });
  }

  void _goToPage(int page) {
    final total = widget.tasks.length;
    final maxPage = total == 0 ? 0 : (total - 1) ~/ _pageSize;
    final target = page.clamp(0, maxPage);
    if (target != _currentPage) {
      setState(() {
        _currentPage = target;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalTasks = widget.tasks.length;
    final totalPages = totalTasks == 0 ? 1 : ((totalTasks - 1) ~/ _pageSize) + 1;
    final safePage = _currentPage.clamp(0, totalPages - 1);
    final startIndex = totalTasks == 0 ? 0 : safePage * _pageSize;
    final endIndex = (startIndex + _pageSize > totalTasks) ? totalTasks : startIndex + _pageSize;
    final pageTasks = totalTasks == 0
        ? const <TaskModel>[]
        : widget.tasks.sublist(startIndex, endIndex);

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
                  '$totalTasks tugas',
                  style: const TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (totalTasks == 0)
            const _EmptyTable()
          else ...<Widget>[
            Scrollbar(
              controller: _scrollController,
              thumbVisibility: false,
              child: SingleChildScrollView(
                controller: _scrollController,
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
                  rows: pageTasks.map((task) => _buildRow(context, task)).toList(),
                ),
              ),
            ),
            const Divider(height: 1),
            _PaginationFooter(
              totalTasks: totalTasks,
              startIndex: startIndex,
              endIndex: endIndex,
              currentPage: safePage,
              totalPages: totalPages,
              pageSize: _pageSize,
              pageSizeOptions: _pageSizeOptions,
              onPageSizeChanged: _setPageSize,
              onFirstPage: safePage > 0 ? () => _goToPage(0) : null,
              onPreviousPage: safePage > 0 ? () => _goToPage(safePage - 1) : null,
              onNextPage: safePage < totalPages - 1 ? () => _goToPage(safePage + 1) : null,
              onLastPage: safePage < totalPages - 1 ? () => _goToPage(totalPages - 1) : null,
            ),
          ],
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
                        onTap: () => widget.onSubTaskToggle(task, entry.key),
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
            onSelected: (status) => widget.onStatusChanged(task, status),
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
                onTap: () => widget.onEdit(task),
              ),
              const SizedBox(width: 6),
              _ActionButton(
                tooltip: 'Hapus tugas',
                icon: FontAwesomeIcons.trashCan,
                color: AppColors.danger,
                onTap: () => widget.onDelete(task),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.totalTasks,
    required this.startIndex,
    required this.endIndex,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.pageSizeOptions,
    required this.onPageSizeChanged,
    required this.onFirstPage,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onLastPage,
  });

  final int totalTasks;
  final int startIndex;
  final int endIndex;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final List<int> pageSizeOptions;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback? onFirstPage;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final VoidCallback? onLastPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final infoText = Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const FaIcon(
                FontAwesomeIcons.barsStaggered,
                size: 11,
                color: AppColors.slate400,
              ),
              const SizedBox(width: 8),
              Text(
                'Menampilkan ${startIndex + 1}–$endIndex dari $totalTasks tugas',
                style: const TextStyle(
                  color: AppColors.slate600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          final controls = Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Baris:',
                    style: TextStyle(
                      color: AppColors.slate500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: pageSize,
                        isDense: true,
                        icon: const FaIcon(
                          FontAwesomeIcons.chevronDown,
                          size: 10,
                          color: AppColors.slate500,
                        ),
                        items: pageSizeOptions
                            .map(
                              (size) => DropdownMenuItem<int>(
                                value: size,
                                child: Text(
                                  size.toString(),
                                  style: const TextStyle(
                                    color: AppColors.slate900,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) onPageSizeChanged(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                height: 16,
                width: 1,
                color: AppColors.slate200,
              ),
              Text(
                'Hal ${currentPage + 1} dari $totalPages',
                style: const TextStyle(
                  color: AppColors.slate700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _PaginationButton(
                    tooltip: 'Halaman pertama',
                    icon: FontAwesomeIcons.anglesLeft,
                    onPressed: onFirstPage,
                  ),
                  const SizedBox(width: 4),
                  _PaginationButton(
                    tooltip: 'Halaman sebelumnya',
                    icon: FontAwesomeIcons.chevronLeft,
                    onPressed: onPreviousPage,
                  ),
                  const SizedBox(width: 4),
                  _PaginationButton(
                    tooltip: 'Halaman berikutnya',
                    icon: FontAwesomeIcons.chevronRight,
                    onPressed: onNextPage,
                  ),
                  const SizedBox(width: 4),
                  _PaginationButton(
                    tooltip: 'Halaman terakhir',
                    icon: FontAwesomeIcons.anglesRight,
                    onPressed: onLastPage,
                  ),
                ],
              ),
            ],
          );

          return SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 10,
              children: <Widget>[
                infoText,
                controls,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  const _PaginationButton({
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
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? AppColors.white : AppColors.slate100.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: enabled ? AppColors.slate300 : AppColors.slate200,
            ),
          ),
          child: FaIcon(
            icon,
            size: 10,
            color: enabled ? AppColors.slate700 : AppColors.slate300,
          ),
        ),
      ),
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
