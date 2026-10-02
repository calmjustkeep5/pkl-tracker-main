import 'dart:io';
import 'package:flutter/material.dart';

enum UserRole { siswa, guru }

class DetailLogbookScreen extends StatelessWidget {
  final UserRole role;
  
  // Data Logbook
  final String tanggal;
  final String kegiatan;
  final List<String> fotoBuktiPaths; 
  
  // Data Ekstra khusus Guru
  final String? namaSiswa;
  final String? fotoSiswaPath;

  const DetailLogbookScreen({
    super.key,
    required this.role,
    required this.tanggal,
    required this.kegiatan,
    required this.fotoBuktiPaths,
    this.namaSiswa,
    this.fotoSiswaPath,
  });

  // Fungsi cerdas untuk mengecek apakah gambar dari URL atau File lokal
  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
  }

  // Fungsi cerdas untuk avatar siswa
  ImageProvider? _buildAvatarProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5828FF); 

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Logbook',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: PROFIL SISWA (HANYA MUNCUL DI AKUN GURU) ---
            if (role == UserRole.guru) ...[
              const Text(
                'Siswa',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primaryColor.withValues(alpha: 0.1),
                    backgroundImage: _buildAvatarProvider(fotoSiswaPath),
                    child: (fotoSiswaPath == null || fotoSiswaPath!.isEmpty)
                        ? const Icon(Icons.person, color: primaryColor)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    namaSiswa ?? 'Nama Siswa Tidak Diketahui',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // --- SECTION 2: TANGGAL ---
            const Text(
              'Tanggal',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              tanggal,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),

            // --- SECTION 3: KEGIATAN ---
            const Text(
              'Kegiatan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              kegiatan,
              style: const TextStyle(fontSize: 16, height: 1.4, color: Colors.black87),
            ),
            const SizedBox(height: 24),

            // --- SECTION 4: FOTO BUKTI ---
            const Text(
              'Foto Bukti',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (fotoBuktiPaths.isEmpty)
              const Text('Tidak ada foto bukti yang dilampirkan.', style: TextStyle(color: Colors.grey))
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: fotoBuktiPaths.map((path) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _buildImage(path), // Menggunakan fungsi cerdas
                    ),
                  );
                }).toList(),
              ),
            
            const SizedBox(height: 50),

            // --- SECTION 5: TOMBOL AKSI BERDASARKAN ROLE ---
            if (role == UserRole.siswa) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context), 
                  child: const Text(
                    'KEMBALI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ] else if (role == UserRole.guru) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // TODO: API Setuju
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logbook Disetujui')),
                    );
                  },
                  child: const Text(
                    'SETUJUI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // TODO: API Tolak
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logbook Ditolak')),
                    );
                  },
                  child: const Text(
                    'TOLAK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24), 
          ],
        ),
      ),
    );
  }
}