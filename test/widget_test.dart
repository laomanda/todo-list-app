import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:daily_work_2026_manager/main.dart';
import 'package:daily_work_2026_manager/models/task_model.dart';
import 'package:daily_work_2026_manager/services/task_storage_service.dart';
import 'package:daily_work_2026_manager/widgets/productivity_chart.dart';
import 'package:daily_work_2026_manager/widgets/task_form.dart';

class _MemoryStorage implements TaskStorage {
  List<TaskModel> tasks = <TaskModel>[];

  @override
  Future<void> clear() async => tasks = <TaskModel>[];

  @override
  Future<List<TaskModel>> load() async => List<TaskModel>.from(tasks);

  @override
  Future<void> save(List<TaskModel> value) async =>
      tasks = List<TaskModel>.from(value);
}

void main() {
  testWidgets('dashboard loads and switches between table and kanban', (
    tester,
  ) async {
    await tester.pumpWidget(DailyWorkApp(storage: _MemoryStorage()));
    await tester.pumpAndSettle();

    expect(find.text('Todo List Jakkob'), findsOneWidget);
    expect(find.text('DAILY WORK 2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('table-view-button')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('kanban-view-button')),
    );
    await tester.tap(find.byKey(const ValueKey('kanban-view-button')));
    await tester.pumpAndSettle();
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Dalam Proses'), findsWidgets);
    expect(find.text('Review'), findsWidgets);
    expect(find.text('Selesai'), findsWidgets);
  });

  testWidgets('sample data can be loaded and new task form validates', (
    tester,
  ) async {
    await tester.pumpWidget(DailyWorkApp(storage: _MemoryStorage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kelola Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muat Data Sampel'));
    await tester.pumpAndSettle();
    expect(find.text('Finalisasi laporan operasional bulanan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-task-button')));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Tugas Baru'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('task-save-button')));
    await tester.pumpAndSettle();
    expect(find.text('Uraian pekerjaan wajib diisi.'), findsOneWidget);
  });

  testWidgets('table pagination displays page slices and navigates correctly', (
    tester,
  ) async {
    final storage = _MemoryStorage();
    storage.tasks = List<TaskModel>.generate(
      12,
      (i) => TaskModel(
        id: 'task-$i',
        tanggal: DateTime(2026, 8, 1),
        uraianPekerjaan: 'Tugas ke-$i',
        keterangan: 'Keterangan $i',
        pic: 'User',
        rincianTindakLanjut: const [],
        status: TaskStatus.pending,
        prioritas: TaskPriority.medium,
      ),
    );

    await tester.pumpWidget(DailyWorkApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Menampilkan 1–10 dari 12 tugas'), findsOneWidget);
    expect(find.text('Hal 1 dari 2'), findsOneWidget);
    expect(find.text('Tugas ke-0'), findsOneWidget);
    expect(find.text('Tugas ke-11'), findsNothing);

    await tester.scrollUntilVisible(
      find.byTooltip('Halaman berikutnya'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Halaman berikutnya'));
    await tester.pumpAndSettle();

    expect(find.text('Menampilkan 11–12 dari 12 tugas'), findsOneWidget);
    expect(find.text('Hal 2 dari 2'), findsOneWidget);
    expect(find.text('Tugas ke-11'), findsOneWidget);
    expect(find.text('Tugas ke-0'), findsNothing);

    await tester.scrollUntilVisible(
      find.byTooltip('Halaman sebelumnya'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Halaman sebelumnya'));
    await tester.pumpAndSettle();

    expect(find.text('Menampilkan 1–10 dari 12 tugas'), findsOneWidget);
    expect(find.text('Hal 1 dari 2'), findsOneWidget);
  });

  testWidgets('kanban column paginates cards when exceeding limit', (
    tester,
  ) async {
    final storage = _MemoryStorage();
    storage.tasks = List<TaskModel>.generate(
      7,
      (i) => TaskModel(
        id: 'k-task-$i',
        tanggal: DateTime(2026, 8, 1),
        uraianPekerjaan: 'Kanban Task $i',
        keterangan: 'Desc $i',
        pic: 'User',
        rincianTindakLanjut: const [],
        status: TaskStatus.pending,
        prioritas: TaskPriority.medium,
      ),
    );

    await tester.pumpWidget(DailyWorkApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('kanban-view-button')),
    );
    await tester.tap(find.byKey(const ValueKey('kanban-view-button')));
    await tester.pumpAndSettle();

    expect(find.text('1–5 dari 7'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('Kanban Task 0'), findsOneWidget);
    expect(find.text('Kanban Task 6'), findsNothing);

    await tester.scrollUntilVisible(
      find.byTooltip('Halaman berikutnya').first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Halaman berikutnya').first);
    await tester.pumpAndSettle();

    expect(find.text('6–7 dari 7'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('Kanban Task 6'), findsOneWidget);
    expect(find.text('Kanban Task 0'), findsNothing);
  });

  testWidgets('task form displays existing PIC quick chips and allows selection',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskForm(
            existingPics: const ['Budi Santoso', 'Siti Rahma'],
            onSubmit: (_) {},
            onCancel: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilih cepat:'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Siti Rahma'), findsOneWidget);

    final picFieldFinder = find.byKey(const ValueKey('task-pic-field'));
    expect(picFieldFinder, findsOneWidget);

    // Tap quick chip 'Budi Santoso'
    await tester.tap(find.text('Budi Santoso'));
    await tester.pumpAndSettle();

    final picField = tester.widget<TextFormField>(picFieldFinder);
    expect(picField.controller?.text, 'Budi Santoso');

    // Clear icon appears and works
    final clearBtnFinder = find.byTooltip('Hapus nama');
    expect(clearBtnFinder, findsOneWidget);
    await tester.tap(clearBtnFinder);
    await tester.pumpAndSettle();

    expect(picField.controller?.text, '');
  });

  testWidgets('productivity chart renders 3 days and handles collapse/expand',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final testTasks = [
      TaskModel(
        id: 'p-1',
        tanggal: DateTime(2026, 9, 21),
        uraianPekerjaan: 'Task A',
        keterangan: '',
        pic: 'Andi',
        rincianTindakLanjut: const [],
        status: TaskStatus.completed,
        prioritas: TaskPriority.high,
      ),
      TaskModel(
        id: 'p-2',
        tanggal: DateTime(2026, 9, 22),
        uraianPekerjaan: 'Task B',
        keterangan: '',
        pic: 'Budi',
        rincianTindakLanjut: const [],
        status: TaskStatus.inProgress,
        prioritas: TaskPriority.medium,
      ),
      TaskModel(
        id: 'p-3',
        tanggal: DateTime(2026, 9, 23),
        uraianPekerjaan: 'Task C',
        keterangan: '',
        pic: 'Citra',
        rincianTindakLanjut: const [],
        status: TaskStatus.completed,
        prioritas: TaskPriority.high,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProductivityChart(tasks: testTasks),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Diagram Produktivitas (3 Hari)'), findsOneWidget);
    expect(find.text('3-Day Window'), findsOneWidget);
    expect(find.text('Rata-rata Produktivitas'), findsOneWidget);

    // Toggle collapse
    final toggleCollapseFinder = find.byTooltip('Sembunyikan diagram');
    expect(toggleCollapseFinder, findsOneWidget);
    await tester.tap(toggleCollapseFinder);
    await tester.pumpAndSettle();

    // Diagram contents are hidden
    expect(find.text('Rata-rata Produktivitas'), findsNothing);

    // Toggle expand
    final toggleExpandFinder = find.byTooltip('Tampilkan diagram');
    expect(toggleExpandFinder, findsOneWidget);
    await tester.tap(toggleExpandFinder);
    await tester.pumpAndSettle();

    expect(find.text('Rata-rata Produktivitas'), findsOneWidget);
  });
}


