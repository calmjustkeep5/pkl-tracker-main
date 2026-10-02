import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- IMPORT UTILS ---
import 'package:apk_pkl_tracker/utils/app_theme.dart'; 

// --- IMPORT SCREENS ---
import 'package:apk_pkl_tracker/screens/splash_screen.dart'; 
import 'package:apk_pkl_tracker/screens/dashboard_siswa_screen.dart'; 
import 'package:apk_pkl_tracker/siswa/presensi_screen.dart';
import 'package:apk_pkl_tracker/siswa/logbook_screen.dart';
import 'package:apk_pkl_tracker/siswa/profile_siswa_screen.dart'; 

// ✅ TAMBAHAN IMPORT UNTUK HALAMAN RIWAYAT PRESENSI
import 'package:apk_pkl_tracker/siswa/riwayat_presensi_screen.dart'; 

import 'package:apk_pkl_tracker/screens/dashboard_guru_screen.dart';
import 'package:apk_pkl_tracker/screens/validasi_logbook_screen.dart';
import 'package:apk_pkl_tracker/screens/monitoring_screen.dart';
import 'package:apk_pkl_tracker/screens/profile_guru_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi bahasa Indonesia untuk format tanggal dan jam
  await initializeDateFormatting('id', null);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PKL Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        // Menggunakan font/style dari AppTheme jika tersedia
        scaffoldBackgroundColor: const Color(0xFFF9FAFC),
      ),
      // Mendukung lokalisasi untuk komponen Flutter bawaan
      localizationsDelegates: const [
        // ... (tambahkan jika menggunakan library localization tambahan)
      ],
      home: const SplashScreen(), 
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  final String role;
  const MainScreen({super.key, required this.role});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _siswaScreens;
  late List<Widget> _guruScreens;

  @override
  void initState() {
    super.initState();
    
    // ✅ REVISI: Menambahkan RiwayatPresensiScreen ke dalam urutan layar siswa
    _siswaScreens = [
      const DashboardSiswaScreen(),
      const PresensiScreen(),
      const RiwayatPresensiScreen(), // <-- HALAMAN BARU SISWA
      const LogbookScreen(),
      const ProfilSiswaScreen(),
    ];

    _guruScreens = [
      const DashboardGuruScreen(),
      const ValidasiLogbookScreen(),
      const MonitoringScreen(),
      const ProfileGuruScreen(),
    ];
  }

  // ✅ REVISI: Menambahkan Icon dan Label "Riwayat" di Bottom Navigation Bar
  List<BottomNavigationBarItem> get _siswaNavItems => [
    const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
    const BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: 'Presensi'),
    const BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Riwayat'), // <-- MENU BARU
    const BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: 'Logbook'),
    const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
  ];

  List<BottomNavigationBarItem> get _guruNavItems => [
    const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
    const BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Validasi'),
    const BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Monitoring'),
    const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final isSiswa = widget.role == 'siswa';
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: isSiswa ? _siswaScreens : _guruScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: isSiswa ? _siswaNavItems : _guruNavItems,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        // type: BottomNavigationBarType.fixed sangat penting di sini 
        // agar menu tidak hilang saat jumlahnya mencapai 5!
        type: BottomNavigationBarType.fixed, 
        backgroundColor: Colors.white,
        elevation: 10,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
