import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/activity.dart';
import '../../widgets/app_drawer.dart';

class ActivitiesManageScreen extends StatefulWidget {
  const ActivitiesManageScreen({Key? key}) : super(key: key);

  @override
  State<ActivitiesManageScreen> createState() => _ActivitiesManageScreenState();
}

class _ActivitiesManageScreenState extends State<ActivitiesManageScreen> {
  bool _isLoading = true;
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiService.getActivities();
      setState(() {
        _activities = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddEditDialog([Activity? act]) {
    final titleCtrl = TextEditingController(text: act?.title ?? '');
    String typeVal = act?.type ?? 'Jumat Berkah';
    final dateCtrl = TextEditingController(text: act?.activityDate ?? DateTime.now().toIso8601String().substring(0, 10));
    final timeCtrl = TextEditingController(text: act?.activityTime ?? '11:30 - 13:00 WIB');
    final locCtrl = TextEditingController(text: act?.location ?? 'Masjid Al-Ikhlas');
    final pjCtrl = TextEditingController(text: act?.pjName ?? '');
    final notesCtrl = TextEditingController(text: act?.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text(act == null ? 'Tambah Kegiatan Baru (FR-06)' : 'Ubah Kegiatan (FR-07)'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Kegiatan *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: typeVal,
                    decoration: const InputDecoration(labelText: 'Jenis Kegiatan *', border: OutlineInputBorder()),
                    items: ['Jumat Berkah', 'Pengajian', 'Kegiatan Bulan Puasa', 'Lainnya']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setDlgState(() => typeVal = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateCtrl,
                          decoration: const InputDecoration(labelText: 'Tanggal *', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: timeCtrl,
                          decoration: const InputDecoration(labelText: 'Waktu *', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locCtrl,
                    decoration: const InputDecoration(labelText: 'Lokasi', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pjCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Penanggung Jawab (PJ)',
                      hintText: 'Kosongkan bila belum ditentukan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Keterangan Tambahan', border: OutlineInputBorder()),
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
                if (titleCtrl.text.trim().isEmpty || dateCtrl.text.trim().isEmpty) return;
                try {
                  final body = {
                    'title': titleCtrl.text.trim(),
                    'type': typeVal,
                    'activity_date': dateCtrl.text.trim(),
                    'activity_time': timeCtrl.text.trim(),
                    'location': locCtrl.text.trim(),
                    'pj_name': pjCtrl.text.trim().isEmpty ? null : pjCtrl.text.trim(),
                    'notes': notesCtrl.text.trim(),
                  };
                  if (act == null) {
                    await apiService.createActivity(body);
                  } else {
                    await apiService.updateActivity(act.id, body);
                  }
                  Navigator.pop(ctx);
                  _fetchActivities();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCopyDialog(Activity act) {
    // FR-08: Menyalin kegiatan sebelumnya
    final dateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10));
    final timeCtrl = TextEditingController(text: act.activityTime);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Salin Kegiatan: ${act.title} (FR-08)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sistem akan membuat kegiatan baru dengan rincian sama, Anda dapat mengubah tanggal pelaksanaan:'),
            const SizedBox(height: 12),
            TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Tanggal Baru', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Waktu', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await apiService.copyActivity(act.id, newDate: dateCtrl.text, newTime: timeCtrl.text);
              Navigator.pop(ctx);
              _fetchActivities();
            },
            child: const Text('Salin Sekarang'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Activity act) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Batalkan Kegiatan: ${act.title}'),
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
              await apiService.cancelActivity(act.id, reasonCtrl.text.trim());
              Navigator.pop(ctx);
              _fetchActivities();
            },
            child: const Text('Ya, Batalkan Kegiatan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kegiatan & Jadwal PJ'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddEditDialog()),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/admin/activities'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Kegiatan', style: TextStyle(color: Colors.white)),
        onPressed: () => _showAddEditDialog(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchActivities,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _activities.length,
                itemBuilder: (context, idx) {
                  final act = _activities[idx];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(act.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              Chip(
                                label: Text(act.status.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.white)),
                                backgroundColor: act.status == 'terjadwal'
                                    ? const Color(0xFF059669)
                                    : (act.status == 'selesai' ? Colors.blueGrey : Colors.red),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Text('📅 ${act.activityDate} (${act.activityTime}) | 📍 ${act.location}'),
                          const SizedBox(height: 6),

                          // PENANDA KEGIATAN TANPA PJ (FR-10)
                          Row(
                            children: [
                              Icon(act.needsPj ? Icons.warning : Icons.person, color: act.needsPj ? Colors.red : const Color(0xFF0F766E), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'PJ: ${act.pjName ?? "BELUM ADA PJ (PERLU DILENGKAPI)"}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: act.needsPj ? Colors.red : Colors.black87,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Salin (FR-08)'),
                                onPressed: () => _showCopyDialog(act),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Ubah'),
                                onPressed: () => _showAddEditDialog(act),
                              ),
                              if (act.status != 'dibatalkan')
                                TextButton.icon(
                                  icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                                  label: const Text('Batalkan', style: TextStyle(color: Colors.red)),
                                  onPressed: () => _showCancelDialog(act),
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
