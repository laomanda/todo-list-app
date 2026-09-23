import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/date_utils.dart';
import '../models/sub_task_model.dart';
import '../models/task_model.dart';
import 'task_file_reader.dart';

class TaskFileService {
  const TaskFileService();

  Future<bool> exportJson(List<TaskModel> tasks) async {
    final payload = <String, dynamic>{
      'application': 'Todo List Jakkob',
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
      dialogTitle: 'Pilih backup Todo List Jakkob',
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

  Future<List<TaskModel>?> importCsv() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Pilih file CSV Todo List Jakkob',
      type: FileType.custom,
      allowedExtensions: const <String>['csv'],
      withData: true,
    );
    if (result == null) return null;

    final bytes = await readPickedFile(result.files.single);
    if (bytes == null) {
      throw const FormatException(
        'File CSV tidak dapat dibaca pada perangkat ini.',
      );
    }

    final rawText = utf8.decode(bytes);
    return parseCsvData(rawText);
  }

  List<TaskModel> parseCsvData(String rawText) {
    var text = rawText;
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(text);
    if (rows.isEmpty) {
      throw const FormatException('File CSV kosong.');
    }

    final firstRow = rows.first
        .map((e) => e.toString().trim().toLowerCase())
        .toList();

    int colDate = -1;
    int colTitle = -1;
    int colNotes = -1;
    int colPic = -1;
    int colSubTasks = -1;
    int colStatus = -1;
    int colPriority = -1;

    for (var i = 0; i < firstRow.length; i++) {
      final header = firstRow[i];
      if (header == 'tanggal' || header == 'date') {
        colDate = i;
      } else if (header.contains('uraian') ||
          header.contains('tugas') ||
          header.contains('pekerjaan') ||
          header == 'title' ||
          header == 'task') {
        colTitle = i;
      } else if (header.contains('keterangan') ||
          header.contains('catatan') ||
          header == 'notes' ||
          header == 'description') {
        colNotes = i;
      } else if (header == 'pic' || header.contains('penanggung')) {
        colPic = i;
      } else if (header.contains('rincian') ||
          header.contains('tindak') ||
          header.contains('subtask') ||
          header.contains('sub-task')) {
        colSubTasks = i;
      } else if (header == 'status') {
        colStatus = i;
      } else if (header.contains('prioritas') || header == 'priority') {
        colPriority = i;
      }
    }

    final hasHeader = colTitle != -1 || colDate != -1;
    final dataRows = hasHeader ? rows.skip(1) : rows;

    if (!hasHeader) {
      colDate = 0;
      colTitle = 1;
      colNotes = 2;
      colPic = 3;
      colSubTasks = 4;
      colStatus = 5;
      colPriority = 6;
    }

    final tasks = <TaskModel>[];
    var rowIndex = 0;

    for (final row in dataRows) {
      rowIndex++;
      if (row.isEmpty) continue;

      String getCell(int idx) {
        if (idx >= 0 && idx < row.length) {
          return row[idx].toString().trim();
        }
        return '';
      }

      final title = colTitle != -1
          ? getCell(colTitle)
          : (row.length > 1 ? row[1].toString().trim() : '');
      if (title.isEmpty) continue;

      final dateStr = colDate != -1
          ? getCell(colDate)
          : (row.isNotEmpty ? row[0].toString().trim() : '');
      final parsedDate =
          DateTime.tryParse(dateStr) ??
          _parseCustomDate(dateStr) ??
          DateTime.now();

      final notes = colNotes != -1
          ? getCell(colNotes)
          : (row.length > 2 ? row[2].toString().trim() : '');
      final pic = colPic != -1
          ? getCell(colPic)
          : (row.length > 3 ? row[3].toString().trim() : '');
      final subTasksRaw = colSubTasks != -1
          ? getCell(colSubTasks)
          : (row.length > 4 ? row[4].toString().trim() : '');
      final statusRaw = colStatus != -1
          ? getCell(colStatus)
          : (row.length > 5 ? row[5].toString().trim() : '');
      final priorityRaw = colPriority != -1
          ? getCell(colPriority)
          : (row.length > 6 ? row[6].toString().trim() : '');

      final subTasks = _parseSubTasks(subTasksRaw);

      tasks.add(
        TaskModel(
          id: '${DateTime.now().microsecondsSinceEpoch}-$rowIndex',
          tanggal: parsedDate,
          uraianPekerjaan: title,
          keterangan: notes,
          pic: pic,
          rincianTindakLanjut: subTasks,
          status: TaskStatusX.fromKey(statusRaw),
          prioritas: TaskPriorityX.fromKey(priorityRaw),
        ),
      );
    }

    if (tasks.isEmpty) {
      throw const FormatException(
        'Tidak ada data tugas yang valid di dalam file CSV.',
      );
    }

    return tasks;
  }

  DateTime? _parseCustomDate(String input) {
    if (input.trim().isEmpty) return null;
    final parts = input.trim().split(RegExp(r'[/.-]'));
    if (parts.length == 3) {
      if (parts[0].length == 4) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      } else if (parts[2].length == 4) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      }
    }
    return null;
  }

  List<SubTaskModel> _parseSubTasks(String raw) {
    if (raw.trim().isEmpty) return const <SubTaskModel>[];
    final items = raw.split('|');
    final result = <SubTaskModel>[];
    for (final item in items) {
      var text = item.trim();
      if (text.isEmpty) continue;
      var isCompleted = false;
      if (text.startsWith('[x]') ||
          text.startsWith('[X]') ||
          text.startsWith('[v]') ||
          text.startsWith('[V]')) {
        isCompleted = true;
        text = text.substring(3).trim();
      } else if (text.startsWith('[ ]')) {
        isCompleted = false;
        text = text.substring(3).trim();
      }
      if (text.isNotEmpty) {
        result.add(SubTaskModel(text: text, isCompleted: isCompleted));
      }
    }
    return result;
  }

  Future<bool> _save({
    required String fileName,
    required String extension,
    required Uint8List bytes,
  }) async {
    final path = await FilePicker.saveFile(
      dialogTitle: 'Simpan file Todo List Jakkob',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: <String>[extension],
      bytes: bytes,
    );
    // Browsers start a download and intentionally return no filesystem path.
    return path != null || kIsWeb;
  }
}
