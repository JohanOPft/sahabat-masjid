class PublishedReport {
  final int id;
  final String title;
  final String reportType; // 'periode', 'kegiatan', 'kas'
  final String? periodStart;
  final String? periodEnd;
  final int? activityId;
  final String? activityTitle;
  final Map<String, dynamic> summaryJson;
  final bool isPublished;
  final String? approverName;
  final String? publishedAt;

  PublishedReport({
    required this.id,
    required this.title,
    required this.reportType,
    this.periodStart,
    this.periodEnd,
    this.activityId,
    this.activityTitle,
    required this.summaryJson,
    required this.isPublished,
    this.approverName,
    this.publishedAt,
  });

  factory PublishedReport.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> summary = {};
    if (json['summary_json'] is Map) {
      summary = Map<String, dynamic>.from(json['summary_json'] as Map);
    }

    return PublishedReport(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Laporan',
      reportType: json['report_type'] as String? ?? 'periode',
      periodStart: json['period_start'] as String?,
      periodEnd: json['period_end'] as String?,
      activityId: json['activity_id'] as int?,
      activityTitle: json['activity_title'] as String?,
      summaryJson: summary,
      isPublished: json['is_published'] == 1 || json['is_published'] == true,
      approverName: json['approver_name'] as String?,
      publishedAt: json['published_at'] as String?,
    );
  }

  double get totalMoney => (summaryJson['total_money_donation'] as num?)?.toDouble() ?? 0.0;
  double get totalGoodsServices => (summaryJson['total_goods_services_value'] as num?)?.toDouble() ?? 0.0;
  int get totalFoodPortions => (summaryJson['total_food_portions'] as num?)?.toInt() ?? 0;
  double get totalExpense => (summaryJson['total_expense'] as num?)?.toDouble() ?? 0.0;
  double get balance => (summaryJson['balance'] as num?)?.toDouble() ?? 0.0;
}
