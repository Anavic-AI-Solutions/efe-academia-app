class FaqModel {
  final String id;
  final String question;
  final String answer;
  final String? category;
  final String? createdAt;

  FaqModel({
    required this.id,
    required this.question,
    required this.answer,
    this.category,
    this.createdAt,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final attrs = json['attributes'] as Map<String, dynamic>? ??
        (data is Map ? data['attributes'] as Map<String, dynamic>? : null) ??
        json;
    final rawId =
        json['id'] ?? (data is Map ? data['id'] : null) ?? attrs['id'];

    return FaqModel(
      id: rawId?.toString() ?? '',
      question: attrs['question']?.toString() ?? '',
      answer: attrs['answer']?.toString() ?? '',
      category: attrs['category']?.toString(),
      createdAt: attrs['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'created_at': createdAt,
    };
  }
}
