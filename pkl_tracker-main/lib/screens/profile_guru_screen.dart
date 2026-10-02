import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../role_selection_screen.dart';
import '../utils/app_theme.dart';
import 'edit_profile_guru_screen.dart';
import 'change_password_screen.dart';

class ProfileGuruScreen extends ConsumerStatefulWidget {
  const ProfileGuruScreen({super.key});

  @override
  ConsumerState<ProfileGuruScreen> createState() => _ProfileGuruScreenState();
}

class _ProfileGuruScreenState extends ConsumerState<ProfileGuruScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // --- FUNGSI MEMBUKA GALERI (SAMA SEPERTI SISI SISWA) ---
  Future<void> _changeProfilePicture() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Kompres kualitas gambar agar hemat penyimpanan
      );
      
      if (pickedFile != null) {
        final currentUser = ref.read(authProvider).valueOrNull;
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(photoUrl: pickedFile.path);
          await ref.read(authProvider.notifier).updateProfile(updatedUser);
        }

        setState(() {
          _imageFile = File(pickedFile.path);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Foto profil berhasil diperbarui'),
              backgroundColor: AppTheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final String namaGuru = user?.nama ?? 'Nama tidak tersedia';
    final String nipGuru = user?.noInduk ?? '-';
    final String emailGuru = user?.email ?? '-';
    final String phoneGuru = user?.phone ?? '-';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil Guru',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        actions: [
          // Tombol Navigasi ke Halaman Edit Profil di Pojok Kanan Atas
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileGuruScreen()),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- BAGIAN 1: FOTO PROFIL ---
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 4),
                      image: _imageFile != null
                          ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                          : (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                              ? DecorationImage(image: FileImage(File(user.photoUrl!)), fit: BoxFit.cover)
                              : const DecorationImage(
                                  image: AssetImage('assets/images/default_avatar.png'), 
                                  fit: BoxFit.cover,
                                ),
                      color: AppTheme.bgLight,
                    ),
                    // Jika tidak ada gambar, tampilkan fallback icon person
                    child: (_imageFile == null && (user?.photoUrl == null || user!.photoUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _changeProfilePicture,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ganti Foto Profil',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
            
            const SizedBox(height: 32),

            // --- BAGIAN 2: INFORMASI PROFILE (READ ONLY) ---
            _buildInfoCard(label: 'Nama Lengkap', value: namaGuru, icon: Icons.person_outline),
            const SizedBox(height: 14),
            _buildInfoCard(label: 'NIP', value: nipGuru, icon: Icons.badge_outlined),
            const SizedBox(height: 14),
            _buildInfoCard(label: 'Email (Tidak dapat diubah)', value: emailGuru, icon: Icons.email_outlined),
            const SizedBox(height: 14),
            _buildInfoCard(label: 'Nomor WhatsApp', value: phoneGuru, icon: Icons.phone_outlined),
            
            const SizedBox(height: 28),
            const Divider(color: Color(0xFFEEEEEE), thickness: 1.5),
            const SizedBox(height: 16),

            // --- BAGIAN 3: PENGATURAN AKUN ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pengaturan Akun',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Menu Ganti Password
            _buildSettingsMenu(
              title: 'Ganti Password',
              subtitle: 'Perbarui kata sandi untuk keamanan',
              icon: Icons.lock_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                );
              },
            ),
            
            // Menu Logout
            _buildSettingsMenu(
              title: 'Keluar',
              subtitle: 'Akhiri sesi pada perangkat ini',
              icon: Icons.logout_rounded,
              isDestructive: true,
              onTap: () => _logout(context, ref),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget Bantuan untuk Tampilan Kartu Informasi yang Bersih
  Widget _buildInfoCard({required String label, required String value, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget Bantuan untuk Menu Pengaturan
  Widget _buildSettingsMenu({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive ? AppTheme.danger.withValues(alpha: 0.1) : AppTheme.bgLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: isDestructive ? AppTheme.danger : AppTheme.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDestructive ? AppTheme.danger : AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun PKL Tracker?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Keluar Akun'),
          ),
        ],
      ),
    );
  }
}