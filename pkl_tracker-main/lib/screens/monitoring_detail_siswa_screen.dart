// lib/screens/monitoring_detail_siswa_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../services/database_service.dart';
import 'package:apk_pkl_tracker/siswa/riwayat_presensi_screen.dart';

class MonitoringDetailSiswaScreen extends StatelessWidget {
  final String namaSiswa;
  final String nisSiswa;
  final String siswaUid;

  const MonitoringDetailSiswaScreen({
    super.key,
    required this.namaSiswa,
    required this.nisSiswa,
    required this.siswaUid,
  });

  Future<void> _cetakPresensiPDF(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final UserModel? siswa = await DatabaseService.getUserById(siswaUid);
      final List<AttendanceModel> daftarPresensi = await DatabaseService.getUserAttendance(siswaUid);

      final profileRows = <List<String>>[
        ['Nama', siswa?.nama ?? namaSiswa],
        ['NISN', siswa?.noInduk ?? nisSiswa],
        ['Program Keahlian', siswa?.sekolah?.isNotEmpty == true ? siswa!.sekolah! : 'Perangkat Lunak dan Gim'],
        ['Konsentrasi Keahlian', siswa?.jurusan?.isNotEmpty == true ? siswa!.jurusan! : 'Rekayasa Perangkat Lunak'],
        ['Tempat PKL', siswa?.sekolah?.isNotEmpty == true ? siswa!.sekolah! : 'Belum diisi'],
        ['Alamat', siswa?.alamat?.isNotEmpty == true ? siswa!.alamat! : '-'],
      ];

      final tableRows = daftarPresensi.isNotEmpty
          ? daftarPresensi.asMap().entries.map((entry) {
              final att = entry.value;
              final tanggal = _formatTanggal(att.tanggal);
              final masuk = att.checkIn ?? '-';
              final pulang = att.checkOut ?? '-';
              final keterangan = att.status == 'izin'
                  ? (att.alasanIzin ?? 'Izin')
                  : (att.status == 'terlambat' ? 'Terlambat' : '-');

              return [
                '${entry.key + 1}',
                tanggal,
                masuk,
                pulang,
                keterangan,
              ];
            }).toList()
          : [
              ['-', 'Tidak ada data', '-', '-', '-'],
            ];

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('DAFTAAR HADIR PELAJAR', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text('Praktik Kerja Lapangan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 18),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(5),
                    },
                    children: profileRows.map((row) {
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6),
                            child: pw.Text(row[0], style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6),
                            child: pw.Text(row[1], style: const pw.TextStyle(fontSize: 10)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('DAFTAR HADIR', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                  headerHeight: 24,
                  cellAlignment: pw.Alignment.centerLeft,
                  headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  headers: ['No', 'Hari/Tanggal', 'Masuk', 'Pulang', 'Keterangan'],
                  data: tableRows,
                  cellAlignments: {
                    0: pw.Alignment.center,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.center,
                    3: pw.Alignment.center,
                    4: pw.Alignment.centerLeft,
                  },
                ),
              ],
            ),
          ],
        ),
      );

      Navigator.pop(context);
      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
        name: 'Rekap_${siswa?.nama ?? namaSiswa}.pdf',
      );
    } catch (e) {
      Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String _formatTanggal(String tanggal) {
    try {
      final parsed = DateTime.parse(tanggal);
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      return tanggal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monitoring: $namaSiswa'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      // MENGGUNAKAN KEMBALI UI RIWAYAT PRESENSI SISWA
      body: RiwayatPresensiScreen(
        userId: siswaUid,
        userName: namaSiswa,
      ),
      
      // TOMBOL CETAK DI POJOK KANAN BAWAH
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _cetakPresensiPDF(context),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.print, color: Colors.white),
        label: const Text('Cetak Presensi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}