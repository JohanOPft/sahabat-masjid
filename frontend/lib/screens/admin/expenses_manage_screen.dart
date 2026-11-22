import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../services/api_service.dart';
import '../../models/expense.dart';
import '../../models/activity.dart';
import '../../config/api_config.dart';
import '../../widgets/app_drawer.dart';

class ExpensesManageScreen extends StatefulWidget {
  const ExpensesManageScreen({Key? key}) : super(key: key);

  @override
  State<ExpensesManageScreen> createState() => _ExpensesManageScreenState();
}

class _ExpensesManageScreenState extends State<ExpensesManageScreen> {
  bool _isLoading = true;
  List<Expense> _expenses = [];
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final exps = await apiService.getExpenses();
      final acts = await apiService.getActivities();
      setState(() {
        _expenses = exps;
        _activities = acts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddExpenseDialog() {
    int? actId = _activities.isNotEmpty ? _activities.first.id : null;
    String category = 'Konsumsi';
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Catat Pengeluaran Kegiatan (FR-18)'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int?>(
                    value: actId,
                    decoration: const InputDecoration(labelText: 'Kegiatan *', border: OutlineInputBorder()),
                    items: _activities.map((a) => DropdownMenuItem(value: a.id, child: Text(a.title))).toList(),
                    onChanged: (v) => setDlgState(() => actId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Kategori Biaya *', border: OutlineInputBorder()),
                    items: ['Konsumsi', 'Perlengkapan', 'Transportasi', 'Kebersihan', 'Honor Penceramah', 'Lainnya']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setDlgState(() => category = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nominal Biaya (Rp) *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Keterangan Pengeluaran *', border: OutlineInputBorder()),
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
                if (actId == null || amountCtrl.text.isEmpty || descCtrl.text.isEmpty) return;
                try {
                  await apiService.createExpense({
                    'activity_id': actId,
                    'category': category,
                    'description': descCtrl.text.trim(),
                    'amount': double.parse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
                    'proof_photo': '',
                  });
                  Navigator.pop(ctx);
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              },
              child: const Text('Simpan Pengeluaran', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(Expense exp) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Batalkan Pengeluaran #${exp.id} (FR-21)'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Alasan Pembatalan *', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kembali')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              await apiService.cancelExpense(exp.id, reasonCtrl.text.trim());
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencatatan Pengeluaran Kegiatan'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddExpenseDialog),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/admin/expenses'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Catat Pengeluaran', style: TextStyle(color: Colors.white)),
        onPressed: _showAddExpenseDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _expenses.isEmpty
                  ? const Center(child: Text('Belum ada data pengeluaran.', style: TextStyle(fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _expenses.length,
                      itemBuilder: (context, idx) {
                        final exp = _expenses[idx];
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
                                    Text(
                                      ApiConfig.formatRupiah(exp.amount),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    Chip(
                                      label: Text(exp.category),
                                      backgroundColor: Colors.grey.shade200,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(exp.description, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                Text('📅 Tanggal: ${exp.expenseDate} | Status: ${exp.status.toUpperCase()}'),
                                if (exp.activityTitle != null) Text('📍 Terkait: ${exp.activityTitle}', style: const TextStyle(color: Colors.grey)),
                                if (exp.cancelReason != null) Text('Alasan Batal: ${exp.cancelReason}', style: const TextStyle(color: Colors.red)),

                                if (auth.isTakmir && exp.status != 'dibatalkan')
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      icon: const Icon(Icons.cancel, color: Colors.red, size: 16),
                                      label: const Text('Batalkan (Takmir)', style: TextStyle(color: Colors.red)),
                                      onPressed: () => _showCancelDialog(exp),
                                    ),
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
