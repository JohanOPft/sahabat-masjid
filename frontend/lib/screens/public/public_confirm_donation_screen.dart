import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/activity.dart';
import '../../models/donation_confirmation.dart';
import '../../widgets/app_drawer.dart';

class PublicConfirmDonationScreen extends StatefulWidget {
  const PublicConfirmDonationScreen({Key? key}) : super(key: key);

  @override
  State<PublicConfirmDonationScreen> createState() => _PublicConfirmDonationScreenState();
}

class _PublicConfirmDonationScreenState extends State<PublicConfirmDonationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form kirim konfirmasi
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  int? _selectedActivityId;
  List<Activity> _activities = [];
  bool _isSubmitting = false;
  String? _successRefCode;

  // Form cek status
  final _refCodeCtrl = TextEditingController();
  bool _isChecking = false;
  DonationConfirmation? _checkedConfirmation;
  String? _checkError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final list = await apiService.getActivities(status: 'terjadwal');
      setState(() => _activities = list);
    } catch (_) {}
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final code = await apiService.submitConfirmation({
        'donor_name': _nameCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'amount': double.parse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')),
        'donation_date': _dateCtrl.text.trim(),
        'activity_id': _selectedActivityId,
        'proof_photo': '',
      });
      setState(() {
        _successRefCode = code;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleCheck() async {
    final code = _refCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _isChecking = true;
      _checkedConfirmation = null;
      _checkError = null;
    });
    try {
      final res = await apiService.checkConfirmation(code);
      setState(() {
        _checkedConfirmation = res;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _checkError = e.toString().replaceAll('Exception: ', '');
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Donasi'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Kirim Konfirmasi'),
            Tab(icon: Icon(Icons.search), text: 'Cek Status (Kode Ref)'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/confirm-donation'),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: FORM KONFIRMASI (FR-27)
          _successRefCode != null ? _buildSuccessView() : _buildFormView(),

          // TAB 2: CEK STATUS KONFIRMASI (FR-31)
          _buildCheckStatusView(),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Formulir Konfirmasi Transfer Donasi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Mohon isi form ini setelah Anda mentransfer donasi agar dapat diverifikasi oleh takmir/marbot.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Donatur (Opsional)',
                hintText: 'Biarkan kosong bila Hamba Allah / Anonim',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _contactCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor WhatsApp / Kontak (Opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal Transfer (Rp) *',
                hintText: 'Contoh: 100000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nominal wajib diisi.';
                final numVal = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                if (numVal == null || numVal <= 0) return 'Nominal harus lebih dari 0.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Tanggal Transfer (YYYY-MM-DD) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Tanggal wajib diisi.' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int?>(
              value: _selectedActivityId,
              decoration: const InputDecoration(
                labelText: 'Tujuan Kegiatan (Opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Umum / Kas Masjid')),
                ..._activities.map((a) => DropdownMenuItem(value: a.id, child: Text(a.title))),
              ],
              onChanged: (val) => setState(() => _selectedActivityId = val),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isSubmitting ? null : _handleSubmit,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Kirim Konfirmasi Donasi', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF059669), size: 64),
                const SizedBox(height: 16),
                const Text('Konfirmasi Berhasil Terkirim!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Kode Referensi Anda:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 6),
                SelectableText(
                  _successRefCode!,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F766E), letterSpacing: 1.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Catat atau salin kode referensi ini untuk memantau status verifikasi pengurus pada tab "Cek Status".',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _successRefCode = null;
                      _nameCtrl.clear();
                      _contactCtrl.clear();
                      _amountCtrl.clear();
                    });
                  },
                  child: const Text('Kirim Konfirmasi Lain'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckStatusView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Lacak Status Konfirmasi Donasi Anda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
          ),
          const SizedBox(height: 8),
          const Text('Masukkan kode referensi donasi (contoh: DON-20261121-0001):'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _refCodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kode Referensi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onPressed: _isChecking ? null : _handleCheck,
                child: _isChecking
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Cek', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_checkError != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_checkError!, style: const TextStyle(color: Colors.red, fontSize: 15)),
              ),
            ),

          if (_checkedConfirmation != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ref: ${_checkedConfirmation!.referenceCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Chip(
                          label: Text(_checkedConfirmation!.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                          backgroundColor: _checkedConfirmation!.isApproved
                              ? const Color(0xFF059669)
                              : (_checkedConfirmation!.isPending ? Colors.amber.shade800 : Colors.red),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text('Donatur: ${_checkedConfirmation!.donorName}', style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Nominal: Rp ${_checkedConfirmation!.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                    const SizedBox(height: 4),
                    Text('Tanggal: ${_checkedConfirmation!.donationDate}', style: const TextStyle(fontSize: 14)),
                    if (_checkedConfirmation!.activityTitle != null) ...[
                      const SizedBox(height: 4),
                      Text('Tujuan Kegiatan: ${_checkedConfirmation!.activityTitle}', style: const TextStyle(fontSize: 14)),
                    ],
                    if (_checkedConfirmation!.rejectReason != null) ...[
                      const SizedBox(height: 10),
                      Text('Alasan Penolakan: ${_checkedConfirmation!.rejectReason}', style: const TextStyle(color: Colors.red, fontSize: 14)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
