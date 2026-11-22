import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/donation_confirmation.dart';
import '../../config/api_config.dart';
import '../../widgets/app_drawer.dart';

class ConfirmationsManageScreen extends StatefulWidget {
  const ConfirmationsManageScreen({Key? key}) : super(key: key);

  @override
  State<ConfirmationsManageScreen> createState() => _ConfirmationsManageScreenState();
}

class _ConfirmationsManageScreenState extends State<ConfirmationsManageScreen> {
  bool _isLoading = true;
  List<DonationConfirmation> _confirmations = [];
  String _filter = 'menunggu';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiService.getConfirmations(status: _filter == 'semua' ? null : _filter);
      setState(() {
        _confirmations = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showApproveConfirmDialog(DonationConfirmation conf) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Setujui Konfirmasi Donasi (FR-29)'),
        content: Text(
          'Apakah Anda yakin menyetujui transfer dari "${conf.donorName}" sebesar ${ApiConfig.formatRupiah(conf.amount)}?\n\n'
          'Sistem akan otomatis mencatat data ini ke daftar donasi terverifikasi.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
            onPressed: () async {
              await apiService.approveConfirmation(conf.id);
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Ya, Setujui', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(DonationConfirmation conf) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Konfirmasi Donasi'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Alasan Penolakan *', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kembali')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              await apiService.rejectConfirmation(conf.id, reasonCtrl.text.trim());
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Tolak Konfirmasi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Konfirmasi Donasi Donatur'),
      ),
      drawer: const AppDrawer(currentRoute: '/admin/confirmations'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // Filter Chips
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: ['menunggu', 'disetujui', 'ditolak', 'semua'].map((f) {
                        final isSel = _filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(f.toUpperCase()),
                            selected: isSel,
                            selectedColor: const Color(0xFF0F766E),
                            labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                            onSelected: (val) {
                              if (val) {
                                setState(() => _filter = f);
                                _loadData();
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  Expanded(
                    child: _confirmations.isEmpty
                        ? const Center(child: Text('Tidak ada konfirmasi donasi.', style: TextStyle(fontSize: 16)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _confirmations.length,
                            itemBuilder: (context, idx) {
                              final conf = _confirmations[idx];
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
                                          Text('Ref: ${conf.referenceCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Chip(
                                            label: Text(conf.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11)),
                                            backgroundColor: conf.isApproved
                                                ? const Color(0xFF059669)
                                                : (conf.isPending ? Colors.amber.shade800 : Colors.red),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 16),
                                      Text(
                                        ApiConfig.formatRupiah(conf.amount),
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                                      ),
                                      const SizedBox(height: 6),
                                      Text('Donatur: ${conf.donorName} | Kontak: ${conf.contact ?? "-"}'),
                                      Text('Tanggal: ${conf.donationDate}'),
                                      if (conf.activityTitle != null) Text('Terkait Kegiatan: ${conf.activityTitle}'),
                                      if (conf.rejectReason != null) Text('Alasan Penolakan: ${conf.rejectReason}', style: const TextStyle(color: Colors.red)),

                                      if (conf.isPending) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(Icons.close, color: Colors.red),
                                              label: const Text('Tolak', style: TextStyle(color: Colors.red)),
                                              onPressed: () => _showRejectDialog(conf),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                                              icon: const Icon(Icons.check, color: Colors.white),
                                              label: const Text('Setujui & Verifikasi', style: TextStyle(color: Colors.white)),
                                              onPressed: () => _showApproveConfirmDialog(conf),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
