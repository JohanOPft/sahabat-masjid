import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/activity.dart';
import '../../models/mosque_info.dart';
import '../../widgets/app_drawer.dart';

class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({Key? key}) : super(key: key);

  @override
  State<PublicHomeScreen> createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  bool _isLoading = true;
  MosqueInfo? _mosqueInfo;
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final info = await apiService.getMosqueInfo();
      final acts = await apiService.getActivities(status: 'terjadwal');
      setState(() {
        _mosqueInfo = info;
        _activities = acts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(_mosqueInfo?.name ?? 'Sahabat Masjid Al-Ikhlas'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text('Masuk Pengurus', style: TextStyle(color: Colors.white, fontSize: 16)),
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 64 : 16,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HERO BANNER
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF047857)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.mosque, size: 36, color: Colors.amber),
                              SizedBox(width: 12),
                              Text(
                                'Aplikasi Sahabat Masjid v1.0',
                                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _mosqueInfo?.name ?? 'Masjid Al-Ikhlas',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _mosqueInfo?.address ?? 'Semarang, Jawa Tengah',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _mosqueInfo?.description ?? 'Pusat ibadah, kajian, dan penyaluran donasi umat yang amanah, transparan, dan terstruktur.',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // TOMBOL AKSI CEPAT PUBLIK (FR-38)
                    const Text(
                      'Layanan & Menu Utama',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                    ),
                    const SizedBox(height: 12),

                    LayoutBuilder(builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.3,
                        children: [
                          _buildActionTile(
                            context,
                            title: 'Cara Berdonasi',
                            desc: 'Rekening & QRIS Masjid',
                            icon: Icons.volunteer_activism,
                            color: const Color(0xFF059669),
                            route: '/how-to-donate',
                          ),
                          _buildActionTile(
                            context,
                            title: 'Konfirmasi Donasi',
                            desc: 'Kirim bukti & pantau status',
                            icon: Icons.receipt_long,
                            color: const Color(0xFF0D9488),
                            route: '/confirm-donation',
                          ),
                          _buildActionTile(
                            context,
                            title: 'Jadwal Kegiatan',
                            desc: 'Jumat Berkah, Pengajian & PJ',
                            icon: Icons.calendar_month,
                            color: const Color(0xFF2563EB),
                            route: '/public-activities',
                          ),
                          _buildActionTile(
                            context,
                            title: 'Laporan Publik',
                            desc: 'Transparansi keuangan masjid',
                            icon: Icons.bar_chart,
                            color: const Color(0xFFD97706),
                            route: '/public-reports',
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 32),

                    // JADWAL KEGIATAN TERDEKAT (FR-09, FR-38)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kegiatan Terdekat & PJ',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/public-activities'),
                          child: const Text('Lihat Semua Kegiatan →', style: TextStyle(fontSize: 15)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_activities.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text('Belum ada jadwal kegiatan terdekat.', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        itemCount: _activities.take(3).length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, idx) {
                          final act = _activities[idx];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0F766E).withOpacity(0.12),
                                radius: 24,
                                child: const Icon(Icons.event, color: Color(0xFF0F766E)),
                              ),
                              title: Text(
                                act.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text('${act.activityDate} (${act.activityTime})', style: const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                          'PJ: ${act.pjName ?? 'Belum Ditentukan'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: act.needsPj ? Colors.red : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (act.notes != null && act.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(act.notes!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                    ]
                                  ],
                                ),
                              ),
                              trailing: Chip(
                                label: Text(act.type, style: const TextStyle(fontSize: 12, color: Colors.white)),
                                backgroundColor: const Color(0xFF0F766E),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionTile(BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                radius: 24,
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
