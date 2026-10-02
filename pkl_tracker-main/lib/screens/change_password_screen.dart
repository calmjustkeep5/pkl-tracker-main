import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart'; // Sesuaikan path ini
// import '../providers/auth_provider.dart'; // Buka komen ini saat integrasi backend

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // State untuk visibilitas password (show/hide)
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _saveNewPassword() async {
    // 1. Validasi form kosong
    if (_oldPassCtrl.text.isEmpty || _newPassCtrl.text.isEmpty || _confirmPassCtrl.text.isEmpty) {
      _showSnack('Semua kolom password wajib diisi!', isError: true);
      return;
    }

    // 2. Validasi kecocokan konfirmasi password
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _showSnack('Password baru dan konfirmasi tidak cocok!', isError: true);
      return;
    }

    // 3. Validasi panjang password (opsional)
    if (_newPassCtrl.text.length < 6) {
      _showSnack('Password baru minimal 6 karakter!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Simulasi loading ke server (nanti ganti dengan panggil API backend)
    await Future.delayed(const Duration(seconds: 2));
    
    // Integrasi backend:
    // try {
    //   await ref.read(authProvider.notifier).changePassword(
    //     oldPass: _oldPassCtrl.text,
    //     newPass: _newPassCtrl.text,
    //   );
    // } catch (e) { ... }

    setState(() => _isLoading = false);

    if (mounted) {
      _showSnack('Password berhasil diubah!', isError: false);
      Navigator.pop(context); // Kembali ke halaman profil setelah sukses
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.danger : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Ganti Password',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // --- HEADER VISUAL ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 60,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Buat Kata Sandi Baru',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan kombinasi yang kuat agar akun Anda tetap aman.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 36),

            // --- FORM INPUT ---
            _buildPasswordField(
              label: 'Password Saat Ini',
              controller: _oldPassCtrl,
              isObscure: _obscureOld,
              onToggleVisibility: () => setState(() => _obscureOld = !_obscureOld),
            ),
            const SizedBox(height: 20),
            _buildPasswordField(
              label: 'Password Baru',
              controller: _newPassCtrl,
              isObscure: _obscureNew,
              onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 20),
            _buildPasswordField(
              label: 'Konfirmasi Password Baru',
              controller: _confirmPassCtrl,
              isObscure: _obscureConfirm,
              onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: 24),

            // --- KOTAK INFO KEAMANAN ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Saran Keamanan',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Minimal 6 karakter. Sangat disarankan menggunakan kombinasi huruf dan angka.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- TOMBOL SIMPAN ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveNewPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'PERBARUI PASSWORD',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget Bantuan Khusus untuk Password Field dengan ikon "Eye"
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggleVisibility,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          textInputAction: textInputAction,
          style: const TextStyle(fontSize: 14, letterSpacing: 1.2), // Letter spacing agar titik password lebih jelas
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, size: 22, color: AppTheme.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 22,
                color: isObscure ? AppTheme.textSecondary : AppTheme.primary,
              ),
              onPressed: onToggleVisibility,
              splashRadius: 20,
            ),
            filled: true,
            fillColor: AppTheme.bgLight.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}