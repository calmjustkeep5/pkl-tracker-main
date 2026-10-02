import 'dart:io'; // Tambahan wajib untuk membaca file foto lokal
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../siswa/presensi_screen.dart';
import '../siswa/riwayat_presensi_screen.dart';
import '../siswa/logbook_screen.dart';
import '../siswa/profile_siswa_screen.dart';
import '../siswa/tambah_logbook_screen.dart';

class DashboardSiswaScreen extends ConsumerStatefulWidget {
  const DashboardSiswaScreen({super.key});

  @override
  ConsumerState<DashboardSiswaScreen> createState() =>
      _DashboardSiswaScreenState();
}

class _DashboardSiswaScreenState extends ConsumerState<DashboardSiswaScreen> {
  Map<String, int> _attendanceStats = {};
  Map<String, int> _logbookStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;
    final aStats = await DatabaseService.getAttendanceStats(user.uid);
    final lStats = await DatabaseService.getLogbookStats(user.uid);
    if (mounted) {
      setState(() {
        _attendanceStats = aStats;
        _logbookStats = lStats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch akan memastikan widget ini me-render ulang otomatis
    // setiap kali ada perubahan pada authProvider (misal habis ganti foto/profil)
    final user = ref.watch(authProvider).valueOrNull;
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header greeting
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user?.nama.split(' ').first ?? 'Siswa'} 👋',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
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
                        MaterialPageRoute(builder: (_) => const ProfilSiswaScreen()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                          ? FileImage(File(user.photoUrl!))
                          : null,
                      child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                          ? Text(
                              (user?.nama.isNotEmpty == true)
                                  ? user!.nama[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // PKL Program Card
              _ProgramCard(user: user),
              const SizedBox(height: 20),

              // Stats Row
              if (!_loading)
                Row(
                  children: [
                    Expanded(
                      child: _StatMiniCard(
                        label: 'Presensi',
                        value: '${_attendanceStats['total'] ?? 0}',
                        sub: 'Hari masuk',
                        color: AppTheme.primary,
                        icon: Icons.location_on,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatMiniCard(
                        label: 'Logbook',
                        value: '${_logbookStats['total'] ?? 0}',
                        sub: 'Total laporan',
                        color: AppTheme.success,
                        icon: Icons.book,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatMiniCard(
                        label: 'Disetujui',
                        value: '${_logbookStats['disetujui'] ?? 0}',
                        sub: 'Logbook OK',
                        color: AppTheme.warning,
                        icon: Icons.check_circle,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // Menu Section
              const Text(
                'Menu',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Menu Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _MenuCard(
                    title: 'Presensi',
                    subtitle: 'Absen masuk & keluar',
                    icon: Icons.location_on,
                    color: AppTheme.primary,
                    onTap: () => _navigateTo(context, const PresensiScreen()),
                  ),
                  _MenuCard(
                    title: 'Logbook',
                    subtitle: 'Catat kegiatan PKL',
                    icon: Icons.book,
                    color: AppTheme.success,
                    onTap: () => _navigateTo(context, const LogbookScreen()),
                  ),
                  _MenuCard(
                    title: 'Upload Bukti',
                    subtitle: 'Foto kegiatan',
                    icon: Icons.camera_alt,
                    color: AppTheme.warning,
                    onTap: () => _navigateTo(context, const TambahLogbookScreen()),
                  ),
                  _MenuCard(
                    title: 'Riwayat',
                    subtitle: 'Lihat semua data',
                    icon: Icons.history,
                    color: const Color(0xFF8B5CF6),
                    onTap: () => _navigateTo(context, const RiwayatPresensiScreen()),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Status Hari Ini
              _StatusHariIni(),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _ProgramCard extends StatelessWidget {
  final dynamic user;
  const _ProgramCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B4BF5), Color(0xFF1E3BD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Program PKL',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.sekolah ?? 'SMK Negeri 10 Semarang',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // --- REVISI BAGIAN JURUSAN DI SINI ---
                Text(
                  user?.jurusan ?? 'Jurusan belum diisi', // Mengambil data jurusan dari model User
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIS: ${user?.noInduk ?? '-'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kelola dari pantauan aktivitas PKL mu dengan mudah',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 10, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusHariIni extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StatusHariIni> createState() => _StatusHariIniState();
}

class _StatusHariIniState extends ConsumerState<_StatusHariIni> {
  dynamic _todayAttendance;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;
    final att = await DatabaseService.getTodayAttendance(user.uid);
    if (mounted) setState(() => _todayAttendance = att);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Hari Ini',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (_todayAttendance != null)
                      ? AppTheme.success.withValues(alpha: 0.12)
                      : AppTheme.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _todayAttendance != null
                      ? Icons.check_circle
                      : Icons.access_time,
                  color: _todayAttendance != null
                      ? AppTheme.success
                      : AppTheme.warning,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _todayAttendance != null
                          ? 'Sudah Check-in'
                          : 'Belum Check-in',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _todayAttendance != null
                          ? 'Check-in: ${_todayAttendance.checkIn ?? "-"} WIB'
                          : 'Lakukan presensi sekarang',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}