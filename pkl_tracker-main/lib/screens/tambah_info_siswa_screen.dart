import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class TambahInfoSiswaScreen extends StatefulWidget {
  final UserModel siswa;
  const TambahInfoSiswaScreen({super.key, required this.siswa});

  @override
  State<TambahInfoSiswaScreen> createState() => _TambahInfoSiswaScreenState();
}

class _TambahInfoSiswaScreenState extends State<TambahInfoSiswaScreen> {
  late final TextEditingController _placeNameCtrl;
  late final TextEditingController _placeAddressCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _placeNameCtrl = TextEditingController(text: widget.siswa.pklPlaceName ?? '');
    _placeAddressCtrl = TextEditingController(text: widget.siswa.pklPlaceAddress ?? '');
    _latCtrl = TextEditingController(text: widget.siswa.pklLatitude?.toString() ?? '');
    _lngCtrl = TextEditingController(text: widget.siswa.pklLongitude?.toString() ?? '');
  }

  @override
  void dispose() {
    _placeNameCtrl.dispose();
    _placeAddressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveInfo() async {
    final placeName = _placeNameCtrl.text.trim();
    final placeAddress = _placeAddressCtrl.text.trim();
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());

    if (placeName.isEmpty || placeAddress.isEmpty || lat == null || lng == null) {
      _showSnack('Semua bidang harus diisi dan koordinat harus valid.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final updatedStudent = widget.siswa.copyWith(
      pklPlaceName: placeName,
      pklPlaceAddress: placeAddress,
      pklLatitude: lat,
      pklLongitude: lng,
    );

    try {
      final count = await DatabaseService.updateUser(updatedStudent);
      if (count > 0) {
        if (mounted) {
          _showSnack('Info siswa berhasil disimpan.', isError: false);
          Navigator.pop(context, true);
        }
      } else {
        _showSnack('Gagal menyimpan info siswa. Coba lagi.', isError: true);
      }
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
        title: const Text('Tambah Info Siswa'),
        leading: const BackButton(color: AppTheme.textPrimary),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Siswa: ${widget.siswa.nama}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(widget.siswa.noInduk != null ? 'NIS: ${widget.siswa.noInduk}' : widget.siswa.email,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            _buildField('Nama Tempat PKL', _placeNameCtrl, Icons.location_city_outlined),
            const SizedBox(height: 18),
            _buildField('Jalan Tempat PKL', _placeAddressCtrl, Icons.location_on_outlined),
            const SizedBox(height: 18),
            _buildField('Latitude', _latCtrl, Icons.my_location_outlined, isNumber: true),
            const SizedBox(height: 18),
            _buildField('Longitude', _lngCtrl, Icons.my_location_outlined, isNumber: true),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Simpan Informasi', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.bgLight.withAlpha((0.5 * 255).round()),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
