import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../models/attendance_model.dart';
import '../../utils/app_theme.dart';
import 'monitoring_detail_siswa_screen.dart';
import 'tambah_info_siswa_screen.dart';


class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  List<UserModel> _siswaList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isNewStudent(UserModel siswa) {
    final age = DateTime.now().difference(siswa.createdAt).inHours;
    return age >= 0 && age < 48;
  }

  Future<void> _load() async {
    await DatabaseService.syncUsersFromServer();
    final currentUser = ref.read(authProvider).valueOrNull;
    final list = await DatabaseService.getAllSiswa(guruUid: currentUser?.uid);
    list.sort((a, b) {
      final aNew = _isNewStudent(a);
      final bNew = _isNewStudent(b);
      if (aNew != bNew) return aNew ? -1 : 1;
      return a.nama.compareTo(b.nama);
    });
    if (mounted) setState(() {
      _siswaList = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Monitoring Siswa'),
        leading: const SizedBox.shrink(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _siswaList.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 52, color: AppTheme.textSecondary),
                          SizedBox(height: 12),
                          Text('Belum ada siswa terdaftar',
                              style:
                                  TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _siswaList.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _SiswaMonitorCard(siswa: _siswaList[i]),
                    ),
            ),
    );
  }
}

class _SiswaMonitorCard extends StatefulWidget {
  final UserModel siswa;
  const _SiswaMonitorCard({required this.siswa});

  @override
  State<_SiswaMonitorCard> createState() => _SiswaMonitorCardState();
}

class _SiswaMonitorCardState extends State<_SiswaMonitorCard> {
  AttendanceModel? _todayAtt;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final att = await DatabaseService.getTodayAttendance(widget.siswa.uid);
    final stats = await DatabaseService.getAttendanceStats(widget.siswa.uid);
    if (mounted) setState(() {
      _todayAtt = att;
      _stats = stats;
    });
  }

  bool _isNewStudent(UserModel siswa) {
    final age = DateTime.now().difference(siswa.createdAt).inHours;
    return age >= 0 && age < 48;
  }

  @override
  Widget build(BuildContext context) {
    final hadir = _todayAtt != null;
    final statsWidgets = <Widget>[
      _MiniStat(
          label: 'Total',
          value: '${_stats['total'] ?? 0}',
          color: AppTheme.primary),
      _MiniStat(
          label: 'Hadir',
          value: '${_stats['hadir'] ?? 0}',
          color: AppTheme.success),
      _MiniStat(
          label: 'Terlambat',
          value: '${_stats['terlambat'] ?? 0}',
          color: AppTheme.warning),
    ];
    if (_todayAtt != null) {
      statsWidgets.add(
        _MiniStat(
          label: 'Check-in',
          value: _todayAtt!.checkIn ?? '-',
          color: AppTheme.textSecondary,
        ),
      );
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MonitoringDetailSiswaScreen(
              namaSiswa: widget.siswa.nama,
              nisSiswa: widget.siswa.noInduk ?? widget.siswa.email,
              siswaUid: widget.siswa.uid,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primary.withAlpha((0.1 * 255).round()),
                child: Text(
                  widget.siswa.nama.isNotEmpty
                      ? widget.siswa.nama[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.siswa.nama,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.textPrimary)),
                        if (_isNewStudent(widget.siswa)) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('BARU',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                        if (widget.siswa.pklPlaceName != null && widget.siswa.pklPlaceName!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('TERKIRIM',
                                style: TextStyle(
                                    color: AppTheme.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      widget.siswa.noInduk != null
                          ? 'NIS: ${widget.siswa.noInduk}'
                          : widget.siswa.email,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hadir
                      ? AppTheme.success.withAlpha((0.12 * 255).round())
                      : AppTheme.danger.withAlpha((0.12 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hadir ? 'Hadir' : 'Belum',
                  style: TextStyle(
                      color: hadir ? AppTheme.success : AppTheme.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: statsWidgets,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TambahInfoSiswaScreen(siswa: widget.siswa),
                      ),
                    );
                    if (result == true && mounted) {
                      _load();
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tambah Info', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
      ],
    );
  }
}