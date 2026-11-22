class Expense {
  final int id;
  final int activityId;
  final String? activityTitle;
  final String expenseDate;
  final String category;
  final String description;
  final double amount;
  final String? proofPhoto;
  final String status; // sah, dibatalkan
  final String? cancelReason;
  final String? creatorName;

  Expense({
    required this.id,
    required this.activityId,
    this.activityTitle,
    required this.expenseDate,
    required this.category,
    required this.description,
    required this.amount,
    this.proofPhoto,
    required this.status,
    this.cancelReason,
    this.creatorName,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int,
      activityId: json['activity_id'] as int? ?? 0,
      activityTitle: json['activity_title'] as String?,
      expenseDate: json['expense_date'] as String? ?? '',
      category: json['category'] as String? ?? 'Lainnya',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      proofPhoto: json['proof_photo'] as String?,
      status: json['status'] as String? ?? 'sah',
      cancelReason: json['cancel_reason'] as String?,
      creatorName: json['creator_name'] as String?,
    );
  }
}
