import 'package:flutter_test/flutter_test.dart';

import 'package:daily_work_2026_manager/models/sub_task_model.dart';
import 'package:daily_work_2026_manager/models/task_model.dart';
import 'package:daily_work_2026_manager/providers/task_provider.dart';
import 'package:daily_work_2026_manager/services/task_file_service.dart';
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

TaskModel _task({
  required String id,
  required String title,
  required TaskStatus status,
  String pic = 'Andini',
}) {
  return TaskModel(
    id: id,
    tanggal: DateTime(2026, 8, 3),
    uraianPekerjaan: title,
    keterangan: 'Catatan $title',
    pic: pic,
    rincianTindakLanjut: const <SubTaskModel>[
      SubTaskModel(text: 'Satu', isCompleted: true),
      SubTaskModel(text: 'Dua'),
    ],
    status: status,
    prioritas: TaskPriority.high,
  );
}

void main() {
  test('provider computes statistics, filters, and persists changes', () async {
    final storage = _MemoryStorage();
    final provider = TaskProvider(storage);
    await provider.initialize();
    await provider.addTask(
      _task(id: '1', title: 'Laporan', status: TaskStatus.inProgress),
    );
    await provider.addTask(
      _task(id: '2', title: 'Audit', status: TaskStatus.pending, pic: 'Bima'),
    );

    expect(provider.totalCount, 2);
    expect(provider.inProgressCount, 1);
    expect(provider.pendingCount, 1);
    provider.setPicFilter('Bima');
    expect(provider.filteredTasks.single.uraianPekerjaan, 'Audit');

    await provider.toggleSubTask('1', 1);
    expect(provider.tasks.first.progressPercent, 100);
    await provider.changeStatus('1', TaskStatus.completed);
    expect(provider.completedCount, 1);
    expect(storage.tasks.first.status, TaskStatus.completed);
  });

  test('task JSON round trip preserves task fields', () {
    final original = _task(
      id: 'round-trip',
      title: 'Rekonsiliasi',
      status: TaskStatus.review,
    );
    final restored = TaskModel.fromJson(original.toJson());

    expect(restored.id, original.id);
    expect(restored.tanggal, original.tanggal);
    expect(restored.status, original.status);
    expect(restored.prioritas, original.prioritas);
    expect(restored.rincianTindakLanjut[0].isCompleted, isTrue);
  });

  test('task CSV parse restores fields and sub-tasks properly', () {
    const csvContent =
        'Tanggal,Uraian Pekerjaan,Keterangan,PIC,Rincian Tindak Lanjut,Status,Prioritas,Progress\r\n'
        '2026-08-05,Koordinasi Rapat,Rapat pimpinan,Budi,[x] Siapkan materi | [ ] Kirim undangan,Dalam Proses,Tinggi,1/2 (50%)';

    const service = TaskFileService();
    final tasks = service.parseCsvData(csvContent);

    expect(tasks.length, 1);
    final task = tasks.first;
    expect(task.uraianPekerjaan, 'Koordinasi Rapat');
    expect(task.keterangan, 'Rapat pimpinan');
    expect(task.pic, 'Budi');
    expect(task.status, TaskStatus.inProgress);
    expect(task.prioritas, TaskPriority.high);
    expect(task.rincianTindakLanjut.length, 2);
    expect(task.rincianTindakLanjut[0].text, 'Siapkan materi');
    expect(task.rincianTindakLanjut[0].isCompleted, isTrue);
    expect(task.rincianTindakLanjut[1].text, 'Kirim undangan');
    expect(task.rincianTindakLanjut[1].isCompleted, isFalse);
  });
}
