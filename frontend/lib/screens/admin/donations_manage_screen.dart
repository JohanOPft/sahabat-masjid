import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../services/api_service.dart';
import '../../models/donation.dart';
import '../../models/activity.dart';
import '../../config/api_config.dart';
import '../../widgets/app_drawer.dart';

class DonationsManageScreen extends StatefulWidget {
  const DonationsManageScreen({Key? key}) : super(key: key);

  @override
  State<DonationsManageScreen> createState() => _DonationsManageScreenState();
}

class _DonationsManageScreenState extends State<DonationsManageScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Donation> _donations = [];
  List<Activity> _activities = [];
  String _selectedTypeFilter = 'semua';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dons = await apiService.getDonations();
      final acts = await apiService.getActivities();
      setState(() {
        _donations = dons;
        _activities = acts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddDonationDialog() {
    String type = 'uang';
    final nameCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    final portionsCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String method = 'tunai';
    int? actId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Catat Donasi Baru (FR-11, FR-12)'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Jenis Donasi:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['uang', 'barang', 'jasa', 'makanan'].map((t) {
                      final isSel = type == t;
                      return ChoiceChip(
                        label: Text(t.toUpperCase()),
                        selected: isSel,
                        selectedColor: const Color(0xFF0F766E),
                        labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                        onSelected: (val) {
                          if (val) setDlgState(() => type = t);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Donatur (Opsional / Anonim)',
                      hintText: 'Biarkan kosong bila Hamba Allah',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int?>(
                    value: actId,
                    decoration: const InputDecoration(labelText: 'Terkait Kegiatan (Opsional)', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Umum / Tanpa Kegiatan')),
                      ..._activities.map((a) => DropdownMenuItem(value: a.id, child: Text(a.title))),
                    ],
                    onChanged: (v) => setDlgState(() => actId = v),
                  ),
                  const SizedBox(height: 12),

                  if (type == 'uang') ...[
                    TextField(
                      controller: valCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nominal Donasi Uang (Rp) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: method,
                      decoration: const InputDecoration(labelText: 'Metode Pembayaran *', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'tunai', child: Text('Tunai (Cash)')),
                        DropdownMenuItem(value: 'transfer', child: Text('Transfer Bank / QRIS')),
                      ],
                      onChanged: (v) => setDlgState(() => method = v!),
                    ),
                  ] else if (type == 'makanan') ...[
                    TextField(
                      controller: portionsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Porsi Makanan *',
                        hintText: 'Contoh: 50',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Makanan *',
                        hintText: 'Contoh: Nasi bungkus ayam geprek',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else ...[
                    // Barang & Jasa
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi ${type.toUpperCase()} *',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: valCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Perkiraan Nilai Rupiah (Rp) *',
                        hintText: 'Nilai taksiran',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
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
                  final body = {
                    'type': type,
                    'donor_name': nameCtrl.text.trim().isEmpty ? 'Hamba Allah' : nameCtrl.text.trim(),
                    'activity_id': actId,
                    'description': descCtrl.text.trim(),
                    'value_amount': double.tryParse(valCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0,
                    'portions': int.tryParse(portionsCtrl.text.trim()),
                    'payment_method': type == 'uang' ? method : null,
                  };
                  await apiService.createDonation(body);
                  Navigator.pop(ctx);
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              },
              child: const Text('Simpan Donasi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(Donation don) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Batalkan Donasi #${don.id} (FR-16)'),
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
              await apiService.cancelDonation(don.id, reasonCtrl.text.trim());
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
    final filtered = _donations.where((d) {
      if (_selectedTypeFilter == 'semua') return true;
      return d.type == _selectedTypeFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencatatan Donasi (4 Jenis)'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDonationDialog),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/admin/donations'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Catat Donasi', style: TextStyle(color: Colors.white)),
        onPressed: _showAddDonationDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // Filter bar jenis donasi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey.shade50,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['semua', 'uang', 'barang', 'jasa', 'makanan'].map((t) {
                          final isSel = _selectedTypeFilter == t;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(t.toUpperCase()),
                              selected: isSel,
                              selectedColor: const Color(0xFF0F766E),
                              labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87),
                              onSelected: (val) {
                                if (val) setState(() => _selectedTypeFilter = t);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('Belum ada data donasi.', style: TextStyle(fontSize: 16)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, idx) {
                              final d = filtered[idx];
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
                                          Text(d.donorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          Chip(
                                            label: Text(d.type.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.white)),
                                            backgroundColor: d.type == 'uang' ? const Color(0xFF059669) : const Color(0xFF0F766E),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      if (d.type == 'uang')
                                        Text(
                                          ApiConfig.formatRupiah(d.valueAmount),
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                        )
                                      else if (d.type == 'makanan')
                                        Text(
                                          '${d.portions} Porsi (${d.description ?? "-"})',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                        )
                                      else
                                        Text(
                                          '${d.description ?? "-"} (Est: ${ApiConfig.formatRupiah(d.valueAmount)})',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      const SizedBox(height: 8),
                                      Text('📅 Tanggal: ${d.donationDate} | Status: ${d.status.toUpperCase()}'),
                                      if (d.activityTitle != null) Text('📍 Terkait: ${d.activityTitle}', style: const TextStyle(color: Colors.grey)),
                                      if (d.cancelReason != null) Text('Alasan Batal: ${d.cancelReason}', style: const TextStyle(color: Colors.red)),

                                      // Takmir can cancel donation (FR-16)
                                      if (auth.isTakmir && d.status != 'dibatalkan')
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            icon: const Icon(Icons.cancel, color: Colors.red, size: 16),
                                            label: const Text('Batalkan Donasi (Takmir)', style: TextStyle(color: Colors.red)),
                                            onPressed: () => _showCancelDialog(d),
                                          ),
                                        ),
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
