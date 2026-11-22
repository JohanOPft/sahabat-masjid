import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../services/api_service.dart';
import '../../models/cash_transaction.dart';
import '../../config/api_config.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/stat_card.dart';

class CashManageScreen extends StatefulWidget {
  const CashManageScreen({Key? key}) : super(key: key);

  @override
  State<CashManageScreen> createState() => _CashManageScreenState();
}

class _CashManageScreenState extends State<CashManageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  List<CashTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final s = await apiService.getCashSummary();
      final tx = await apiService.getCashTransactions();
      setState(() {
        _summary = s;
        _transactions = tx;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddKasDialog({String direction = 'masuk', int? defaultActivityId, double? defaultAmount}) {
    final amountCtrl = TextEditingController(text: defaultAmount != null ? defaultAmount.toStringAsFixed(0) : '');
    final noteCtrl = TextEditingController(
      text: direction == 'keluar' && defaultActivityId != null ? 'Penambalan kekurangan dana kegiatan' : '',
    );
    int? actId = defaultActivityId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(direction == 'masuk' ? 'Tambah Kas Masuk (FR-23)' : 'Tambah Kas Keluar / Tambal Kegiatan (FR-23, FR-26)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal Kas (Rp) *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Keterangan Sumber / Keperluan *', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
            onPressed: () async {
              if (amountCtrl.text.isEmpty || noteCtrl.text.isEmpty) return;
              try {
                await apiService.recordCashTransaction({
                  'direction': direction,
                  'amount': double.parse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
                  'note': noteCtrl.text.trim(),
                  'activity_id': actId,
                });
                Navigator.pop(ctx);
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            child: const Text('Simpan Transaksi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);
    final deficitList = (_summary['deficit_activities'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kas & Selisih Kegiatan'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.warning), text: 'Status Selisih & Defisit'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat Transaksi Kas'),
          ],
        ),
        actions: [
          if (auth.isTakmir)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Catat Kas Masuk',
              onPressed: () => _showAddKasDialog(direction: 'masuk'),
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/admin/cash'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: STATUS SELISIH & KEGIATAN DEFISIT (FR-22, FR-25)
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      StatCard(
                        title: 'Saldo Kas Masjid Al-Ikhlas Saat Ini',
                        value: ApiConfig.formatRupiah(_summary['current_balance'] ?? 0),
                        icon: Icons.account_balance,
                        color: const Color(0xFF059669),
                        subtitle: 'Kas Masuk: ${ApiConfig.formatRupiah(_summary["total_cash_in"] ?? 0)} | Kas Keluar: ${ApiConfig.formatRupiah(_summary["total_cash_out"] ?? 0)}',
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Kegiatan yang Mengalami Kekurangan Dana (Defisit)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Selisih dihitung dari total biaya kegiatan dikurangi donasi uang & subsidi kas. Takmir dapat menutup kekurangan dari kas masjid (FR-22, FR-26).',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      if (deficitList.isEmpty)
                        Card(
                          color: Colors.green.shade50,
                          child: const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Center(
                              child: Text(
                                'Alhamdulillah, tidak ada kegiatan yang defisit dana.',
                                style: TextStyle(fontSize: 16, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )
                      else
                        ...deficitList.map((d) => Card(
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
                                          child: Text(d['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        ),
                                        Chip(
                                          label: const Text('DEFISIT', style: TextStyle(color: Colors.white, fontSize: 11)),
                                          backgroundColor: Colors.red.shade700,
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    Text('Donasi Uang: ${ApiConfig.formatRupiah(d["total_donation"] ?? 0)} | Pengeluaran: ${ApiConfig.formatRupiah(d["total_expense"] ?? 0)}'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Kekurangan Dana: ${ApiConfig.formatRupiah(d["deficit_amount"] ?? 0)}',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                    ),
                                    const SizedBox(height: 10),

                                    if (auth.isTakmir)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                                          icon: const Icon(Icons.healing, color: Colors.white, size: 18),
                                          label: const Text('Tambal dari Kas Masjid', style: TextStyle(color: Colors.white)),
                                          onPressed: () => _showAddKasDialog(
                                            direction: 'keluar',
                                            defaultActivityId: d['id'],
                                            defaultAmount: (d['deficit_amount'] as num?)?.toDouble(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )),
                    ],
                  ),

                  // TAB 2: RIWAYAT TRANSAKSI KAS (FR-23, FR-24)
                  _transactions.isEmpty
                      ? const Center(child: Text('Belum ada transaksi kas.', style: TextStyle(fontSize: 16)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _transactions.length,
                          itemBuilder: (context, idx) {
                            final tx = _transactions[idx];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: tx.isMasuk ? Colors.green.shade100 : Colors.red.shade100,
                                  child: Icon(
                                    tx.isMasuk ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: tx.isMasuk ? Colors.green.shade800 : Colors.red.shade800,
                                  ),
                                ),
                                title: Text(
                                  '${tx.isMasuk ? "+ " : "- "}${ApiConfig.formatRupiah(tx.amount)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: tx.isMasuk ? const Color(0xFF059669) : Colors.red.shade700,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(tx.note, style: const TextStyle(fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text('📅 ${tx.transactionDate} | Status: ${tx.status.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    if (tx.activityTitle != null) Text('📍 Kegiatan: ${tx.activityTitle}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
