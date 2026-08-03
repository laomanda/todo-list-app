import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/app_colors.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class FilterToolbar extends StatelessWidget {
  const FilterToolbar({
    super.key,
    required this.searchController,
    required this.provider,
    required this.onClear,
  });

  final TextEditingController searchController;
  final TaskProvider provider;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        provider.searchQuery.isNotEmpty ||
        provider.statusFilter != null ||
        provider.priorityFilter != null ||
        provider.picFilter != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 760;
            final fieldWidth = isCompact
                ? constraints.maxWidth
                : (constraints.maxWidth - 36) / 4;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const FaIcon(
                      FontAwesomeIcons.filter,
                      size: 14,
                      color: AppColors.slate500,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Pencarian & Filter',
                        style: TextStyle(
                          color: AppColors.slate700,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (hasFilters)
                      TextButton.icon(
                        onPressed: onClear,
                        icon: const FaIcon(FontAwesomeIcons.xmark, size: 13),
                        label: const Text('Bersihkan'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    SizedBox(
                      width: fieldWidth,
                      child: TextField(
                        key: const ValueKey('task-search-field'),
                        controller: searchController,
                        onChanged: provider.setSearchQuery,
                        decoration: const InputDecoration(
                          hintText: 'Cari pekerjaan atau keterangan',
                          prefixIcon: Padding(
                            padding: EdgeInsets.all(14),
                            child: FaIcon(
                              FontAwesomeIcons.magnifyingGlass,
                              size: 15,
                              color: AppColors.slate500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _FilterDropdown<TaskStatus>(
                        key: ValueKey(provider.statusFilter),
                        value: provider.statusFilter,
                        hint: 'Semua status',
                        icon: FontAwesomeIcons.barsProgress,
                        items: TaskStatus.values,
                        labelBuilder: (value) => value.label,
                        onChanged: provider.setStatusFilter,
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _FilterDropdown<String>(
                        key: ValueKey(provider.picFilter),
                        value: provider.picFilter,
                        hint: 'Semua PIC',
                        icon: FontAwesomeIcons.user,
                        items: provider.pics,
                        labelBuilder: (value) => value,
                        onChanged: provider.setPicFilter,
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: _FilterDropdown<TaskPriority>(
                        key: ValueKey(provider.priorityFilter),
                        value: provider.priorityFilter,
                        hint: 'Semua prioritas',
                        icon: FontAwesomeIcons.flag,
                        items: TaskPriority.values,
                        labelBuilder: (value) => value.label,
                        onChanged: provider.setPriorityFilter,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final FaIconData icon;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: const FaIcon(
        FontAwesomeIcons.chevronDown,
        size: 12,
        color: AppColors.slate500,
      ),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(14),
          child: FaIcon(icon, size: 14, color: AppColors.slate500),
        ),
      ),
      hint: Text(hint, overflow: TextOverflow.ellipsis),
      items: <DropdownMenuItem<T>>[
        DropdownMenuItem<T>(
          value: null,
          child: Text(hint, overflow: TextOverflow.ellipsis),
        ),
        ...items.map(
          (item) => DropdownMenuItem<T>(
            value: item,
            child: Text(labelBuilder(item), overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
