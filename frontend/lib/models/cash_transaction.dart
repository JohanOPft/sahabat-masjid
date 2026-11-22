class CashTransaction {
  final int id;
  final int? activityId;
  final String? activityTitle;
  final String transactionDate;
  final String direction; // 'masuk' atau 'keluar'
  final double amount;
  final String note;
  final String status; // 'sah' atau 'dibatalkan'
  final String? cancelReason;
  final String? creatorName;

  CashTransaction({
    required this.id,
    this.activityId,
    this.activityTitle,
    required this.transactionDate,
    required this.direction,
    required this.amount,
    required this.note,
    required this.status,
    this.cancelReason,
    this.creatorName,
  });

  factory CashTransaction.fromJson(Map<String, dynamic> json) {
    return CashTransaction(
      id: json['id'] as int,
      activityId: json['activity_id'] as int?,
      activityTitle: json['activity_title'] as String?,
      transactionDate: json['transaction_date'] as String? ?? '',
      direction: json['direction'] as String? ?? 'masuk',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String? ?? '',
      status: json['status'] as String? ?? 'sah',
      cancelReason: json['cancel_reason'] as String?,
      creatorName: json['creator_name'] as String?,
    );
  }

  bool get isMasuk => direction == 'masuk';
}
