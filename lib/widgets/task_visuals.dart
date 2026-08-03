import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/app_colors.dart';
import '../models/task_model.dart';

FaIconData statusIcon(TaskStatus status) => switch (status) {
  TaskStatus.pending => FontAwesomeIcons.clock,
  TaskStatus.inProgress => FontAwesomeIcons.spinner,
  TaskStatus.review => FontAwesomeIcons.clipboardCheck,
  TaskStatus.completed => FontAwesomeIcons.circleCheck,
};

Color statusColor(TaskStatus status) => switch (status) {
  TaskStatus.pending => AppColors.slate600,
  TaskStatus.inProgress => AppColors.royalBlue,
  TaskStatus.review => AppColors.purple,
  TaskStatus.completed => AppColors.success,
};

Color statusSoftColor(TaskStatus status) => switch (status) {
  TaskStatus.pending => AppColors.slate100,
  TaskStatus.inProgress => const Color(0xFFDBEAFE),
  TaskStatus.review => AppColors.purpleSoft,
  TaskStatus.completed => AppColors.successSoft,
};

Color priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.high => AppColors.danger,
  TaskPriority.medium => AppColors.warning,
  TaskPriority.low => AppColors.slate600,
};

Color prioritySoftColor(TaskPriority priority) => switch (priority) {
  TaskPriority.high => AppColors.dangerSoft,
  TaskPriority.medium => AppColors.warningSoft,
  TaskPriority.low => AppColors.slate100,
};

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final TaskStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: statusSoftColor(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FaIcon(statusIcon(status), size: compact ? 11 : 12, color: color),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class PriorityChip extends StatelessWidget {
  const PriorityChip({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: prioritySoftColor(priority),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FaIcon(FontAwesomeIcons.flag, size: 10, color: color),
          const SizedBox(width: 5),
          Text(
            priority.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
