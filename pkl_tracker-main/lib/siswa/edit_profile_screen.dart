import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Controller Form
  late TextEditingController _namaCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _nisCtrl;
  late TextEditingController _jurusanCtrl;
  late TextEditingController _sekolahCtrl;
  late TextEditingController _alamatCtrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Mengambil snapshot data user saat ini
    final user = ref.read(authProvider).valueOrNull;

    _namaCtrl = TextEditingController(text: user?.nama ?? "");
    _emailCtrl = TextEditingController(text: user?.email ?? "");
    _nisCtrl = TextEditingController(text: user?.noInduk ?? "");
    _jurusanCtrl = TextEditingController(text: user?.jurusan ?? "");
    _sekolahCtrl = TextEditingController(text: user?.sekolah ?? "");
    _alamatCtrl = TextEditingController(text: user?.alamat ?? "");

    // Inisialisasi file gambar jika path-nya berupa lokal path yang valid
    if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      if (!user.photoUrl!.startsWith('http')) {
        final file = File(user.photoUrl!);
        if (file.existsSync()) {
          _imageFile = file;
        }
      }
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _nisCtrl.dispose();
    _jurusanCtrl.dispose();
    _sekolahCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Kompresi gambar agar hemat memori/storage
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil foto: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _simpanPerubahan() async {
    if (_namaCtrl.text.trim().isEmpty) {
      _showSnackBar("Nama tidak boleh kosong", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(authProvider).valueOrNull;
      
      if (currentUser != null) {
        // Buat objek baru dengan data dari inputan form
        final updatedUser = currentUser.copyWith(
          nama: _namaCtrl.text.trim(),
          noInduk: _nisCtrl.text.trim(),
          jurusan: _jurusanCtrl.text.trim(),
          sekolah: _sekolahCtrl.text.trim(),
          alamat: _alamatCtrl.text.trim(),
          photoUrl: _imageFile?.path ?? currentUser.photoUrl,
        );

        // Panggil fungsi update di AuthProvider
        await ref.read(authProvider.notifier).updateUserProfile(updatedUser);

        if (mounted) {
          _showSnackBar('Profile berhasil diperbarui! ✅');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    } catch (e) {
      _showSnackBar('Gagal memperbarui profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;

    // Menentukan penampung gambar (Local file, Network URL, atau Icon default)
    ImageProvider? imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      if (user.photoUrl!.startsWith('http')) {
        imageProvider = NetworkImage(user.photoUrl!);
      } else {
        imageProvider = FileImage(File(user.photoUrl!));
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // --- FOTO PROFIL SECTION ---
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 4),
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: imageProvider,
                        child: imageProvider == null
                            ? const Icon(Icons.person, size: 55, color: AppTheme.primary)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
  
              // --- INPUT FIELDS ---
              _buildInputField("Nama Lengkap", _namaCtrl, Icons.person_outline),
              _buildInputField("Email", _emailCtrl, Icons.email_outlined, enabled: false),
              _buildInputField(
                user?.role == 'siswa' ? "NIS" : "NIP / Nomor Induk", 
                _nisCtrl, 
                Icons.badge_outlined, 
                isNumber: true
              ),
              _buildInputField("Jurusan", _jurusanCtrl, Icons.account_tree_outlined),
              _buildInputField("Sekolah", _sekolahCtrl, Icons.school_outlined),
              _buildInputField("Alamat Lengkap", _alamatCtrl, Icons.location_on_outlined, maxLines: 3),
  
              const SizedBox(height: 24),
  
              // --- ACTION BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _simpanPerubahan,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Simpan Perubahan",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label, 
    TextEditingController controller, 
    IconData icon, 
    {bool isNumber = false, int maxLines = 1, bool enabled = true}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: TextStyle(color: enabled ? Colors.black87 : Colors.grey.shade600, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: enabled ? AppTheme.primary : Colors.grey),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}