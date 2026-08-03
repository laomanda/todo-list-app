import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_model.dart';

abstract interface class TaskStorage {
  Future<List<TaskModel>> load();
  Future<void> save(List<TaskModel> tasks);
  Future<void> clear();
}

class TaskStorageService implements TaskStorage {
  TaskStorageService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'daily_work_2026_tasks_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<TaskModel>> load() async {
    final raw = await _preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return <TaskModel>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <TaskModel>[];
      return decoded
          .whereType<Map>()
          .map((item) => TaskModel.fromJson(Map<String, dynamic>.from(item)))
          .where((task) => task.uraianPekerjaan.isNotEmpty)
          .toList();
    } on FormatException {
      return <TaskModel>[];
    }
  }

  @override
  Future<void> save(List<TaskModel> tasks) {
    final payload = jsonEncode(tasks.map((task) => task.toJson()).toList());
    return _preferences.setString(_storageKey, payload);
  }

  @override
  Future<void> clear() => _preferences.remove(_storageKey);
}
