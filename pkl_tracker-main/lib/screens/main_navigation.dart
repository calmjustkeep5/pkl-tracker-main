import 'package:flutter/material.dart';
import '../siswa/presensi_screen.dart';
import 'profile_screen.dart'; // Halaman awal profil

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 3; // Default ke tab Profile untuk ngetes

  final List<Widget> _screens = [
    const Scaffold(body: Center(child: Text("Beranda"))),
    const PresensiScreen(),
    const Scaffold(body: Center(child: Text("Logbook"))),
    const ProfileScreen(), // Halaman utama profil siswa
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Presensi"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Logbook"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}