import 'dart:io'; // Penting untuk membaca file lokal
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../role_selection_screen.dart';
import 'riwayat_presensi_screen.dart';
import 'edit_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';

class ProfilSiswaScreen extends ConsumerWidget {
  const ProfilSiswaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau perubahan data secara real-time
    final userAsync = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Profil Siswa', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        centerTitle: true,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Gagal memuat data: $error')),
        data: (user) {
          // Siapkan baris info akademik
          List<Widget> infoRows = [];
          if (user?.noInduk != null && user!.noInduk!.isNotEmpty) {
            infoRows.add(_InfoRow(icon: Icons.badge_outlined, label: 'NIS / No. Induk', value: user.noInduk!));
          }
          if (user?.sekolah != null && user!.sekolah!.isNotEmpty) {
            infoRows.add(_InfoRow(icon: Icons.school_outlined, label: 'Asal Sekolah', value: user.sekolah!));
          }
          if (user?.jurusan != null && user!.jurusan!.isNotEmpty) {
            infoRows.add(_InfoRow(icon: Icons.account_tree_outlined, label: 'Jurusan', value: user.jurusan!));
          }
          if (user?.alamat != null && user!.alamat!.isNotEmpty) {
            infoRows.add(_InfoRow(icon: Icons.location_on_outlined, label: 'Alamat', value: user.alamat!));
          }

          // === LOGIKA FOTO PINTAR (MEMBACA LOKAL & INTERNET) ===
          final userPhoto = user?.photoUrl;
          final bool hasPhoto = userPhoto != null && userPhoto.isNotEmpty;
          // Cek apakah URL berawalan http (internet) atau path lokal file HP
          final bool isNetworkUrl = hasPhoto && (userPhoto.startsWith('http') || userPhoto.startsWith('https'));

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // --- SECTION 1: AVATAR & INFO DASAR ---
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                          // Jika ada foto, tentukan pakai NetworkImage atau FileImage
                          backgroundImage: hasPhoto
                              ? (isNetworkUrl
                                  ? NetworkImage(userPhoto) as ImageProvider
                                  : FileImage(File(userPhoto)))
                              : null,
                          // Jika TIDAK ADA foto, tampilkan inisial huruf
                          child: !hasPhoto
                              ? Text(
                                  user?.nama != null && user!.nama.isNotEmpty
                                      ? user.nama[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle, size: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.nama ?? 'Siswa PKL',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '-',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Siswa Magang Aktif',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- SECTION 2: INFO AKADEMIK ---
              if (infoRows.isNotEmpty) ...[
                const Text(
                  "Informasi Akademik",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: infoRows.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Widget row = entry.value;
                      return Column(
                        children: [
                          row,
                          if (idx < infoRows.length - 1)
                            const Divider(height: 20, color: AppTheme.border),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // --- SECTION 3: MENU UTAMA ---
              const Text(
                "Pengaturan Akun",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              _ProfileMenu(
                items: [
                  _MenuItem(
                    icon: Icons.person_outline,
                    label: 'Edit Profil',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.lock_outline,
                    label: 'Ubah Password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.history_rounded,
                    label: 'Riwayat Presensi',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RiwayatPresensiScreen()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.info_outline,
                    label: 'Tentang Aplikasi',
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- SECTION 4: MENU KELUAR ---
              _ProfileMenu(
                items: [
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Keluar dari Akun',
                    color: AppTheme.danger,
                    onTap: () => _logout(context, ref),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  "PKL Tracker v1.0.0",
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                ),
              ),
            ],
          );
        },
      ),
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

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'PKL Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: Image.asset(
        'assets/logo_pkl.png', 
        width: 50, 
        height: 50, 
        errorBuilder: (c, e, s) => const Icon(Icons.track_changes, size: 50, color: AppTheme.primary)
      ),
      applicationLegalese: '© 2026 PKL Tracker Developer Team',
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final List<_MenuItem> items;
  const _ProfileMenu({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Icon(item.icon, color: item.color ?? AppTheme.textPrimary, size: 22),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w500, 
                    color: item.color ?? AppTheme.textPrimary
                  )
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textSecondary),
                onTap: item.onTap,
              ),
              if (i < items.length - 1)
                const Divider(height: 1, thickness: 1, indent: 54, color: AppTheme.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  _MenuItem({required this.icon, required this.label, required this.onTap, this.color});
}