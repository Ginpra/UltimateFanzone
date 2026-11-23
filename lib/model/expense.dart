/// Satu pengeluaran perjalanan tandang (Away Day), dalam Rupiah.
class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.createdAt,
  });

  static const categories = ['Tiket', 'Transport', 'Makan', 'Lainnya'];

  final String id;
  final String title;
  final String category;
  final int amount;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'amount': amount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    amount: (json['amount'] as num).toInt(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
