import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              auth.isLoggedIn ? auth.currentUser!.name : 'Sahabat Masjid',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              auth.isLoggedIn 
                  ? '${auth.currentUser!.email} (${auth.currentUser!.role.toUpperCase()})'
                  : 'Masjid Al-Ikhlas Semarang',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                auth.isLoggedIn ? Icons.admin_panel_settings : Icons.mosque,
                size: 40,
                color: const Color(0xFF0F766E),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // MENU PUBLIK
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'HALAMAN PUBLIK',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home, color: Color(0xFF0F766E)),
                  title: const Text('Beranda Publik', style: TextStyle(fontSize: 16)),
                  selected: currentRoute == '/',
                  onTap: () => Navigator.pushReplacementNamed(context, '/'),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month, color: Color(0xFF0F766E)),
                  title: const Text('Jadwal Kegiatan & PJ', style: TextStyle(fontSize: 16)),
                  selected: currentRoute == '/public-activities',
                  onTap: () => Navigator.pushReplacementNamed(context, '/public-activities'),
                ),
                ListTile(
                  leading: const Icon(Icons.volunteer_activism, color: Color(0xFF0F766E)),
                  title: const Text('Cara Berdonasi', style: TextStyle(fontSize: 16)),
                  selected: currentRoute == '/how-to-donate',
                  onTap: () => Navigator.pushReplacementNamed(context, '/how-to-donate'),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: Color(0xFF0F766E)),
                  title: const Text('Konfirmasi Donasi', style: TextStyle(fontSize: 16)),
                  selected: currentRoute == '/confirm-donation',
                  onTap: () => Navigator.pushReplacementNamed(context, '/confirm-donation'),
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Color(0xFF0F766E)),
                  title: const Text('Laporan Transparansi', style: TextStyle(fontSize: 16)),
                  selected: currentRoute == '/public-reports',
                  onTap: () => Navigator.pushReplacementNamed(context, '/public-reports'),
                ),

                const Divider(),

                // MENU PENGURUS (Jika Sudah Login)
                if (auth.isLoggedIn) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'PENGELOLAAN (${auth.currentUser!.role.toUpperCase()})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dashboard, color: Color(0xFF059669)),
                    title: const Text('Dashboard Pengurus', style: TextStyle(fontSize: 16)),
                    selected: currentRoute == '/admin/dashboard',
                    onTap: () => Navigator.pushReplacementNamed(context, '/admin/dashboard'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_note, color: Color(0xFF059669)),
                    title: const Text('Kelola Kegiatan & PJ', style: TextStyle(fontSize: 16)),
                    selected: currentRoute == '/admin/activities',
                    onTap: () => Navigator.pushReplacementNamed(context, '/admin/activities'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF059669)),
                    title: const Text('Pencatatan Donasi', style: TextStyle(fontSize: 16)),
                    selected: currentRoute == '/admin/donations',
                    onTap: () => Navigator.pushReplacementNamed(context, '/admin/donations'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart, color: Color(0xFF059669)),
                    title: const Text('Catat Pengeluaran', style: TextStyle(fontSize: 16)),
                    selected: currentRoute == '/admin/expenses',
                    onTap: () => Navigator.pushReplacementNamed(context, '/admin/expenses'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.savings, color: Color(0xFF059669)),
                    title: const Text('Kas & Selisih Kegiatan', style: TextStyle(fontSize: 16)),
                    selected: currentRoute == '/admin/cash',
                    onTap: () => Navigator.pushReplacementNamed(context, '/admin/cash'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.verified, color: Color(0xFF059669)),
                    title: const Text('Verifikasi Konfirmasi', style: TextStyle(fontSize: 16)),
                    selected: currentRoute == '/admin/confirmations',
                    onTap: () => Navigator.pushReplacementNamed(context, '/admin/confirmations'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.assessment, color: Color(0xFF059669)),
                    title: const Text('Laporan & Publikasi', style: TextStyle(fontSize: 16)),
                    selected: currentRoute == '/admin/reports',
                    onTap: () => Navigator.pushReplacementNamed(context, '/admin/reports'),
                  ),

                  // Menu Khusus Takmir
                  if (auth.isTakmir) ...[
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'PENGATURAN TAKMIR',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.people, color: Color(0xFFD97706)),
                      title: const Text('Kelola Akun Pengurus', style: TextStyle(fontSize: 16)),
                      selected: currentRoute == '/admin/users',
                      onTap: () => Navigator.pushReplacementNamed(context, '/admin/users'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.store, color: Color(0xFFD97706)),
                      title: const Text('Profil & Info Donasi', style: TextStyle(fontSize: 16)),
                      selected: currentRoute == '/admin/mosque-info',
                      onTap: () => Navigator.pushReplacementNamed(context, '/admin/mosque-info'),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const Divider(),
          if (auth.isLoggedIn)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Keluar dari Akun', style: TextStyle(fontSize: 16, color: Colors.red)),
              onTap: () {
                auth.logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login, color: Color(0xFF0F766E)),
              title: const Text('Masuk Pengurus (Marbot/Takmir)', style: TextStyle(fontSize: 16)),
              onTap: () => Navigator.pushNamed(context, '/login'),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
