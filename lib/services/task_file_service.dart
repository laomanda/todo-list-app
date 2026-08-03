import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/date_utils.dart';
import '../models/task_model.dart';
import 'task_file_reader.dart';

class TaskFileService {
  const TaskFileService();

  Future<bool> exportJson(List<TaskModel> tasks) async {
    final payload = <String, dynamic>{
      'application': 'todo list jakkob',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
    return _save(
      fileName: 'daily-work-2026-${toDateKey(DateTime.now())}.json',
      extension: 'json',
      bytes: Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
      ),
    );
  }

  Future<bool> exportCsv(List<TaskModel> tasks) async {
    final rows = <List<dynamic>>[
      <dynamic>[
        'Tanggal',
        'Uraian Pekerjaan',
        'Keterangan',
        'PIC',
        'Rincian Tindak Lanjut',
        'Status',
        'Prioritas',
        'Progress',
      ],
      ...tasks.map(
        (task) => <dynamic>[
          toDateKey(task.tanggal),
          task.uraianPekerjaan,
          task.keterangan,
          task.pic,
          task.rincianTindakLanjut
              .map((item) => '${item.isCompleted ? '[x]' : '[ ]'} ${item.text}')
              .join(' | '),
          task.status.label,
          task.prioritas.label,
          '${task.completedSubTaskCount}/${task.rincianTindakLanjut.length} '
              '(${task.progressPercent}%)',
        ],
      ),
    ];
    final csvData = const ListToCsvConverter(eol: '\r\n').convert(rows);
    return _save(
      fileName: 'daily-work-2026-${toDateKey(DateTime.now())}.csv',
      extension: 'csv',
      bytes: Uint8List.fromList(<int>[
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(csvData),
      ]),
    );
  }

  Future<List<TaskModel>?> importJson() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Pilih backup todo list jakkob',
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
      withData: true,
    );
    if (result == null) return null;

    final bytes = await readPickedFile(result.files.single);
    if (bytes == null) {
      throw const FormatException(
        'File tidak dapat dibaca pada perangkat ini.',
      );
    }

    final decoded = jsonDecode(utf8.decode(bytes));
    final Object? rawTasks = decoded is List
        ? decoded
        : decoded is Map
        ? decoded['tasks']
        : null;
    if (rawTasks is! List) {
      throw const FormatException('Struktur file JSON tidak valid.');
    }

    final tasks = rawTasks
        .whereType<Map>()
        .map((item) => TaskModel.fromJson(Map<String, dynamic>.from(item)))
        .where((task) => task.uraianPekerjaan.isNotEmpty)
        .toList();
    if (tasks.isEmpty && rawTasks.isNotEmpty) {
      throw const FormatException('Tidak ada tugas valid di dalam file.');
    }
    return tasks;
  }

  Future<bool> _save({
    required String fileName,
    required String extension,
    required Uint8List bytes,
  }) async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Simpan file todo list jakkob',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: <String>[extension],
      bytes: bytes,
    );
    // Browsers start a download and intentionally return no filesystem path.
    return path != null || kIsWeb;
  }
}
