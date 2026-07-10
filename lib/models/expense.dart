class Expense {
  final String id;
  String title;
  double amount;
  String category;
  String? note;
  DateTime date;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    this.category = 'other',
    this.note,
    required this.date,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String? ?? 'other',
        note: json['note'] as String?,
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
