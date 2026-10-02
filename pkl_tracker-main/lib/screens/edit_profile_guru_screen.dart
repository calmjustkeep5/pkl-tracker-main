import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_theme.dart'; // Pastikan path ini sesuai dengan struktur foldermu
import '../providers/auth_provider.dart';

class EditProfileGuruScreen extends ConsumerStatefulWidget {
  const EditProfileGuruScreen({super.key});

  @override
  ConsumerState<EditProfileGuruScreen> createState() => _EditProfileGuruScreenState();
}

class _EditProfileGuruScreenState extends ConsumerState<EditProfileGuruScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _nipCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _locationNameCtrl;
  late TextEditingController _locationStreetCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(authProvider).valueOrNull;

    _nameCtrl = TextEditingController(text: currentUser?.nama ?? '');
    _nipCtrl = TextEditingController(text: currentUser?.noInduk ?? '');
    _phoneCtrl = TextEditingController(text: currentUser?.phone ?? '');
    _locationNameCtrl = TextEditingController(text: currentUser?.pklPlaceName ?? '');
    _locationStreetCtrl = TextEditingController(text: currentUser?.pklPlaceAddress ?? '');
    _latCtrl = TextEditingController(text: currentUser?.pklLatitude?.toString() ?? '');
    _lngCtrl = TextEditingController(text: currentUser?.pklLongitude?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nipCtrl.dispose();
    _phoneCtrl.dispose();
    _locationNameCtrl.dispose();
    _locationStreetCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    // Validasi form kosong
    if (_nameCtrl.text.isEmpty || _nipCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      _showSnack('Semua kolom wajib diisi!', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. Ambil data user yang sedang login saat ini
      final currentUser = ref.read(authProvider).valueOrNull;
      
      if (currentUser != null) {
        final latitude = _latCtrl.text.isNotEmpty ? double.tryParse(_latCtrl.text.trim()) : null;
        final longitude = _lngCtrl.text.isNotEmpty ? double.tryParse(_lngCtrl.text.trim()) : null;

        if ((_locationNameCtrl.text.isNotEmpty || _locationStreetCtrl.text.isNotEmpty) && (latitude == null || longitude == null)) {
          _showSnack('Koordinat latitude/longitude harus valid jika lokasi PKL diisi.', isError: true);
          return;
        }

        // 2. Buat objek user baru dengan data yang sudah diupdate dari form
        final updatedUser = currentUser.copyWith(
          nama: _nameCtrl.text.trim(),
          noInduk: _nipCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          pklPlaceName: _locationNameCtrl.text.trim().isEmpty ? null : _locationNameCtrl.text.trim(),
          pklPlaceAddress: _locationStreetCtrl.text.trim().isEmpty ? null : _locationStreetCtrl.text.trim(),
          pklLatitude: latitude,
          pklLongitude: longitude,
        );
        // 3. Kirim objek updatedUser secara utuh ke AuthNotifier
        await ref.read(authProvider.notifier).updateProfile(updatedUser);
        if (mounted) {
          _showSnack('Perubahan profil berhasil disimpan', isError: false);
          // Kembali ke halaman sebelumnya (Profil) setelah sukses
          Navigator.pop(context); 
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Gagal memperbarui profil: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fillCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Layanan lokasi tidak aktif', isError: true);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _showSnack('Izin lokasi ditolak', isError: true);
        return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _latCtrl.text = position.latitude.toString();
      _lngCtrl.text = position.longitude.toString();
      _showSnack('Koordinat berhasil diisi dari lokasi saat ini', isError: false);
    } catch (e) {
      _showSnack('Gagal mengisi lokasi: $e', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.danger : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Ubah Profil',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Info singkat
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pastikan data yang dimasukkan sudah benar. Email tidak dapat diubah dari menu ini.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            // Form Input Data
            _buildField(label: 'Nama Lengkap & Gelar', controller: _nameCtrl, icon: Icons.person_outline),
            const SizedBox(height: 18),
            _buildField(label: 'Nomor Induk Pegawai (NIP)', controller: _nipCtrl, icon: Icons.badge_outlined, isNumber: true),
            const SizedBox(height: 18),
            _buildField(label: 'Nomor WhatsApp Aktif', controller: _phoneCtrl, icon: Icons.phone_outlined, isNumber: true),
            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Lokasi PKL Siswa',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 12),
            _buildField(label: 'Nama Tempat PKL', controller: _locationNameCtrl, icon: Icons.location_city_outlined),
            const SizedBox(height: 18),
            _buildField(label: 'Jalan Tempat PKL', controller: _locationStreetCtrl, icon: Icons.location_on_outlined),
            const SizedBox(height: 18),
            _buildField(label: 'Latitude', controller: _latCtrl, icon: Icons.my_location_outlined, isNumber: true),
            const SizedBox(height: 18),
            _buildField(label: 'Longitude', controller: _lngCtrl, icon: Icons.my_location_outlined, isNumber: true),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _fillCurrentLocation,
                icon: const Icon(Icons.gps_fixed, size: 18),
                label: const Text('Isi Koordinat Saat Ini'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 18),
            const SizedBox(height: 22),
            
            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                  elevation: 0
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22, 
                        height: 22, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                      )
                    : const Text(
                        'SIMPAN PERUBAHAN', 
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget Bantuan untuk TextFormField
  Widget _buildField({required String label, required TextEditingController controller, required IconData icon, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 22, color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.bgLight.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide.none
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: BorderSide(color: Colors.grey.shade200)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), 
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)
            ),
          ),
        ),
      ],
    );
  }
}