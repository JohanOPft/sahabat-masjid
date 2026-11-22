import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  String _selectedRole = 'admin'; // 'admin' (Marbot) atau 'takmir'
  bool _obscurePass = true;
  String? _errorMessage;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _errorMessage = 'Konfirmasi kata sandi tidak cocok.');
      return;
    }

    setState(() => _errorMessage = null);
    final auth = Provider.of<AuthState>(context, listen: false);

    try {
      await auth.register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passCtrl.text,
        _selectedRole,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pendaftaran berhasil sebagai ${_selectedRole.toUpperCase()}!'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Pengurus Masjid'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Center(
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Color(0xFF0F766E),
                          child: Icon(Icons.person_add_alt_1, size: 40, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Registrasi Pengurus Baru',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Daftar akun sebagai Admin (Marbot) atau Takmir Masjid Al-Ikhlas',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14))),
                            ],
                          ),
                        ),

                      // PILIHAN PERAN (ADMIN / MARBOT atau TAKMIR)
                      const Text('Pilih Peran Pengurus:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedRole = 'admin'),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'admin' ? const Color(0xFF0F766E).withOpacity(0.12) : Colors.grey.shade100,
                                  border: Border.all(
                                    color: _selectedRole == 'admin' ? const Color(0xFF0F766E) : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: const [
                                    Icon(Icons.badge, color: Color(0xFF0F766E)),
                                    SizedBox(height: 4),
                                    Text('Admin (Marbot)', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Pencatat donasi & PJ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _selectedRole = 'takmir'),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _selectedRole == 'takmir' ? const Color(0xFFD97706).withOpacity(0.12) : Colors.grey.shade100,
                                  border: Border.all(
                                    color: _selectedRole == 'takmir' ? const Color(0xFFD97706) : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: const [
                                    Icon(Icons.star, color: Color(0xFFD97706)),
                                    SizedBox(height: 4),
                                    Text('Takmir (Pengawas)', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Kelola kas & laporan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _nameCtrl,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap *',
                          hintText: 'Contoh: Mas Rizki (Marbot)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Nama lengkap wajib diisi.' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: 'Alamat Email *',
                          hintText: 'nama@alikhlas.id',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Email wajib diisi.' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi (Min. 6 Karakter) *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Kata sandi wajib diisi.';
                          if (v.length < 6) return 'Kata sandi minimal 6 karakter.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPassCtrl,
                        obscureText: _obscurePass,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: 'Konfirmasi Kata Sandi *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Konfirmasi kata sandi wajib diisi.' : null,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: auth.isLoading ? null : _handleRegister,
                        child: auth.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Daftar Sebagai ${_selectedRole.toUpperCase()}',
                                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Sudah memiliki akun pengurus?'),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: const Text('Masuk di sini', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
