import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/task_model.dart';

class TaskProgress extends StatelessWidget {
  const TaskProgress({super.key, required this.task, this.compact = false});

  final TaskModel task;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final total = task.rincianTindakLanjut.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              total == 0
                  ? 'Belum ada rincian'
                  : '${task.completedSubTaskCount}/$total selesai',
              style: TextStyle(
                color: AppColors.slate500,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${task.progressPercent}%',
              style: TextStyle(
                color: AppColors.slate700,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: task.progress,
            minHeight: compact ? 5 : 7,
            color: task.progress >= 1 ? AppColors.success : AppColors.royalBlue,
            backgroundColor: AppColors.slate200,
          ),
        ),
      ],
    );
  }
}
