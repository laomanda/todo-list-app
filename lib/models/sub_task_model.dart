class SubTaskModel {
  const SubTaskModel({required this.text, this.isCompleted = false});

  final String text;
  final bool isCompleted;

  SubTaskModel copyWith({String? text, bool? isCompleted}) {
    return SubTaskModel(
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'text': text,
    'isCompleted': isCompleted,
  };

  factory SubTaskModel.fromJson(Map<String, dynamic> json) {
    return SubTaskModel(
      text: (json['text'] as String? ?? '').trim(),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
