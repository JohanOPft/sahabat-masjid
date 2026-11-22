import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/mosque_info.dart';
import '../../widgets/app_drawer.dart';

class MosqueInfoScreen extends StatefulWidget {
  const MosqueInfoScreen({Key? key}) : super(key: key);

  @override
  State<MosqueInfoScreen> createState() => _MosqueInfoScreenState();
}

class _MosqueInfoScreenState extends State<MosqueInfoScreen> {
  bool _isLoading = true;
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _bankHolderCtrl = TextEditingController();
  final _donationInfoCtrl = TextEditingController();
  final _waCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    setState(() => _isLoading = true);
    try {
      final info = await apiService.getMosqueInfo();
      _nameCtrl.text = info.name;
      _addressCtrl.text = info.address;
      _descCtrl.text = info.description ?? '';
      _bankNameCtrl.text = info.bankName;
      _bankAccountCtrl.text = info.bankAccount;
      _bankHolderCtrl.text = info.bankHolder;
      _donationInfoCtrl.text = info.donationInfo ?? '';
      _waCtrl.text = info.whatsappContact ?? '';
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    try {
      await apiService.updateMosqueInfo({
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'bank_name': _bankNameCtrl.text.trim(),
        'bank_account': _bankAccountCtrl.text.trim(),
        'bank_holder': _bankHolderCtrl.text.trim(),
        'donation_info': _donationInfoCtrl.text.trim(),
        'whatsapp_contact': _waCtrl.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informasi masjid dan cara berdonasi berhasil diperbarui!'), backgroundColor: Color(0xFF059669)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Masjid & Info Donasi (FR-40)'),
      ),
      drawer: const AppDrawer(currentRoute: '/admin/mosque-info'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Profil & Identitas Masjid', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                  const SizedBox(height: 12),
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama Masjid *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Alamat Lengkap *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Deskripsi Singkat Masjid', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _waCtrl, decoration: const InputDecoration(labelText: 'Nomor WhatsApp Takmir (contoh: 6281234567890)', border: OutlineInputBorder())),

                  const Divider(height: 36),
                  const Text('Rekening Donasi & Petunjuk Infaq', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                  const SizedBox(height: 12),
                  TextField(controller: _bankNameCtrl, decoration: const InputDecoration(labelText: 'Nama Bank / Dompet Digital *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _bankAccountCtrl, decoration: const InputDecoration(labelText: 'Nomor Rekening Resmi *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _bankHolderCtrl, decoration: const InputDecoration(labelText: 'Atas Nama Rekening *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _donationInfoCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Teks Petunjuk Donasi bagi Jamaah & Donatur Jauh', border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _handleSave,
                    child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}
