import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/mosque_info.dart';
import '../../widgets/app_drawer.dart';

class PublicHowToDonateScreen extends StatefulWidget {
  const PublicHowToDonateScreen({Key? key}) : super(key: key);

  @override
  State<PublicHowToDonateScreen> createState() => _PublicHowToDonateScreenState();
}

class _PublicHowToDonateScreenState extends State<PublicHowToDonateScreen> {
  bool _isLoading = true;
  MosqueInfo? _info;

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  Future<void> _fetchInfo() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiService.getMosqueInfo();
      setState(() {
        _info = res;
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
        title: const Text('Cara Berdonasi (Infaq & Shadaqah)'),
      ),
      drawer: const AppDrawer(currentRoute: '/how-to-donate'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CARD REKENING RESMI MASJID (FR-39)
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'REKENING RESMI MASJID',
                            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _info?.bankName ?? 'Bank Syariah Indonesia (BSI)',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                _info?.bankAccount ?? '7123456789',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Atas Nama: ${_info?.bankHolder ?? "Masjid Al-Ikhlas"}',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // PETUNJUK DONATUR JAUH (Tembalang dll, SRS Bab 1.3)
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.info_outline, color: Color(0xFF0F766E), size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Petunjuk Bagi Donatur',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            _info?.donationInfo ??
                                '1. Transfer donasi ke rekening resmi di atas.\n2. Simpan struk / tangkapan layar bukti transfer.\n3. Masuk ke menu "Konfirmasi Donasi" di aplikasi ini.\n4. Isi nominal dan unggah foto bukti transfer.\n5. Anda akan menerima Kode Referensi untuk memantau status verifikasi pengurus.',
                            style: const TextStyle(fontSize: 15, height: 1.6),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.arrow_forward, color: Colors.white),
                            label: const Text(
                              'Lanjut ke Form Konfirmasi Donasi',
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => Navigator.pushNamed(context, '/confirm-donation'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
