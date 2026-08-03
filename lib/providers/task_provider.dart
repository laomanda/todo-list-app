import 'package:flutter/foundation.dart';

import '../models/sub_task_model.dart';
import '../models/task_model.dart';
import '../services/task_storage_service.dart';

enum TaskViewMode { table, kanban }

class TaskProvider extends ChangeNotifier {
  TaskProvider(this._storage);

  final TaskStorage _storage;
  List<TaskModel> _tasks = <TaskModel>[];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  String? _picFilter;
  TaskViewMode _viewMode = TaskViewMode.table;

  List<TaskModel> get tasks => List<TaskModel>.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  TaskStatus? get statusFilter => _statusFilter;
  TaskPriority? get priorityFilter => _priorityFilter;
  String? get picFilter => _picFilter;
  TaskViewMode get viewMode => _viewMode;

  int get totalCount => _tasks.length;
  int get pendingCount =>
      _tasks.where((task) => task.status == TaskStatus.pending).length;
  int get inProgressCount =>
      _tasks.where((task) => task.status == TaskStatus.inProgress).length;
  int get completedCount =>
      _tasks.where((task) => task.status == TaskStatus.completed).length;

  List<String> get pics {
    final values =
        _tasks
            .map((task) => task.pic.trim())
            .where((pic) => pic.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  List<TaskModel> get filteredTasks {
    final query = _searchQuery.trim().toLowerCase();
    final result = _tasks.where((task) {
      final matchesQuery =
          query.isEmpty ||
          task.uraianPekerjaan.toLowerCase().contains(query) ||
          task.keterangan.toLowerCase().contains(query) ||
          task.pic.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == null || task.status == _statusFilter;
      final matchesPriority =
          _priorityFilter == null || task.prioritas == _priorityFilter;
      final matchesPic = _picFilter == null || task.pic == _picFilter;
      return matchesQuery && matchesStatus && matchesPriority && matchesPic;
    }).toList()..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return result;
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tasks = await _storage.load();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Data lokal tidak dapat dimuat.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setStatusFilter(TaskStatus? value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setPriorityFilter(TaskPriority? value) {
    _priorityFilter = value;
    notifyListeners();
  }

  void setPicFilter(String? value) {
    _picFilter = value;
    notifyListeners();
  }

  void setViewMode(TaskViewMode value) {
    _viewMode = value;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _priorityFilter = null;
    _picFilter = null;
    notifyListeners();
  }

  Future<void> addTask(TaskModel task) async {
    _tasks.add(task);
    await _persist();
  }

  Future<void> updateTask(TaskModel task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    _tasks[index] = task;
    await _persist();
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((task) => task.id == id);
    await _persist();
  }

  Future<void> changeStatus(String id, TaskStatus status) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) return;
    _tasks[index] = _tasks[index].copyWith(status: status);
    await _persist();
  }

  Future<void> toggleSubTask(String taskId, int subTaskIndex) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex < 0) return;
    final task = _tasks[taskIndex];
    if (subTaskIndex < 0 || subTaskIndex >= task.rincianTindakLanjut.length) {
      return;
    }
    final subTasks = List<SubTaskModel>.from(task.rincianTindakLanjut);
    final current = subTasks[subTaskIndex];
    subTasks[subTaskIndex] = current.copyWith(
      isCompleted: !current.isCompleted,
    );
    _tasks[taskIndex] = task.copyWith(rincianTindakLanjut: subTasks);
    await _persist();
  }

  Future<void> replaceAll(List<TaskModel> tasks) async {
    _tasks = List<TaskModel>.from(tasks);
    clearFilters();
    await _persist();
  }

  Future<void> resetData() async {
    _tasks = <TaskModel>[];
    clearFilters();
    _errorMessage = null;
    await _storage.clear();
    notifyListeners();
  }

  Future<void> loadSampleData() async {
    _tasks = _sampleTasks();
    clearFilters();
    await _persist();
  }

  Future<void> _persist() async {
    notifyListeners();
    try {
      await _storage.save(_tasks);
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Perubahan belum dapat disimpan ke perangkat.';
      notifyListeners();
    }
  }

  List<TaskModel> _sampleTasks() {
    return <TaskModel>[
      TaskModel(
        id: 'sample-1',
        tanggal: DateTime(2026, 8, 3),
        uraianPekerjaan: 'Finalisasi laporan operasional bulanan',
        keterangan:
            'Konsolidasi data kinerja seluruh unit untuk rapat manajemen.',
        pic: 'Andini',
        rincianTindakLanjut: const <SubTaskModel>[
          SubTaskModel(
            text: 'Validasi data dari seluruh unit',
            isCompleted: true,
          ),
          SubTaskModel(text: 'Susun ringkasan eksekutif', isCompleted: true),
          SubTaskModel(text: 'Kirim draf untuk review'),
        ],
        status: TaskStatus.inProgress,
        prioritas: TaskPriority.high,
      ),
      TaskModel(
        id: 'sample-2',
        tanggal: DateTime(2026, 8, 4),
        uraianPekerjaan: 'Koordinasi jadwal audit internal',
        keterangan: 'Sinkronisasi agenda dan dokumen kesiapan audit.',
        pic: 'Bima',
        rincianTindakLanjut: const <SubTaskModel>[
          SubTaskModel(text: 'Konfirmasi auditor dan pemilik proses'),
          SubTaskModel(text: 'Bagikan daftar dokumen persiapan'),
        ],
        status: TaskStatus.pending,
        prioritas: TaskPriority.medium,
      ),
      TaskModel(
        id: 'sample-3',
        tanggal: DateTime(2026, 8, 1),
        uraianPekerjaan: 'Perbarui prosedur onboarding karyawan',
        keterangan: 'Penyelarasan alur kerja HR dan akses sistem.',
        pic: 'Citra',
        rincianTindakLanjut: const <SubTaskModel>[
          SubTaskModel(text: 'Review prosedur saat ini', isCompleted: true),
          SubTaskModel(text: 'Perbarui matriks akses', isCompleted: true),
          SubTaskModel(text: 'Validasi dengan HR dan IT', isCompleted: true),
        ],
        status: TaskStatus.review,
        prioritas: TaskPriority.high,
      ),
      TaskModel(
        id: 'sample-4',
        tanggal: DateTime(2026, 7, 30),
        uraianPekerjaan: 'Rekonsiliasi anggaran kuartal ketiga',
        keterangan: 'Pencocokan realisasi dan proyeksi biaya operasional.',
        pic: 'Damar',
        rincianTindakLanjut: const <SubTaskModel>[
          SubTaskModel(text: 'Tarik data realisasi', isCompleted: true),
          SubTaskModel(text: 'Validasi deviasi biaya', isCompleted: true),
        ],
        status: TaskStatus.completed,
        prioritas: TaskPriority.low,
      ),
    ];
  }
}
