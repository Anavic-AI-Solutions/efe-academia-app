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
    return FaqModel(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      category: json['category'] as String?,
      createdAt: json['created_at'] as String?,
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