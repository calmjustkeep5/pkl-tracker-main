import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../siswa/riwayat_presensi_screen.dart';
import 'monitoring_screen.dart';
import 'profile_guru_screen.dart';
import 'validasi_logbook_screen.dart';

class DashboardGuruScreen extends ConsumerStatefulWidget {
  const DashboardGuruScreen({super.key});

  @override
  ConsumerState<DashboardGuruScreen> createState() =>
      _DashboardGuruScreenState();
}

class _DashboardGuruScreenState extends ConsumerState<DashboardGuruScreen> {
  Map<String, int> _stats = {};
  bool _loading = true;
  int _newUpdates = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    await DatabaseService.syncUsersFromServer();
    final currentUser = ref.read(authProvider).valueOrNull;
    final stats = await DatabaseService.getGuruDashboardStats();
    if (currentUser?.uid != null) {
      await DatabaseService.getSiswaByGuru(currentUser!.uid);
    }
    final pending = _stats['belum_validasi'] ?? 0;
    final newCount = (stats['belum_validasi'] ?? 0) > pending
        ? (stats['belum_validasi'] ?? 0) - pending
        : 0;
    if (mounted) {
      setState(() {
        _stats = stats;
        _loading = false;
        _newUpdates = newCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Halo, Guru',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          user?.nama ?? 'Guru',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Selamat datang',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileGuruScreen(),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      backgroundImage:
                          (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                          ? FileImage(File(user.photoUrl!))
                          : null,
                      child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                          ? Text(
                              user?.nama.isNotEmpty == true
                                  ? user!.nama[0].toUpperCase()
                                  : 'G',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats Grid
              if (!_loading) ...[
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Siswa',
                        value: '${_stats['total_siswa'] ?? 0}',
                        color: AppTheme.primary,
                        icon: Icons.people,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Presensi Hari Ini',
                        value: '${_stats['presensi_hari_ini'] ?? 0}',
                        color: AppTheme.success,
                        icon: Icons.location_on,
                        valueColor: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Logbook Masuk',
                        value: '${_stats['logbook_masuk'] ?? 0}',
                        color: AppTheme.warning,
                        icon: Icons.book,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Belum Validasi',
                        value: '${_stats['belum_validasi'] ?? 0}',
                        color: AppTheme.danger,
                        icon: Icons.pending_actions,
                        valueColor: AppTheme.danger,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              if (_newUpdates > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ada $_newUpdates update baru dari siswa',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Text(
                'Menu',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Menu Items
              _GuruMenuItem(
                title: 'Validasi Logbook',
                subtitle: 'Setujui atau tolak laporan siswa',
                icon: Icons.check_circle_outline,
                color: AppTheme.primary,
                badge:
                    _stats['belum_validasi'] != null &&
                        (_stats['belum_validasi']! > 0)
                    ? '${_stats['belum_validasi']}'
                    : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ValidasiLogbookScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _GuruMenuItem(
                title: 'Monitoring Siswa',
                subtitle: 'Pantau presensi & aktivitas siswa',
                icon: Icons.monitor_heart_outlined,
                color: AppTheme.success,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonitoringScreen()),
                ),
              ),
              const SizedBox(height: 10),
              _GuruMenuItem(
                title: 'Rekap Presensi',
                subtitle: 'Laporan kehadiran semua siswa',
                icon: Icons.summarize_outlined,
                color: AppTheme.warning,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RiwayatPresensiScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _GuruMenuItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _GuruMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
