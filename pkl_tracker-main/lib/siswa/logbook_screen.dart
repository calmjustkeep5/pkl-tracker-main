import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:apk_pkl_tracker/utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/logbook_model.dart';
import 'tambah_logbook_screen.dart';

// Import file detail logbook
import 'package:apk_pkl_tracker/screens/logbook/detail_logbook_screen.dart'; 

class LogbookScreen extends ConsumerStatefulWidget {
  const LogbookScreen({super.key});

  @override
  ConsumerState<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends ConsumerState<LogbookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LogbookModel> _allLogbooks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLogbooks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLogbooks() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;
    await DatabaseService.syncLogbooksFromServer(userId: user.uid);
    final list = await DatabaseService.getUserLogbooks(user.uid);
    if (mounted) {
      setState(() {
        _allLogbooks = list;
        _loading = false;
      });
    }
  }

  List<LogbookModel> _filtered(String status) {
    if (status == 'semua') return _allLogbooks;
    return _allLogbooks.where((l) => l.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Logbook'),
        leading: const SizedBox.shrink(),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 12),
          tabs: const [
            Tab(text: 'Menunggu'),
            Tab(text: 'Disetujui'),
            Tab(text: 'Ditolak'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLogbooks,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LogbookList(items: _filtered('menunggu'), onRefresh: _loadLogbooks),
                  _LogbookList(items: _filtered('disetujui'), onRefresh: _loadLogbooks),
                  _LogbookList(items: _filtered('ditolak'), onRefresh: _loadLogbooks),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahLogbookScreen()),
          );
          _loadLogbooks();
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _LogbookList extends StatelessWidget {
  final List<LogbookModel> items;
  final VoidCallback onRefresh;

  const _LogbookList({required this.items, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 52, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text('Belum ada logbook',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _LogbookCard(logbook: items[i]),
    );
  }
}

class _LogbookCard extends StatelessWidget {
  final LogbookModel logbook;
  const _LogbookCard({required this.logbook});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMMM yyyy', 'id_ID')
        .format(DateTime.parse(logbook.tanggal));

    return InkWell(
      onTap: () {
        // Logika memecah string foto langsung di sini
        List<String> daftarFoto = [];
        if (logbook.fotoBukti != null && logbook.fotoBukti!.isNotEmpty) {
          daftarFoto = logbook.fotoBukti!.split(',');
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailLogbookScreen(
              role: UserRole.siswa, 
              tanggal: date,
              kegiatan: logbook.kegiatan,
              fotoBuktiPaths: daftarFoto, 
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.description_outlined,
                  color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    logbook.kegiatan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  if (logbook.catatanGuru != null && logbook.catatanGuru!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Catatan: ${logbook.catatanGuru}',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: logbook.statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                logbook.statusLabel,
                style: TextStyle(
                  color: logbook.statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}