class MaterialModel {
  const MaterialModel({
    required this.id,
    required this.title,
    required this.text,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String text;
  final DateTime updatedAt;

  MaterialModel copyWith({
    String? id,
    String? title,
    String? text,
    DateTime? updatedAt,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
