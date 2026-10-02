import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../models/activity_model.dart';

// Import file profil siswa
import '../siswa/profile_siswa_screen.dart'; 

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // 1. Mengambil data user yang sedang login
    final user = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- HEADER SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Halo!", 
                      style: TextStyle(fontSize: 14, color: Colors.grey)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? "User", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)
                    ),
                  ],
                ),
                // 2. PERBAIKAN: Menggunakan GestureDetector agar klik navigasi pasti berjalan
                GestureDetector(
                  onTap: () {
                    // Navigasi menuju ProfilSiswaScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilSiswaScreen()),
                    );
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    // 3. PERBAIKAN: Pengecekan ekstra agar NetworkImage tidak memproses String kosong ('')
                    backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) 
                        ? NetworkImage(user.photoUrl!) 
                        : null,
                    // Jika URL null atau kosong, tampilkan ikon default
                    child: (user?.photoUrl == null || user!.photoUrl!.isEmpty) 
                        ? const Icon(Icons.person, color: Colors.grey) 
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- PROGRAM CARD SECTION ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2E3192), 
                borderRadius: BorderRadius.circular(16)
              ),
              child: const Text(
                "PKL Tracker System\nMonitoring Logbook", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.4)
              ),
            ),
            const SizedBox(height: 30),

            // --- ACTIVITY LIST HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Aktivitas Saya", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF2E3192), size: 28),
                  onPressed: () {
                    if (user != null) {
                          _showAddDialog(user.uid);
                        }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // --- ACTIVITY LIST CONTENT ---
            if (user == null)
              const Center(
                child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text("Belum ada data", style: TextStyle(color: Colors.grey))),
              )
            else
              FutureBuilder<List<ActivityModel>>(
                future: DatabaseService.getUserActivities(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.only(top: 20), child: CircularProgressIndicator()));
                  }
                  final acts = snapshot.data ?? [];
                  if (acts.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text("Belum ada data", style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  return Column(
                    children: acts.map((act) => Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(act.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text("${act.date.day}/${act.date.month}/${act.date.year}"),
                        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                      ),
                    )).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // --- ADD LOGBOOK DIALOG ---
  void _showAddDialog(String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Tambah Logbook"),
        content: TextField(
          controller: controller, 
          decoration: const InputDecoration(
            hintText: "Kegiatan hari ini",
            border: OutlineInputBorder(),
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Batal", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E3192),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await DatabaseService.addActivity(ActivityModel(
                  id: const Uuid().v4(),
                  userId: userId,
                  title: controller.text,
                  date: DateTime.now(),
                ));
                setState(() {});
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }
}