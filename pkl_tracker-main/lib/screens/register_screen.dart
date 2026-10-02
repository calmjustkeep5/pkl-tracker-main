import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _noIndukCtrl = TextEditingController();
  final _sekolahCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;
  bool _isLoading = false;

  double get _passStrength {
    final pass = _passCtrl.text;
    if (pass.isEmpty) return 0;
    double strength = 0;
    if (pass.length >= 6) strength += 0.25;
    if (pass.length >= 8) strength += 0.25;
    if (pass.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (pass.contains(RegExp(r'[0-9!@#\$&*~]'))) strength += 0.25;
    return strength;
  }

  Color get _passStrengthColor {
    if (_passStrength < 0.5) return AppTheme.danger;
    if (_passStrength < 0.75) return AppTheme.warning;
    return AppTheme.success;
  }

  String get _passStrengthLabel {
    if (_passCtrl.text.isEmpty) return '';
    if (_passStrength < 0.5) return 'Lemah';
    if (_passStrength < 0.75) return 'Sedang';
    return 'Kuat';
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _noIndukCtrl.dispose();
    _sekolahCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_namaCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty) {
      _showSnack('Isi semua kolom yang diperlukan');
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _showSnack('Konfirmasi password tidak cocok');
      return;
    }
    if (_passCtrl.text.length < 6) {
      _showSnack('Password minimal 6 karakter');
      return;
    }
    if (!_agreeTerms) {
      _showSnack('Setujui syarat & ketentuan terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    final defaultGuru = widget.role == 'siswa' ? await DatabaseService.getFirstGuru() : null;

    final newUser = UserModel(
      uid: DateTime.now().millisecondsSinceEpoch.toString(),
      nama: _namaCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: widget.role,
      noInduk: _noIndukCtrl.text.trim(),
      sekolah: _sekolahCtrl.text.trim(),
      guruUid: widget.role == 'siswa' ? defaultGuru?.uid : null,
      createdAt: DateTime.now(),
    );

    // Pemanggilan provider yang benar
    final error = await ref.read(authProvider.notifier).register(newUser);
    
    setState(() => _isLoading = false);

    if (error != null) {
      _showSnack(error);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Akun berhasil dibuat! Silakan login.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen(role: widget.role)),
        );
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Daftar',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Isi data dibawah ini untuk membuat akun PKL Tracker',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
                ),
              ),
              const SizedBox(height: 28),

              // Nama Lengkap
              _label('Nama Lengkap'),
              const SizedBox(height: 8),
              _field(
                controller: _namaCtrl,
                hint: 'Masukkan nama lengkap',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              // No Induk (NIS/NIP)
              _label(widget.role == 'siswa' ? 'NIS (Opsional)' : 'NIP (Opsional)'),
              const SizedBox(height: 8),
              _field(
                controller: _noIndukCtrl,
                hint: widget.role == 'siswa' ? 'Nomor Induk Siswa' : 'Nomor Induk Pegawai',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Alamat Email
              _label('Alamat Email'),
              const SizedBox(height: 8),
              _field(
                controller: _emailCtrl,
                hint: 'Masukkan alamat email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Kata Sandi
              _label('Kata Sandi'),
              const SizedBox(height: 8),
              _field(
                controller: _passCtrl,
                hint: 'Masukkan kata sandi',
                icon: Icons.lock_outline,
                obscure: _obscurePass,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Konfirmasi Kata Sandi
              _label('Konfirmasi Kata Sandi'),
              const SizedBox(height: 8),
              _field(
                controller: _confirmPassCtrl,
                hint: 'Ulangi kata sandi',
                icon: Icons.lock_outline,
                obscure: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              // Password strength bar
              if (_passCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Kekuatan kata sandi: ',
                      style: TextStyle(
                        fontSize: 11,
                        color: _passStrengthColor,
                      ),
                    ),
                    Text(
                      _passStrengthLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _passStrengthColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _passStrength,
                    backgroundColor: Colors.grey.shade200,
                    color: _passStrengthColor,
                    minHeight: 4,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Terms & Conditions
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _agreeTerms,
                      onChanged: (v) =>
                          setState(() => _agreeTerms = v ?? false),
                      activeColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontFamily: 'Poppins'),
                        children: [
                          const TextSpan(text: 'Saya menyetujui '),
                          TextSpan(
                            text: 'Syarat & ketentuan',
                            style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: ' dan '),
                          TextSpan(
                            text: 'kebijakan privasi',
                            style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Buat Akun Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Buat Akun'),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Sudah memiliki akun?',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}