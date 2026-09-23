import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/app_colors.dart';
import '../core/date_utils.dart';
import '../models/sub_task_model.dart';
import '../models/task_model.dart';

class TaskForm extends StatefulWidget {
  const TaskForm({
    super.key,
    this.initialTask,
    this.initialDate,
    this.existingPics = const <String>[],
    required this.onSubmit,
    required this.onCancel,
  });

  final TaskModel? initialTask;
  final DateTime? initialDate;
  final List<String> existingPics;
  final ValueChanged<TaskModel> onSubmit;
  final VoidCallback onCancel;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _picController;
  late final TextEditingController _dateController;
  late DateTime _date;
  late TaskStatus _status;
  late TaskPriority _priority;
  final List<TextEditingController> _subTaskControllers =
      <TextEditingController>[];
  final List<bool> _subTaskCompleted = <bool>[];

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.uraianPekerjaan ?? '');
    _notesController = TextEditingController(text: task?.keterangan ?? '');
    _picController = TextEditingController(text: task?.pic ?? '');
    _date = dateOnly(task?.tanggal ?? widget.initialDate ?? DateTime.now());
    _dateController = TextEditingController(text: toDateKey(_date));
    _status = task?.status ?? TaskStatus.pending;
    _priority = task?.prioritas ?? TaskPriority.medium;
    for (final item in task?.rincianTindakLanjut ?? const <SubTaskModel>[]) {
      _subTaskControllers.add(TextEditingController(text: item.text));
      _subTaskCompleted.add(item.isCompleted);
    }
    if (_subTaskControllers.isEmpty) _addSubTask(notify: false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _picController.dispose();
    _dateController.dispose();
    for (final controller in _subTaskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSubTask({bool notify = true}) {
    _subTaskControllers.add(TextEditingController());
    _subTaskCompleted.add(false);
    if (notify) setState(() {});
  }

  void _removeSubTask(int index) {
    _subTaskControllers.removeAt(index).dispose();
    _subTaskCompleted.removeAt(index);
    if (_subTaskControllers.isEmpty) _addSubTask(notify: false);
    setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'PILIH TANGGAL TUGAS',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.navy),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _date = dateOnly(picked);
      _dateController.text = toDateKey(_date);
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final subTasks = <SubTaskModel>[];
    for (var index = 0; index < _subTaskControllers.length; index++) {
      final text = _subTaskControllers[index].text.trim();
      if (text.isNotEmpty) {
        subTasks.add(
          SubTaskModel(text: text, isCompleted: _subTaskCompleted[index]),
        );
      }
    }
    final current = widget.initialTask;
    widget.onSubmit(
      TaskModel(
        id: current?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        tanggal: _date,
        uraianPekerjaan: _titleController.text.trim(),
        keterangan: _notesController.text.trim(),
        pic: _picController.text.trim(),
        rincianTindakLanjut: subTasks,
        status: _status,
        prioritas: _priority,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTask != null;
    return Material(
      color: AppColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 14, 17),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FaIcon(
                        isEditing
                            ? FontAwesomeIcons.penToSquare
                            : FontAwesomeIcons.plus,
                        size: 16,
                        color: AppColors.royalBlue,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            isEditing ? 'Edit Tugas' : 'Tambah Tugas Baru',
                            style: const TextStyle(
                              color: AppColors.slate900,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Lengkapi detail pekerjaan dan tindak lanjut.',
                            style: TextStyle(
                              color: AppColors.slate500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: widget.onCancel,
                      icon: const FaIcon(
                        FontAwesomeIcons.xmark,
                        size: 17,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _FieldLabel(
                        icon: FontAwesomeIcons.listCheck,
                        label: 'Uraian Pekerjaan',
                        isRequired: true,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const ValueKey('task-title-field'),
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Finalisasi laporan operasional',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Uraian pekerjaan wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: 17),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 600;
                          final dateField = _FormBlock(
                            label: 'Tanggal',
                            icon: FontAwesomeIcons.calendarDays,
                            child: TextFormField(
                              controller: _dateController,
                              readOnly: true,
                              onTap: _pickDate,
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  tooltip: 'Pilih tanggal',
                                  onPressed: _pickDate,
                                  icon: const FaIcon(
                                    FontAwesomeIcons.calendarDays,
                                    size: 15,
                                    color: AppColors.royalBlue,
                                  ),
                                ),
                              ),
                            ),
                          );
                          final picField = _FormBlock(
                            label: 'PIC',
                            icon: FontAwesomeIcons.user,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                TextFormField(
                                  key: const ValueKey('task-pic-field'),
                                  controller: _picController,
                                  textCapitalization: TextCapitalization.words,
                                   decoration: InputDecoration(
                                     hintText: 'Nama penanggung jawab',
                                     suffixIcon:
                                         ValueListenableBuilder<TextEditingValue>(
                                       valueListenable: _picController,
                                       builder: (context, value, _) {
                                         final hasText = value.text.isNotEmpty;
                                         final hasPics =
                                             widget.existingPics.isNotEmpty;
                                         if (!hasText && !hasPics) {
                                           return const SizedBox.shrink();
                                         }
                                         return Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: <Widget>[
                                             if (hasText)
                                               IconButton(
                                                 tooltip: 'Hapus nama',
                                                 icon: const FaIcon(
                                                   FontAwesomeIcons.xmark,
                                                   size: 13,
                                                   color: AppColors.slate400,
                                                 ),
                                                 onPressed:
                                                     _picController.clear,
                                               ),
                                             if (hasPics)
                                               PopupMenuButton<String>(
                                                 tooltip: 'Pilih dari daftar PIC',
                                                 icon: const FaIcon(
                                                   FontAwesomeIcons.chevronDown,
                                                   size: 12,
                                                   color: AppColors.royalBlue,
                                                 ),
                                                 onSelected: (pic) {
                                                   _picController.text = pic;
                                                   _picController.selection =
                                                       TextSelection.fromPosition(
                                                     TextPosition(
                                                       offset: pic.length,
                                                     ),
                                                   );
                                                 },
                                                 itemBuilder: (context) => widget
                                                     .existingPics
                                                     .map(
                                                       (pic) =>
                                                           PopupMenuItem<String>(
                                                         value: pic,
                                                         child: Row(
                                                           children: <Widget>[
                                                             Container(
                                                               width: 26,
                                                               height: 26,
                                                               alignment:
                                                                   Alignment
                                                                       .center,
                                                               decoration:
                                                                   const BoxDecoration(
                                                                 color: Color(
                                                                   0xFFDBEAFE,
                                                                 ),
                                                                 shape: BoxShape
                                                                     .circle,
                                                               ),
                                                               child:
                                                                   const FaIcon(
                                                                 FontAwesomeIcons
                                                                     .user,
                                                                 size: 10,
                                                                 color: AppColors
                                                                     .royalBlue,
                                                               ),
                                                             ),
                                                             const SizedBox(
                                                               width: 9,
                                                             ),
                                                             Text(
                                                               pic,
                                                               style: TextStyle(
                                                                 fontWeight:
                                                                     value.text
                                                                                 .trim() ==
                                                                             pic
                                                                         ? FontWeight
                                                                               .w800
                                                                         : FontWeight
                                                                               .w600,
                                                                 color:
                                                                     value.text
                                                                                 .trim() ==
                                                                             pic
                                                                         ? AppColors
                                                                               .royalBlue
                                                                         : AppColors
                                                                               .slate700,
                                                               ),
                                                             ),
                                                           ],
                                                         ),
                                                       ),
                                                     )
                                                     .toList(),
                                               ),
                                           ],
                                         );
                                       },
                                     ),
                                   ),
                                 ),
                                 if (widget.existingPics.isNotEmpty) ...<Widget>[
                                   const SizedBox(height: 7),
                                   ValueListenableBuilder<TextEditingValue>(
                                     valueListenable: _picController,
                                     builder: (context, value, _) {
                                       return Wrap(
                                         spacing: 6,
                                         runSpacing: 6,
                                         crossAxisAlignment:
                                             WrapCrossAlignment.center,
                                         children: <Widget>[
                                           const Text(
                                             'Pilih cepat:',
                                             style: TextStyle(
                                               color: AppColors.slate500,
                                               fontSize: 11,
                                               fontWeight: FontWeight.w600,
                                             ),
                                           ),
                                           ...widget.existingPics
                                               .take(6)
                                               .map((pic) {
                                             final isSelected =
                                                 value.text.trim() == pic;
                                             return InkWell(
                                               onTap: () {
                                                 _picController.text = pic;
                                                 _picController.selection =
                                                     TextSelection.fromPosition(
                                                   TextPosition(
                                                     offset: pic.length,
                                                   ),
                                                 );
                                               },
                                               borderRadius:
                                                   BorderRadius.circular(6),
                                               child: Container(
                                                 padding:
                                                     const EdgeInsets.symmetric(
                                                   horizontal: 8,
                                                   vertical: 4,
                                                 ),
                                                 decoration: BoxDecoration(
                                                   color: isSelected
                                                       ? const Color(0xFFDBEAFE)
                                                       : AppColors.slate100,
                                                   borderRadius:
                                                       BorderRadius.circular(6),
                                                   border: Border.all(
                                                     color: isSelected
                                                         ? AppColors.royalBlue
                                                         : AppColors.slate200,
                                                   ),
                                                 ),
                                                 child: Row(
                                                   mainAxisSize:
                                                       MainAxisSize.min,
                                                   children: <Widget>[
                                                     FaIcon(
                                                       FontAwesomeIcons.user,
                                                       size: 9,
                                                       color: isSelected
                                                           ? AppColors.royalBlue
                                                           : AppColors.slate500,
                                                     ),
                                                     const SizedBox(width: 5),
                                                     Text(
                                                       pic,
                                                       style: TextStyle(
                                                         fontSize: 11,
                                                         fontWeight: isSelected
                                                             ? FontWeight.w800
                                                             : FontWeight.w600,
                                                         color: isSelected
                                                             ? AppColors
                                                                   .royalBlue
                                                             : AppColors
                                                                   .slate700,
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                               ),
                                             );
                                           }),
                                         ],
                                       );
                                     },
                                   ),
                                 ],
                              ],
                            ),
                          );
                          if (compact) {
                            return Column(
                              children: <Widget>[
                                dateField,
                                const SizedBox(height: 17),
                                picField,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(child: dateField),
                              const SizedBox(width: 14),
                              Expanded(child: picField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 17),
                      _FieldLabel(
                        icon: FontAwesomeIcons.noteSticky,
                        label: 'Keterangan',
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Tambahkan konteks, kategori, atau catatan',
                        ),
                      ),
                      const SizedBox(height: 17),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 600;
                          final statusField = _FormBlock(
                            label: 'Status',
                            icon: FontAwesomeIcons.barsProgress,
                            child: _EnumDropdown<TaskStatus>(
                              value: _status,
                              values: TaskStatus.values,
                              labelBuilder: (value) => value.label,
                              onChanged: (value) =>
                                  setState(() => _status = value),
                            ),
                          );
                          final priorityField = _FormBlock(
                            label: 'Prioritas',
                            icon: FontAwesomeIcons.flag,
                            child: _EnumDropdown<TaskPriority>(
                              value: _priority,
                              values: TaskPriority.values,
                              labelBuilder: (value) => value.label,
                              onChanged: (value) =>
                                  setState(() => _priority = value),
                            ),
                          );
                          if (compact) {
                            return Column(
                              children: <Widget>[
                                statusField,
                                const SizedBox(height: 17),
                                priorityField,
                              ],
                            );
                          }
                          return Row(
                            children: <Widget>[
                              Expanded(child: statusField),
                              const SizedBox(width: 14),
                              Expanded(child: priorityField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 21),
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: _FieldLabel(
                              icon: FontAwesomeIcons.barsProgress,
                              label: 'Rincian Tindak Lanjut',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addSubTask,
                            icon: const FaIcon(FontAwesomeIcons.plus, size: 12),
                            label: const Text('Tambah rincian'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List<Widget>.generate(_subTaskControllers.length, (
                        index,
                      ) {
                        final completed = _subTaskCompleted[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: <Widget>[
                              Tooltip(
                                message: completed
                                    ? 'Tandai belum selesai'
                                    : 'Tandai selesai',
                                child: InkWell(
                                  onTap: () => setState(
                                    () => _subTaskCompleted[index] = !completed,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 43,
                                    height: 43,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: completed
                                          ? AppColors.successSoft
                                          : AppColors.slate100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: FaIcon(
                                      completed
                                          ? FontAwesomeIcons.solidSquareCheck
                                          : FontAwesomeIcons.square,
                                      size: 16,
                                      color: completed
                                          ? AppColors.success
                                          : AppColors.slate500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: TextFormField(
                                  controller: _subTaskControllers[index],
                                  decoration: InputDecoration(
                                    hintText:
                                        'Rincian tindak lanjut ${index + 1}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                tooltip: 'Hapus rincian',
                                onPressed: () => _removeSubTask(index),
                                icon: const FaIcon(
                                  FontAwesomeIcons.trashCan,
                                  size: 14,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: widget.onCancel,
                      icon: const FaIcon(FontAwesomeIcons.xmark, size: 13),
                      label: const Text('Batal'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      key: const ValueKey('task-save-button'),
                      onPressed: _submit,
                      icon: const FaIcon(FontAwesomeIcons.floppyDisk, size: 14),
                      label: Text(
                        isEditing ? 'Simpan Perubahan' : 'Tambah Tugas',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormBlock extends StatelessWidget {
  const _FormBlock({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final FaIconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _FieldLabel(icon: icon, label: label),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.icon,
    required this.label,
    this.isRequired = false,
  });

  final FaIconData icon;
  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        FaIcon(icon, size: 12, color: AppColors.slate500),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.slate700,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _EnumDropdown<T> extends StatelessWidget {
  const _EnumDropdown({
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

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
      items: values
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(labelBuilder(item)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
