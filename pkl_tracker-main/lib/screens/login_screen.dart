import '../main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'register_screen.dart';
import 'auth/forgot_password_screen.dart'; // Jalur import menuju screen Lupa Password

class LoginScreen extends ConsumerStatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showSnack('Isi semua kolom terlebih dahulu');
      return;
    }
    setState(() => _isLoading = true);
    final error = await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
    setState(() => _isLoading = false);

    if (error != null) {
      _showSnack(error);
    } else {
      final user = ref.read(authProvider).valueOrNull;
      if (user != null) {
        
        // =====================================================================
        // GERBANG VALIDASI ROLE (Mencegah Siswa masuk sebagai Guru & Sebaliknya)
        // =====================================================================
        if (user.role.toLowerCase() != widget.role.toLowerCase()) {
          // Tampilkan pesan penolakan yang informatif
          _showSnack('Akses ditolak: Akun terdaftar sebagai ${user.role}, bukan ${widget.role}.');
          
          // Paksa logout/bersihkan session di provider agar tidak nyangkut
          ref.read(authProvider.notifier).logout();
          return; // Hentikan fungsi di sini agar tidak lanjut pindah screen
        }
        // =====================================================================

        // Jika lolos validasi role, barulah izinkan masuk ke MainScreen
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainScreen(role: user.role)),
            (route) => false,
          );
        }
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            children: [
              const SizedBox(height: 48),
              // Logo
              _buildLogo(),
              const SizedBox(height: 32),
              // Email Field
              _buildLabel('Email'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Masukkan email',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              // Password Field
              _buildLabel('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  hintText: 'Masukkan password',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppTheme.textSecondary),
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
                ),
              ),
              const SizedBox(height: 12),
              // Remember me & Lupa Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                          activeColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Ingat saya',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigasi clean ke halaman ForgotPasswordScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    style:
                        TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text(
                      'Lupa Password?',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('MASUK'),
                ),
              ),
              const SizedBox(height: 24),
              // Daftar link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum punya akun? ',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RegisterScreen(role: widget.role)),
                    ),
                    child: const Text(
                      'Daftar',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'PT',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                  letterSpacing: -1,
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppTheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on,
                      color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'PKL TRACKER',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Presensi', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('•', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ),
            Text('Logbook', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('•', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ),
            Text('Monitoring', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Masuk ke akun Anda',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}