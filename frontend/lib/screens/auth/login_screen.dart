import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'takmir@alikhlas.id');
  final _passCtrl = TextEditingController(text: 'takmir123');
  bool _obscurePass = true;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    final auth = Provider.of<AuthState>(context, listen: false);

    try {
      await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
      if (mounted) {
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
        title: const Text('Masuk Pengurus Masjid'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
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
                          child: Icon(Icons.mosque, size: 40, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sahabat Masjid',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Portal Masuk Admin (Marbot) & Takmir',
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

                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: 'Email Pengurus',
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
                          labelText: 'Kata Sandi',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Kata sandi wajib diisi.' : null,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: auth.isLoading ? null : _handleLogin,
                        child: auth.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Masuk ke Dashboard', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Belum memiliki akun pengurus?'),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/register'),
                            child: const Text('Daftar di sini', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Info Akun Bawaan (Default Demo Accounts)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Akun Bawaan (Sesuai SRS):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            SizedBox(height: 4),
                            Text('• Takmir: takmir@alikhlas.id / takmir123', style: TextStyle(fontSize: 12)),
                            Text('• Marbot: marbot@alikhlas.id / marbot123', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                        child: const Text('← Kembali ke Beranda Publik', style: TextStyle(fontSize: 15)),
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
