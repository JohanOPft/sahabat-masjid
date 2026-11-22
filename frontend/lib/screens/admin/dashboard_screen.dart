import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _cashData = {};
  Map<String, dynamic> _reportData = {};
  int _pendingConfirmationsCount = 0;
  int _activitiesNeedingPjCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final cash = await apiService.getCashSummary();
      final rep = await apiService.getReportSummary();
      final confs = await apiService.getConfirmations(status: 'menunggu');
      final acts = await apiService.getActivities(status: 'terjadwal');
      final needingPj = acts.where((a) => a.needsPj).length;

      setState(() {
        _cashData = cash;
        _reportData = rep;
        _pendingConfirmationsCount = confs.length;
        _activitiesNeedingPjCount = needingPj;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard ${auth.currentUser?.role.toUpperCase() ?? "Pengurus"}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDashboard),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/admin/dashboard'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Sapaan Pengurus
                  Card(
                    color: const Color(0xFF0F766E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 36, color: Color(0xFF0F766E)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assalamu\'alaikum, ${auth.currentUser?.name ?? "Pengurus"}',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Peran: ${auth.currentUser?.role == "takmir" ? "Takmir (Pengawas & Kas)" : "Admin (Marbot)"}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PERINGATAN / ALERT NOTIFIKASI
                  if (_pendingConfirmationsCount > 0)
                    Card(
                      color: Colors.amber.shade100,
                      child: ListTile(
                        leading: const Icon(Icons.notifications_active, color: Colors.orange),
                        title: Text(
                          '$_pendingConfirmationsCount Donasi Menunggu Verifikasi',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        subtitle: const Text('Donatur jauh telah mengirim bukti transfer. Mohon ditinjau.'),
                        trailing: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/admin/confirmations'),
                          child: const Text('Periksa'),
                        ),
                      ),
                    ),

                  if (_activitiesNeedingPjCount > 0)
                    Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        title: Text(
                          '$_activitiesNeedingPjCount Kegiatan Belum Memiliki Penanggung Jawab (PJ)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        subtitle: const Text('Lengkapi nama PJ agar koordinasi kegiatan jelas (FR-10).'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pushNamed(context, '/admin/activities'),
                          child: const Text('Lengkapi', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // METRIK STATISTIK UTAMA
                  const Text('Ringkasan Keuangan & Donasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                  const SizedBox(height: 12),

                  LayoutBuilder(builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 650;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                          child: StatCard(
                            title: 'Saldo Kas Masjid',
                            value: ApiConfig.formatRupiah(_cashData['current_balance'] ?? 0),
                            icon: Icons.savings,
                            color: const Color(0xFF059669),
                            subtitle: 'Hanya dari transaksi kas (BR-03)',
                          ),
                        ),
                        SizedBox(
                          width: isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                          child: StatCard(
                            title: 'Total Donasi Uang Tercatat',
                            value: ApiConfig.formatRupiah(_reportData['total_money_donation'] ?? 0),
                            icon: Icons.volunteer_activism,
                            color: const Color(0xFF0F766E),
                            subtitle: 'Donasi uang terverifikasi',
                          ),
                        ),
                        SizedBox(
                          width: isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                          child: StatCard(
                            title: 'Total Pengeluaran Kegiatan',
                            value: ApiConfig.formatRupiah(_reportData['total_expense'] ?? 0),
                            icon: Icons.shopping_bag,
                            color: Colors.red.shade700,
                            subtitle: 'Biaya pelaksanaan kegiatan',
                          ),
                        ),
                        SizedBox(
                          width: isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                          child: StatCard(
                            title: 'Donasi Makanan Terkumpul',
                            value: '${_reportData['total_food_portions'] ?? 0} Porsi',
                            icon: Icons.fastfood,
                            color: const Color(0xFFD97706),
                            subtitle: 'Jumat Berkah & kegiatan',
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 28),

                  // MENU PINTAS OPERASIONAL (Alur Cepat)
                  const Text('Aksi & Input Cepat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Catat Donasi Baru', style: TextStyle(color: Colors.white, fontSize: 15)),
                          onPressed: () => Navigator.pushNamed(context, '/admin/donations'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                          label: const Text('Catat Pengeluaran', style: TextStyle(color: Colors.white, fontSize: 15)),
                          onPressed: () => Navigator.pushNamed(context, '/admin/expenses'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
