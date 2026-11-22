import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../widgets/app_drawer.dart';

class UsersManageScreen extends StatefulWidget {
  const UsersManageScreen({Key? key}) : super(key: key);

  @override
  State<UsersManageScreen> createState() => _UsersManageScreenState();
}

class _UsersManageScreenState extends State<UsersManageScreen> {
  bool _isLoading = true;
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiService.getUsers();
      setState(() {
        _users = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'admin';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Tambah Akun Pengurus (FR-04)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Kata Sandi Awal *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Peran Akun *', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin (Marbot)')),
                  DropdownMenuItem(value: 'takmir', child: Text('Takmir (Pengurus Utama)')),
                ],
                onChanged: (v) => setDlgState(() => role = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
                await apiService.createUser(nameCtrl.text.trim(), emailCtrl.text.trim(), passCtrl.text, role);
                Navigator.pop(ctx);
                _loadUsers();
              },
              child: const Text('Buat Akun'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPassDialog(User user) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Kata Sandi: ${user.name}'),
        content: TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Kata Sandi Baru *', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (passCtrl.text.isEmpty) return;
              await apiService.resetPassword(user.id, passCtrl.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kata sandi berhasil diatur ulang.')));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Akun Pengurus (Takmir)'),
        actions: [
          IconButton(icon: const Icon(Icons.person_add), onPressed: _showAddUserDialog),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/admin/users'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, idx) {
                  final u = _users[idx];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: u.isTakmir ? const Color(0xFFD97706) : const Color(0xFF0F766E),
                        child: Icon(u.isTakmir ? Icons.star : Icons.person, color: Colors.white),
                      ),
                      title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text('${u.email} | Peran: ${u.role.toUpperCase()} | Status: ${u.isActive ? "AKTIF" : "NONAKTIF"}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.lock_reset, color: Colors.blue),
                            tooltip: 'Reset Sandi',
                            onPressed: () => _showResetPassDialog(u),
                          ),
                          Switch(
                            value: u.isActive,
                            onChanged: (_) async {
                              await apiService.toggleUserActive(u.id);
                              _loadUsers();
                            },
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
