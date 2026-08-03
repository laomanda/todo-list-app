import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:daily_work_2026_manager/main.dart';
import 'package:daily_work_2026_manager/models/task_model.dart';
import 'package:daily_work_2026_manager/services/task_storage_service.dart';

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

    expect(find.text('todo list jakkob'), findsOneWidget);
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
}
