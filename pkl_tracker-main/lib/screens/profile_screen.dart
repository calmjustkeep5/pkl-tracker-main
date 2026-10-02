import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../role_selection_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Saya"), elevation: 0, backgroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 50, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
            const SizedBox(height: 16),
            const Text("Gibran Rakabuming", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Siswa SMK Negeri 10 Semarang", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const RoleSelectionScreen()), (route) => false);
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("Keluar (Logout)", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}