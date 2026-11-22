import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../services/api_service.dart';
import '../../models/report.dart';
import '../../models/activity.dart';
import '../../config/api_config.dart';
import '../../widgets/app_drawer.dart';

class ReportsManageScreen extends StatefulWidget {
  const ReportsManageScreen({Key? key}) : super(key: key);

  @override
  State<ReportsManageScreen> createState() => _ReportsManageScreenState();
}

class _ReportsManageScreenState extends State<ReportsManageScreen> {
  bool _isLoading = true;
  List<PublishedReport> _reports = [];
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reps = await apiService.getAllReportsAdmin();
      final acts = await apiService.getActivities();
      setState(() {
        _reports = reps;
        _activities = acts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showCreatePublishDialog() {
    final titleCtrl = TextEditingController(text: 'Laporan Keuangan Pekan Ini');
    String reportType = 'periode';
    final startCtrl = TextEditingController(text: DateTime.now().subtract(const Duration(days: 7)).toIso8601String().substring(0, 10));
    final endCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    int? actId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Susun & Publikasikan Laporan (FR-32, FR-34)'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Laporan *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: reportType,
                    decoration: const InputDecoration(labelText: 'Jenis Laporan *', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'periode', child: Text('Laporan Periode Tanggal')),
                      DropdownMenuItem(value: 'kegiatan', child: Text('Laporan Spesifik Per Kegiatan')),
                    ],
                    onChanged: (v) => setDlgState(() => reportType = v!),
                  ),
                  const SizedBox(height: 12),
                  if (reportType == 'kegiatan')
                    DropdownButtonFormField<int?>(
                      value: actId,
                      decoration: const InputDecoration(labelText: 'Pilih Kegiatan *', border: OutlineInputBorder()),
                      items: _activities.map((a) => DropdownMenuItem(value: a.id, child: Text(a.title))).toList(),
                      onChanged: (v) => setDlgState(() => actId = v),
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Mulai', border: OutlineInputBorder()))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'Sampai', border: OutlineInputBorder()))),
                      ],
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
              onPressed: () async {
                try {
                  // Ambil kalkulasi ringkasan angka dari backend
                  final summary = await apiService.getReportSummary(
                    startDate: reportType == 'periode' ? startCtrl.text : null,
                    endDate: reportType == 'periode' ? endCtrl.text : null,
                    activityId: reportType == 'kegiatan' ? actId : null,
                  );
                  await apiService.publishReport({
                    'title': titleCtrl.text.trim(),
                    'report_type': reportType,
                    'period_start': startCtrl.text,
                    'period_end': endCtrl.text,
                    'activity_id': actId,
                    'summary_json': summary,
                  });
                  Navigator.pop(ctx);
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              },
              child: const Text('Publikasikan ke Publik', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Publikasi'),
        actions: [
          if (auth.isTakmir)
            IconButton(icon: const Icon(Icons.add), onPressed: _showCreatePublishDialog),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/admin/reports'),
      floatingActionButton: auth.isTakmir
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF0F766E),
              icon: const Icon(Icons.publish, color: Colors.white),
              label: const Text('Publikasikan Laporan Baru', style: TextStyle(color: Colors.white)),
              onPressed: _showCreatePublishDialog,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _reports.isEmpty
                  ? const Center(child: Text('Belum ada riwayat laporan.', style: TextStyle(fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reports.length,
                      itemBuilder: (context, idx) {
                        final rep = _reports[idx];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(rep.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                    Chip(
                                      label: Text(rep.isPublished ? 'TERPUBLIKASI' : 'DITARIK', style: const TextStyle(color: Colors.white, fontSize: 11)),
                                      backgroundColor: rep.isPublished ? const Color(0xFF059669) : Colors.grey,
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Text('💰 Donasi: ${ApiConfig.formatRupiah(rep.totalMoney)} | 💸 Pengeluaran: ${ApiConfig.formatRupiah(rep.totalExpense)}'),
                                Text('🍱 Makanan: ${rep.totalFoodPortions} Porsi | 📈 Selisih: ${ApiConfig.formatRupiah(rep.balance)}'),
                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.share, size: 16, color: Color(0xFF059669)),
                                      label: const Text('Bagikan ke WA (FR-41)', style: TextStyle(color: Color(0xFF059669))),
                                      onPressed: () async {
                                        final txt = await apiService.getReportWhatsAppText(rep.id);
                                        showDialog(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text('Teks Siap Bagikan WhatsApp:'),
                                            content: SelectableText(txt),
                                            actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup'))],
                                          ),
                                        );
                                      },
                                    ),
                                    if (auth.isTakmir && rep.isPublished)
                                      TextButton.icon(
                                        icon: const Icon(Icons.visibility_off, size: 16, color: Colors.orange),
                                        label: const Text('Tarik Publikasi', style: TextStyle(color: Colors.orange)),
                                        onPressed: () async {
                                          await apiService.unpublishReport(rep.id);
                                          _loadData();
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
