import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/logbook_model.dart';
import '../../utils/app_theme.dart';

class TambahLogbookScreen extends ConsumerStatefulWidget {
  const TambahLogbookScreen({super.key});

  @override
  ConsumerState<TambahLogbookScreen> createState() =>
      _TambahLogbookScreenState();
}

class _TambahLogbookScreenState extends ConsumerState<TambahLogbookScreen> {
  final _kegiatanCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final List<File> _images = [];
  bool _isSaving = false;
  final _picker = ImagePicker();
  double? _locationLat;
  double? _locationLng;
  String? _locationAddress;

  @override
  void dispose() {
    _kegiatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (picked != null && mounted) {
        setState(() => _images.add(File(picked.path)));
      }
    } catch (e) {
      _showSnack('Gagal mengambil gambar: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tambah Foto',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primary),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppTheme.primary,
                ),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    // 🛡️ PENGAMAN MUTLAK: Hentikan langsung di baris pertama jika sedang proses simpan
    if (_isSaving) return;

    if (_kegiatanCtrl.text.trim().isEmpty) {
      _showSnack('Isi deskripsi kegiatan terlebih dahulu!');
      return;
    }

    // Ubah state jadi true SEBELUM ada jeda async apapun
    setState(() => _isSaving = true);

    // Ambil data user dari AuthProvider
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) {
      if (mounted) setState(() => _isSaving = false);
      _showSnack('Sesi tidak valid, silakan login ulang.');
      return;
    }

    final tanggal = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final fotoPaths = _images.isNotEmpty
        ? _images.map((f) => f.path).join(',')
        : null;

    // Ambil posisi GPS terbaru
    await _fetchLocation();

    final logbook = LogbookModel(
      uid: const Uuid().v4(),
      userId: user.uid,
      tanggal: tanggal,
      kegiatan: _kegiatanCtrl.text.trim(),
      fotoBukti: fotoPaths,
      locationLat: _locationLat,
      locationLng: _locationLng,
      locationAddress: _locationAddress,
      createdAt: DateTime.now(),
    );

    // Panggil DatabaseService.addLogbook yang sudah menangani simpan SQLite + Multipart upload
    final successLocal = await DatabaseService.addLogbook(
      logbook,
      images: _images,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (successLocal) {
      _showSnack('Logbook berhasil disimpan ✅', isSuccess: true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context, true);
    } else {
      _showSnack('Gagal menyimpan logbook, coba lagi nanti.');
    }
  }

  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _locationLat = position.latitude;
      _locationLng = position.longitude;
      await _resolveAddress(_locationLat!, _locationLng!);
    } catch (_) {
      _locationLat = null;
      _locationLng = null;
      _locationAddress = null;
    }
  }

  Future<void> _resolveAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _locationAddress = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((part) => part != null && part.isNotEmpty).join(', ');
      }
    } catch (_) {
      _locationAddress = null;
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving, // Mencegah tombol back ditekan saat proses simpan
      child: Scaffold(
        backgroundColor: AppTheme.bgLight,
        appBar: AppBar(
          title: const Text('Tambah Logbook'),
          automaticallyImplyLeading: !_isSaving,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tanggal
              _sectionLabel('Tanggal'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _isSaving
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat(
                          'd MMMM yyyy',
                          'id_ID',
                        ).format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Kegiatan
              _sectionLabel('Kegiatan'),
              const SizedBox(height: 8),
              TextField(
                controller: _kegiatanCtrl,
                enabled: !_isSaving,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Deskripsikan kegiatan PKL hari ini...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Foto Bukti
              _sectionLabel('Foto Bukti'),
              const SizedBox(height: 4),
              const Text(
                'Dapat memilih lebih dari 1 foto (Kamera/Galeri)',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),

              // Image Grid
              if (_images.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _images[i],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (!_isSaving)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _images.removeAt(i)),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: AppTheme.danger,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Add Photo Button
              GestureDetector(
                onTap: _isSaving ? null : _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: _images.isNotEmpty ? 80 : 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tambah Foto',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Simpan Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('SIMPAN'),
                ),
              ),
              const SizedBox(height: 12),

              // Kembali Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'KEMBALI',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
