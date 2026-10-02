// lib/models/presensi_model.dart

class PresensiModel {
  final String id;
  final String studentUid;
  final DateTime tanggal;
  final String? jamMasuk;
  final String? jamPulang;
  final String status; // 'hadir', 'belum_absen', 'izin'
  final String? alasanIzin;
  final String? keteranganTambahan;
  final String? buktiFotoPath;

  PresensiModel({
    required this.id,
    required this.studentUid,
    required this.tanggal,
    this.jamMasuk,
    this.jamPulang,
    required this.status,
    this.alasanIzin,
    this.keteranganTambahan,
    this.buktiFotoPath,
  });
}

// DUMMY DATA UNTUK TESTING UI (Nanti diganti dengan data dari database/API)
final List<PresensiModel> dummyRiwayatPresensi = [
  PresensiModel(
    id: '1',
    studentUid: 'siswa_123',
    tanggal: DateTime.now(),
    jamMasuk: '07:30',
    jamPulang: '16:00',
    status: 'hadir',
  ),
  PresensiModel(
    id: '2',
    studentUid: 'siswa_123',
    tanggal: DateTime.now().subtract(const Duration(days: 1)),
    status: 'belum_absen',
  ),
  PresensiModel(
    id: '3',
    studentUid: 'siswa_123',
    tanggal: DateTime.now().subtract(const Duration(days: 2)),
    status: 'izin',
    alasanIzin: 'Sakit',
    keteranganTambahan: 'Demam tinggi, surat dokter terlampir.',
    buktiFotoPath: 'assets/surat_dokter.jpg',
  ),
];