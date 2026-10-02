// lib/screens/siswa/form_izin_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class FormIzinScreen extends ConsumerStatefulWidget {
  const FormIzinScreen({super.key});

  @override
  ConsumerState<FormIzinScreen> createState() => _FormIzinScreenState();
}

class _FormIzinScreenState extends ConsumerState<FormIzinScreen> {
  String _alasanTerpilih = 'Sakit';
  final _keteranganController = TextEditingController();
  XFile? _pickedFile;
  bool _sending = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _pickedFile = image);
    }
  }

  Future<void> _kirimIzin() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;

    if (_keteranganController.text.isEmpty || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keterangan dan bukti foto wajib diisi!'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _sending = true);
    final success = await DatabaseService.submitIzin(
      userId: user.uid,
      alasanIzin: _alasanTerpilih,
      keterangan: _keteranganController.text.trim(),
      buktiFotoPath: _pickedFile!.path,
    );
    setState(() => _sending = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin berhasil dikirim ke Guru!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim izin. Coba lagi.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pengajuan Izin', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Alasan Tidak Masuk:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _alasanTerpilih,
                  isExpanded: true,
                  items: ['Sakit', 'Alasan Keluarga', 'Kebutuhan Mendesak'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (val) => setState(() => _alasanTerpilih = val!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Keterangan Detail:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _keteranganController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tuliskan alasan secara lengkap di sini...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Upload Evident (Surat Dokter/Bukti):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _pickedFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_pickedFile!.path),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Ketuk untuk memilih bukti foto', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _sending ? null : _kirimIzin,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _sending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Kirim Izin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}