class DonationConfirmation {
  final int id;
  final String referenceCode;
  final int? activityId;
  final String? activityTitle;
  final String donorName;
  final String? contact;
  final double amount;
  final String donationDate;
  final String? proofPhoto;
  final String status; // 'menunggu', 'disetujui', 'ditolak'
  final String? rejectReason;
  final String? reviewerName;
  final String? reviewedAt;

  DonationConfirmation({
    required this.id,
    required this.referenceCode,
    this.activityId,
    this.activityTitle,
    required this.donorName,
    this.contact,
    required this.amount,
    required this.donationDate,
    this.proofPhoto,
    required this.status,
    this.rejectReason,
    this.reviewerName,
    this.reviewedAt,
  });

  factory DonationConfirmation.fromJson(Map<String, dynamic> json) {
    return DonationConfirmation(
      id: json['id'] as int,
      referenceCode: json['reference_code'] as String? ?? '',
      activityId: json['activity_id'] as int?,
      activityTitle: json['activity_title'] as String?,
      donorName: json['donor_name'] as String? ?? 'Hamba Allah',
      contact: json['contact'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      donationDate: json['donation_date'] as String? ?? '',
      proofPhoto: json['proof_photo'] as String?,
      status: json['status'] as String? ?? 'menunggu',
      rejectReason: json['reject_reason'] as String?,
      reviewerName: json['reviewer_name'] as String?,
      reviewedAt: json['reviewed_at'] as String?,
    );
  }

  bool get isPending => status == 'menunggu';
  bool get isApproved => status == 'disetujui';
  bool get isRejected => status == 'ditolak';
}
