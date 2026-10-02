import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:apk_pkl_tracker/providers/auth_provider.dart';
import 'package:apk_pkl_tracker/services/database_service.dart';
import 'package:apk_pkl_tracker/models/attendance_model.dart';
import 'package:apk_pkl_tracker/utils/app_theme.dart';

class RiwayatPresensiScreen extends ConsumerStatefulWidget {
  final String? userId;
  final String? userName;

  const RiwayatPresensiScreen({super.key, this.userId, this.userName});

  @override
  ConsumerState<RiwayatPresensiScreen> createState() =>
      _RiwayatPresensiScreenState();
}

class _RiwayatPresensiScreenState
    extends ConsumerState<RiwayatPresensiScreen> {
  List<AttendanceModel> _list = [];
  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final currentUid = ref.read(authProvider).valueOrNull?.uid;
    final targetUid = widget.userId ?? currentUid;
    if (targetUid == null) return;

    final list = await DatabaseService.getUserAttendance(targetUid);
    final stats = await DatabaseService.getAttendanceStats(targetUid);

    if (mounted) {
      setState(() {
        _list = list;
        _stats = stats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(widget.userName != null ? 'Riwayat Presensi ${widget.userName}' : 'Riwayat Presensi'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats Row
                  Row(
                    children: [
                      _StatCard(
                          label: 'Total',
                          value: '${_stats['total'] ?? 0}',
                          sub: 'Hari',
                          color: AppTheme.primary),
                      const SizedBox(width: 10),
                      _StatCard(
                          label: 'Hadir',
                          value: '${_stats['hadir'] ?? 0}',
                          sub: 'Hari',
                          color: AppTheme.success),
                      const SizedBox(width: 10),
                      _StatCard(
                          label: 'Terlambat',
                          value: '${_stats['terlambat'] ?? 0}',
                          sub: 'Hari',
                          color: AppTheme.warning),
                      const SizedBox(width: 10),
                      _StatCard(
                          label: 'Izin',
                          value: '${_stats['izin'] ?? 0}',
                          sub: 'Hari',
                          color: AppTheme.danger),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_list.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            Icon(Icons.event_busy,
                                size: 52, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Belum ada riwayat presensi',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._list.map((att) => _AttendanceCard(att: att)).toList(),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(sub,
                style: TextStyle(
                    fontSize: 9, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceModel att;
  const _AttendanceCard({required this.att});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel = att.status.toLowerCase();
    
    switch (statusLabel) {
      case 'hadir':
        statusColor = AppTheme.success;
        break;
      case 'terlambat':
        statusColor = AppTheme.warning;
        break;
      case 'izin':
        statusColor = AppTheme.danger; // Merah untuk izin
        break;
      default:
        statusColor = Colors.grey; // Abu-abu untuk belum absen/alpha
    }

    String dateLabel = att.tanggal;
    try {
      final parsed = DateTime.parse(att.tanggal);
      dateLabel = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsed);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER CARD: Tanggal & Badge Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.textPrimary),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  att.status[0].toUpperCase() + att.status.substring(1),
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // ISI CARD: Berubah tergantung statusnya
          if (statusLabel == 'izin') ...[
            // TAMPILAN JIKA IZIN
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppTheme.danger),
                      const SizedBox(width: 8),
                      // Catatan: Pastikan field alasanIzin sudah ada di AttendanceModel milikmu
                      Text(
                        'Alasan: ${att.alasanIzin ?? "Tidak diketahui"}', 
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Keterangan: ${att.keteranganTambahan ?? "-"}',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  
                  // Tombol Cek Evident Foto
                  OutlinedButton.icon(
                    onPressed: att.buktiFotoPath != null
                        ? () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text('Bukti Izin', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                    ),
                                    if (att.buktiFotoPath != null)
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Image.file(File(att.buktiFotoPath!), fit: BoxFit.contain),
                                      ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Tutup'),
                                    )
                                  ],
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: Icon(Icons.image, size: 14, color: AppTheme.primary),
                    label: Text('Lihat Bukti Surat', style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 30),
                      side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                    ),
                  )
                ],
              ),
            ),
          ] else if (statusLabel == 'hadir' || statusLabel == 'terlambat') ...[
            // TAMPILAN JIKA HADIR / TERLAMBAT (Tetap menggunakan UI aslimu)
            Row(
              children: [
                Expanded(
                  child: _TimeInfo(
                    label: 'Check-in',
                    time: att.checkIn != null ? '${att.checkIn} WIB' : '-',
                    color: AppTheme.success,
                  ),
                ),
                Container(
                    width: 1,
                    height: 36,
                    color: AppTheme.border),
                Expanded(
                  child: _TimeInfo(
                    label: 'Check-out',
                    time: att.checkOut != null ? '${att.checkOut} WIB' : '-',
                    color: att.checkOut != null
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                Icon(Icons.map_outlined, color: AppTheme.primary, size: 20),
              ],
            ),
          ] else ...[
            // TAMPILAN JIKA BELUM ABSEN / ALPHA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Belum ada data presensi/lokasi untuk hari ini.',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
              ),
            )
          ]
        ],
      ),
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final String label;
  final String time;
  final Color color;

  const _TimeInfo(
      {required this.label, required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(time,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 13)),
          Text('Di lokasi kantor',
              style: TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}