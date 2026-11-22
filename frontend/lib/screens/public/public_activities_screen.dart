import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/activity.dart';
import '../../widgets/app_drawer.dart';

class PublicActivitiesScreen extends StatefulWidget {
  const PublicActivitiesScreen({Key? key}) : super(key: key);

  @override
  State<PublicActivitiesScreen> createState() => _PublicActivitiesScreenState();
}

class _PublicActivitiesScreenState extends State<PublicActivitiesScreen> {
  bool _isLoading = true;
  List<Activity> _activities = [];
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoading = true);
    try {
      final acts = await apiService.getActivities();
      setState(() {
        _activities = acts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _activities.where((a) {
      if (_selectedFilter == 'Semua') return true;
      return a.type == _selectedFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kegiatan & PJ Masjid'),
      ),
      drawer: const AppDrawer(currentRoute: '/public-activities'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchActivities,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Filter bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Semua', 'Jumat Berkah', 'Pengajian', 'Kegiatan Bulan Puasa', 'Lainnya'].map((f) {
                        final isSel = _selectedFilter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(f, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontSize: 14)),
                            selected: isSel,
                            selectedColor: const Color(0xFF0F766E),
                            onSelected: (val) {
                              if (val) setState(() => _selectedFilter = f);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('Tidak ada kegiatan pada kategori ini.', style: TextStyle(fontSize: 16))),
                    )
                  else
                    ...filtered.map((act) => Card(
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
                                      child: Text(
                                        act.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(act.status.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.white)),
                                      backgroundColor: act.status == 'terjadwal'
                                          ? const Color(0xFF059669)
                                          : (act.status == 'selesai' ? Colors.blueGrey : Colors.red),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    const Icon(Icons.category, size: 16, color: Color(0xFF0F766E)),
                                    const SizedBox(width: 8),
                                    Text('Jenis: ${act.type}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF0F766E)),
                                    const SizedBox(width: 8),
                                    Text('Tanggal: ${act.activityDate} (${act.activityTime})', style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Color(0xFF0F766E)),
                                    const SizedBox(width: 8),
                                    Text('Lokasi: ${act.location}', style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: Color(0xFF0F766E)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Penanggung Jawab (PJ): ${act.pjName ?? '(Belum Ditentukan)'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: act.needsPj ? Colors.red : const Color(0xFF0F766E),
                                      ),
                                    ),
                                  ],
                                ),
                                if (act.notes != null && act.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('Keterangan: ${act.notes}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
