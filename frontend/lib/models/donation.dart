class Donation {
  final int id;
  final int? activityId;
  final String? activityTitle;
  final String donationDate;
  final String type; // uang, barang, jasa, makanan
  final String donorName;
  final String? description;
  final double valueAmount;
  final int? portions;
  final String? paymentMethod; // tunai, transfer
  final String status; // terverifikasi, dibatalkan
  final String? cancelReason;
  final String? creatorName;

  Donation({
    required this.id,
    this.activityId,
    this.activityTitle,
    required this.donationDate,
    required this.type,
    required this.donorName,
    this.description,
    this.valueAmount = 0.0,
    this.portions,
    this.paymentMethod,
    required this.status,
    this.cancelReason,
    this.creatorName,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] as int,
      activityId: json['activity_id'] as int?,
      activityTitle: json['activity_title'] as String?,
      donationDate: json['donation_date'] as String? ?? '',
      type: json['type'] as String? ?? 'uang',
      donorName: json['donor_name'] as String? ?? 'Hamba Allah',
      description: json['description'] as String?,
      valueAmount: (json['value_amount'] as num?)?.toDouble() ?? 0.0,
      portions: json['portions'] as int?,
      paymentMethod: json['payment_method'] as String?,
      status: json['status'] as String? ?? 'terverifikasi',
      cancelReason: json['cancel_reason'] as String?,
      creatorName: json['creator_name'] as String?,
    );
  }
}
