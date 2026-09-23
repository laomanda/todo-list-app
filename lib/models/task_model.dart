import 'sub_task_model.dart';

enum TaskStatus { pending, inProgress, review, completed }

extension TaskStatusX on TaskStatus {
  String get key => switch (this) {
    TaskStatus.pending => 'pending',
    TaskStatus.inProgress => 'in_progress',
    TaskStatus.review => 'review',
    TaskStatus.completed => 'completed',
  };

  String get label => switch (this) {
    TaskStatus.pending => 'Pending',
    TaskStatus.inProgress => 'Dalam Proses',
    TaskStatus.review => 'Review',
    TaskStatus.completed => 'Selesai',
  };

  static TaskStatus fromKey(String? value) {
    final clean = value?.trim().toLowerCase();
    return TaskStatus.values.firstWhere(
      (status) =>
          status.key.toLowerCase() == clean ||
          status.label.toLowerCase() == clean,
      orElse: () => TaskStatus.pending,
    );
  }
}

enum TaskPriority { high, medium, low }

extension TaskPriorityX on TaskPriority {
  String get key => switch (this) {
    TaskPriority.high => 'high',
    TaskPriority.medium => 'medium',
    TaskPriority.low => 'low',
  };

  String get label => switch (this) {
    TaskPriority.high => 'Tinggi',
    TaskPriority.medium => 'Sedang',
    TaskPriority.low => 'Rendah',
  };

  static TaskPriority fromKey(String? value) {
    final clean = value?.trim().toLowerCase();
    return TaskPriority.values.firstWhere(
      (priority) =>
          priority.key.toLowerCase() == clean ||
          priority.label.toLowerCase() == clean,
      orElse: () => TaskPriority.medium,
    );
  }
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.tanggal,
    required this.uraianPekerjaan,
    required this.keterangan,
    required this.pic,
    required this.rincianTindakLanjut,
    required this.status,
    required this.prioritas,
  });

  final String id;
  final DateTime tanggal;
  final String uraianPekerjaan;
  final String keterangan;
  final String pic;
  final List<SubTaskModel> rincianTindakLanjut;
  final TaskStatus status;
  final TaskPriority prioritas;

  int get completedSubTaskCount =>
      rincianTindakLanjut.where((item) => item.isCompleted).length;

  double get progress {
    if (rincianTindakLanjut.isEmpty) return 0;
    return completedSubTaskCount / rincianTindakLanjut.length;
  }

  int get progressPercent => (progress * 100).round();

  TaskModel copyWith({
    String? id,
    DateTime? tanggal,
    String? uraianPekerjaan,
    String? keterangan,
    String? pic,
    List<SubTaskModel>? rincianTindakLanjut,
    TaskStatus? status,
    TaskPriority? prioritas,
  }) {
    return TaskModel(
      id: id ?? this.id,
      tanggal: tanggal ?? this.tanggal,
      uraianPekerjaan: uraianPekerjaan ?? this.uraianPekerjaan,
      keterangan: keterangan ?? this.keterangan,
      pic: pic ?? this.pic,
      rincianTindakLanjut:
          rincianTindakLanjut ??
          List<SubTaskModel>.from(this.rincianTindakLanjut),
      status: status ?? this.status,
      prioritas: prioritas ?? this.prioritas,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'tanggal': _dateKey(tanggal),
    'uraianPekerjaan': uraianPekerjaan,
    'keterangan': keterangan,
    'pic': pic,
    'rincianTindakLanjut': rincianTindakLanjut
        .map((item) => item.toJson())
        .toList(),
    'status': status.key,
    'prioritas': prioritas.key,
  };

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawSubTasks = json['rincianTindakLanjut'];
    final parsedDate = DateTime.tryParse(json['tanggal'] as String? ?? '');
    return TaskModel(
      id: (json['id'] as String? ?? '').trim().isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : (json['id'] as String).trim(),
      tanggal: parsedDate ?? DateTime.now(),
      uraianPekerjaan: (json['uraianPekerjaan'] as String? ?? '').trim(),
      keterangan: (json['keterangan'] as String? ?? '').trim(),
      pic: (json['pic'] as String? ?? '').trim(),
      rincianTindakLanjut: rawSubTasks is List
          ? rawSubTasks
                .whereType<Map>()
                .map(
                  (item) =>
                      SubTaskModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .where((item) => item.text.isNotEmpty)
                .toList()
          : <SubTaskModel>[],
      status: TaskStatusX.fromKey(json['status'] as String?),
      prioritas: TaskPriorityX.fromKey(json['prioritas'] as String?),
    );
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
