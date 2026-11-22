class Activity {
  final int id;
  final String title;
  final String type; // Jumat Berkah, Pengajian, Kegiatan Bulan Puasa, Lainnya
  final String activityDate;
  final String activityTime;
  final String location;
  final String? pjName;
  final String? notes;
  final String status; // terjadwal, selesai, dibatalkan
  final String? cancelReason;
  final String? creatorName;
  final double totalDonationUang;
  final double totalExpense;
  final int totalFoodPortions;
  final double totalCashSubsidy;
  final double netBalance;
  final bool isDeficit;
  final double deficitAmount;
  final bool needsPj;

  Activity({
    required this.id,
    required this.title,
    required this.type,
    required this.activityDate,
    required this.activityTime,
    required this.location,
    this.pjName,
    this.notes,
    required this.status,
    this.cancelReason,
    this.creatorName,
    this.totalDonationUang = 0.0,
    this.totalExpense = 0.0,
    this.totalFoodPortions = 0,
    this.totalCashSubsidy = 0.0,
    this.netBalance = 0.0,
    this.isDeficit = false,
    this.deficitAmount = 0.0,
    this.needsPj = false,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'Lainnya',
      activityDate: json['activity_date'] as String? ?? '',
      activityTime: json['activity_time'] as String? ?? '',
      location: json['location'] as String? ?? 'Masjid Al-Ikhlas',
      pjName: json['pj_name'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'terjadwal',
      cancelReason: json['cancel_reason'] as String?,
      creatorName: json['creator_name'] as String?,
      totalDonationUang: (json['total_donation_uang'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0.0,
      totalFoodPortions: (json['total_food_portions'] as num?)?.toInt() ?? 0,
      totalCashSubsidy: (json['total_cash_subsidy'] as num?)?.toDouble() ?? 0.0,
      netBalance: (json['net_balance'] as num?)?.toDouble() ?? 0.0,
      isDeficit: json['is_deficit'] as bool? ?? false,
      deficitAmount: (json['deficit_amount'] as num?)?.toDouble() ?? 0.0,
      needsPj: json['needs_pj'] as bool? ?? (json['pj_name'] == null || json['pj_name'].toString().trim().isEmpty),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'activity_date': activityDate,
      'activity_time': activityTime,
      'location': location,
      'pj_name': pjName,
      'notes': notes,
      'status': status,
    };
  }
}
