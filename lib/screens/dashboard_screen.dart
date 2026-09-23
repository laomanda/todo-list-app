import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../services/task_file_service.dart';
import '../widgets/filter_toolbar.dart';
import '../widgets/kanban_board.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_form.dart';
import '../widgets/task_table_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  final _fileService = const TaskFileService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openTaskForm([TaskModel? task]) async {
    if (!mounted) return;
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 720;
    final result = isCompact
        ? await showModalBottomSheet<TaskModel>(
            // ignore: use_build_context_synchronously
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (sheetContext) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(sheetContext).height * 0.94,
                child: TaskForm(
                  initialTask: task,
                  onSubmit: (value) => Navigator.pop(sheetContext, value),
                  onCancel: () => Navigator.pop(sheetContext),
                ),
              ),
            ),
          )
        : await showDialog<TaskModel>(
            // ignore: use_build_context_synchronously
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => Dialog(
              insetPadding: const EdgeInsets.all(24),
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 760,
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.92,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: TaskForm(
                    initialTask: task,
                    onSubmit: (value) => Navigator.pop(dialogContext, value),
                    onCancel: () => Navigator.pop(dialogContext),
                  ),
                ),
              ),
            ),
          );

    if (result == null || !mounted) return;
    final provider = context.read<TaskProvider>();
    if (task == null) {
      await provider.addTask(result);
      if (mounted) _showMessage('Tugas baru berhasil ditambahkan.');
    } else {
      await provider.updateTask(result);
      if (mounted) _showMessage('Perubahan tugas berhasil disimpan.');
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await _confirm(
      title: 'Hapus tugas?',
      message:
          'Tugas "${task.uraianPekerjaan}" akan dihapus dari perangkat ini.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<TaskProvider>().deleteTask(task.id);
    if (mounted) _showMessage('Tugas berhasil dihapus.');
  }

  Future<void> _exportJson() async {
    final tasks = context.read<TaskProvider>().tasks;
    try {
      final saved = await _fileService.exportJson(tasks);
      if (mounted && saved) _showMessage('Backup JSON berhasil diekspor.');
    } catch (_) {
      if (mounted) _showMessage('Ekspor JSON gagal.', isError: true);
    }
  }

  Future<void> _exportCsv() async {
    final tasks = context.read<TaskProvider>().tasks;
    try {
      final saved = await _fileService.exportCsv(tasks);
      if (mounted && saved) _showMessage('Data CSV berhasil diekspor.');
    } catch (_) {
      if (mounted) _showMessage('Ekspor CSV gagal.', isError: true);
    }
  }

  Future<void> _importJson() async {
    try {
      final tasks = await _fileService.importJson();
      if (tasks == null || !mounted) return;
      final confirmed = await _confirm(
        title: 'Pulihkan data backup?',
        message:
            '${tasks.length} tugas ditemukan. Data saat ini akan diganti dengan isi backup.',
        confirmLabel: 'Pulihkan',
      );
      if (!confirmed || !mounted) return;
      await context.read<TaskProvider>().replaceAll(tasks);
      _searchController.clear();
      if (mounted) _showMessage('${tasks.length} tugas berhasil dipulihkan.');
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } catch (_) {
      if (mounted) _showMessage('Impor JSON gagal.', isError: true);
    }
  }

  Future<void> _importCsv() async {
    try {
      final tasks = await _fileService.importCsv();
      if (tasks == null || !mounted) return;
      final confirmed = await _confirm(
        title: 'Impor data CSV?',
        message:
            '${tasks.length} tugas ditemukan. Data saat ini akan diganti dengan isi file CSV.',
        confirmLabel: 'Impor CSV',
      );
      if (!confirmed || !mounted) return;
      await context.read<TaskProvider>().replaceAll(tasks);
      _searchController.clear();
      if (mounted) {
        _showMessage('${tasks.length} tugas berhasil diimpor dari CSV.');
      }
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } catch (_) {
      if (mounted) _showMessage('Impor CSV gagal.', isError: true);
    }
  }

  Future<void> _loadSamples() async {
    final provider = context.read<TaskProvider>();
    if (provider.tasks.isNotEmpty) {
      final confirmed = await _confirm(
        title: 'Muat data sampel?',
        message:
            'Data saat ini akan diganti dengan empat contoh tugas profesional.',
        confirmLabel: 'Muat Sampel',
      );
      if (!confirmed || !mounted) return;
    }
    await provider.loadSampleData();
    _searchController.clear();
    if (mounted) _showMessage('Data sampel berhasil dimuat.');
  }

  Future<void> _resetData() async {
    final provider = context.read<TaskProvider>();
    if (provider.tasks.isEmpty) return;
    final confirmed = await _confirm(
      title: 'Reset seluruh data?',
      message:
          'Semua tugas lokal akan dihapus. Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Reset Data',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await provider.resetData();
    _searchController.clear();
    if (mounted) _showMessage('Seluruh data tugas telah direset.');
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: FaIcon(
              destructive
                  ? FontAwesomeIcons.triangleExclamation
                  : FontAwesomeIcons.circleInfo,
              color: destructive ? AppColors.danger : AppColors.royalBlue,
              size: 24,
            ),
            title: Text(title, textAlign: TextAlign.center),
            content: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate600, height: 1.45),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: <Widget>[
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(dialogContext, false),
                icon: const FaIcon(FontAwesomeIcons.xmark, size: 12),
                label: const Text('Batal'),
              ),
              FilledButton.icon(
                style: destructive
                    ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
                    : null,
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: FaIcon(
                  destructive
                      ? FontAwesomeIcons.trashCan
                      : FontAwesomeIcons.circleCheck,
                  size: 12,
                ),
                label: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? AppColors.danger : AppColors.slate900,
          content: Row(
            children: <Widget>[
              FaIcon(
                isError
                    ? FontAwesomeIcons.triangleExclamation
                    : FontAwesomeIcons.circleCheck,
                color: AppColors.white,
                size: 15,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const _LoadingView();
            }
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 600 ? 14 : 24,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _DashboardHeader(
                        onAdd: () => _openTaskForm(),
                        onExportCsv: _exportCsv,
                        onImportCsv: _importCsv,
                        onExportJson: _exportJson,
                        onImportJson: _importJson,
                        onLoadSamples: _loadSamples,
                        onReset: _resetData,
                      ),
                      if (provider.errorMessage != null) ...<Widget>[
                        const SizedBox(height: 14),
                        _ErrorBanner(message: provider.errorMessage!),
                      ],
                      const SizedBox(height: 18),
                      _Statistics(provider: provider),
                      const SizedBox(height: 18),
                      FilterToolbar(
                        searchController: _searchController,
                        provider: provider,
                        onClear: () {
                          _searchController.clear();
                          provider.clearFilters();
                        },
                      ),
                      const SizedBox(height: 18),
                      _ViewHeader(provider: provider),
                      const SizedBox(height: 12),
                      if (provider.viewMode == TaskViewMode.table)
                        TaskTableView(
                          tasks: provider.filteredTasks,
                          onEdit: _openTaskForm,
                          onDelete: _deleteTask,
                          onStatusChanged: (task, status) =>
                              provider.changeStatus(task.id, status),
                          onSubTaskToggle: (task, index) =>
                              provider.toggleSubTask(task.id, index),
                        )
                      else
                        KanbanBoard(
                          tasks: provider.filteredTasks,
                          onEdit: _openTaskForm,
                          onDelete: _deleteTask,
                          onStatusChanged: (task, status) =>
                              provider.changeStatus(task.id, status),
                          onSubTaskToggle: (task, index) =>
                              provider.toggleSubTask(task.id, index),
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.onAdd,
    required this.onExportCsv,
    required this.onImportCsv,
    required this.onExportJson,
    required this.onImportJson,
    required this.onLoadSamples,
    required this.onReset,
  });

  final VoidCallback onAdd;
  final VoidCallback onExportCsv;
  final VoidCallback onImportCsv;
  final VoidCallback onExportJson;
  final VoidCallback onImportJson;
  final VoidCallback onLoadSamples;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final brand = Row(
            mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.listCheck,
                  color: AppColors.navy,
                  size: 21,
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'todo list jakkob',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pusat kendali tugas harian profesional',
                      style: TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 9,
            runSpacing: 9,
            alignment: WrapAlignment.end,
            children: <Widget>[
              PopupMenuButton<String>(
                tooltip: 'Kelola data',
                onSelected: (value) {
                  switch (value) {
                    case 'csv':
                      onExportCsv();
                    case 'import-csv':
                      onImportCsv();
                    case 'json':
                      onExportJson();
                    case 'import':
                      onImportJson();
                    case 'sample':
                      onLoadSamples();
                    case 'reset':
                      onReset();
                  }
                },
                itemBuilder: (context) => const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'csv',
                    child: _HeaderMenuItem(
                      icon: FontAwesomeIcons.fileCsv,
                      label: 'Ekspor CSV',
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'import-csv',
                    child: _HeaderMenuItem(
                      icon: FontAwesomeIcons.fileImport,
                      label: 'Impor CSV',
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'json',
                    child: _HeaderMenuItem(
                      icon: FontAwesomeIcons.fileCode,
                      label: 'Ekspor JSON',
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'import',
                    child: _HeaderMenuItem(
                      icon: FontAwesomeIcons.fileImport,
                      label: 'Impor JSON',
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'sample',
                    child: _HeaderMenuItem(
                      icon: FontAwesomeIcons.database,
                      label: 'Muat Data Sampel',
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'reset',
                    child: _HeaderMenuItem(
                      icon: FontAwesomeIcons.rotateLeft,
                      label: 'Reset Data',
                      color: AppColors.danger,
                    ),
                  ),
                ],
                child: const _HeaderOutlineButton(
                  icon: FontAwesomeIcons.database,
                  label: 'Kelola Data',
                ),
              ),
              FilledButton.icon(
                key: const ValueKey('add-task-button'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.navy,
                ),
                onPressed: onAdd,
                icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                label: const Text('Tambah Tugas'),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[brand, const SizedBox(height: 18), actions],
            );
          }
          return Row(
            children: <Widget>[
              Expanded(child: brand),
              const SizedBox(width: 20),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _HeaderOutlineButton extends StatelessWidget {
  const _HeaderOutlineButton({required this.icon, required this.label});

  final FaIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF93C5FD)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FaIcon(icon, size: 13, color: AppColors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 9),
          const FaIcon(
            FontAwesomeIcons.chevronDown,
            size: 10,
            color: Color(0xFFBFDBFE),
          ),
        ],
      ),
    );
  }
}

class _HeaderMenuItem extends StatelessWidget {
  const _HeaderMenuItem({
    required this.icon,
    required this.label,
    this.color = AppColors.slate700,
  });

  final FaIconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        FaIcon(icon, size: 14, color: color),
        const SizedBox(width: 11),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _Statistics extends StatelessWidget {
  const _Statistics({required this.provider});

  final TaskProvider provider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1080
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            SizedBox(
              width: width,
              child: StatCard(
                label: 'Total Tugas',
                value: provider.totalCount,
                icon: FontAwesomeIcons.clipboardList,
                color: AppColors.navy,
                softColor: const Color(0xFFDBEAFE),
              ),
            ),
            SizedBox(
              width: width,
              child: StatCard(
                label: 'Dalam Proses',
                value: provider.inProgressCount,
                icon: FontAwesomeIcons.spinner,
                color: AppColors.royalBlue,
                softColor: const Color(0xFFDBEAFE),
              ),
            ),
            SizedBox(
              width: width,
              child: StatCard(
                label: 'Pending',
                value: provider.pendingCount,
                icon: FontAwesomeIcons.clock,
                color: AppColors.warning,
                softColor: AppColors.warningSoft,
              ),
            ),
            SizedBox(
              width: width,
              child: StatCard(
                label: 'Selesai',
                value: provider.completedCount,
                icon: FontAwesomeIcons.circleCheck,
                color: AppColors.success,
                softColor: AppColors.successSoft,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ViewHeader extends StatelessWidget {
  const _ViewHeader({required this.provider});

  final TaskProvider provider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Daftar Pekerjaan',
              style: TextStyle(
                color: AppColors.slate900,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${provider.filteredTasks.length} dari ${provider.totalCount} tugas ditampilkan',
              style: const TextStyle(color: AppColors.slate500, fontSize: 12),
            ),
          ],
        );
        final toggle = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            border: Border.all(color: AppColors.slate200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _ViewToggleButton(
                key: const ValueKey('table-view-button'),
                label: 'Tabel',
                icon: FontAwesomeIcons.tableList,
                selected: provider.viewMode == TaskViewMode.table,
                onTap: () => provider.setViewMode(TaskViewMode.table),
              ),
              _ViewToggleButton(
                key: const ValueKey('kanban-view-button'),
                label: 'Kanban',
                icon: FontAwesomeIcons.tableColumns,
                selected: provider.viewMode == TaskViewMode.kanban,
                onTap: () => provider.setViewMode(TaskViewMode.kanban),
              ),
            ],
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              title,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: toggle),
            ],
          );
        }
        return Row(
          children: <Widget>[
            Expanded(child: title),
            toggle,
          ],
        );
      },
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  const _ViewToggleButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final FaIconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: selected ? Border.all(color: AppColors.slate200) : null,
        ),
        child: Row(
          children: <Widget>[
            FaIcon(
              icon,
              size: 12,
              color: selected ? AppColors.royalBlue : AppColors.slate500,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.slate900 : AppColors.slate500,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: <Widget>[
          const FaIcon(
            FontAwesomeIcons.triangleExclamation,
            size: 14,
            color: AppColors.danger,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FaIcon(
            FontAwesomeIcons.spinner,
            size: 28,
            color: AppColors.royalBlue,
          ),
          SizedBox(height: 14),
          Text(
            'Memuat data pekerjaan...',
            style: TextStyle(
              color: AppColors.slate600,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
