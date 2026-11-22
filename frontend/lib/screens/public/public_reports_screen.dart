import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/report.dart';
import '../../config/api_config.dart';
import '../../widgets/app_drawer.dart';

class PublicReportsScreen extends StatefulWidget {
  const PublicReportsScreen({Key? key}) : super(key: key);

  @override
  State<PublicReportsScreen> createState() => _PublicReportsScreenState();
}

class _PublicReportsScreenState extends State<PublicReportsScreen> {
  bool _isLoading = true;
  List<PublishedReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiService.getPublishedReports();
      setState(() {
        _reports = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan & Kegiatan Publik'),
      ),
      drawer: const AppDrawer(currentRoute: '/public-reports'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReports,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Seluruh laporan di halaman ini telah diverifikasi dan disetujui oleh Takmir Masjid Al-Ikhlas untuk transparansi umat.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),

                  if (_reports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text('Belum ada laporan yang dipublikasikan oleh takmir.', style: TextStyle(fontSize: 16)),
                      ),
                    )
                  else
                    ..._reports.map((rep) => Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        rep.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(rep.reportType.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.white)),
                                      backgroundColor: const Color(0xFF0F766E),
                                    ),
                                  ],
                                ),
                                if (rep.periodStart != null || rep.periodEnd != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Periode: ${rep.periodStart ?? "-"} s.d. ${rep.periodEnd ?? "-"}',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                  ),
                                ],
                                const Divider(height: 24),

                                // Grid Ringkasan Angka (FR-32, FR-37)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricTile(
                                        'Donasi Uang',
                                        ApiConfig.formatRupiah(rep.totalMoney),
                                        const Color(0xFF059669),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildMetricTile(
                                        'Pengeluaran',
                                        ApiConfig.formatRupiah(rep.totalExpense),
                                        Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricTile(
                                        'Makanan Siap Santap',
                                        '${rep.totalFoodPortions} Porsi',
                                        const Color(0xFFD97706),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildMetricTile(
                                        'Saldo / Selisih',
                                        ApiConfig.formatRupiah(rep.balance),
                                        const Color(0xFF0F766E),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Disetujui oleh Takmir: ${rep.approverName ?? "Pak Abdul"}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.share, size: 18, color: Color(0xFF059669)),
                                      label: const Text('Bagikan ke WA', style: TextStyle(color: Color(0xFF059669))),
                                      onPressed: () async {
                                        final txt = await apiService.getReportWhatsAppText(rep.id);
                                        _showShareDialog(context, txt);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Teks Siap Bagikan ke WhatsApp'),
        content: SelectableText(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }
}
