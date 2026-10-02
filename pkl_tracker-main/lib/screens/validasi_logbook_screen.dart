import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../models/logbook_model.dart';
import '../../models/user_model.dart';

class ValidasiLogbookScreen extends ConsumerStatefulWidget {
  const ValidasiLogbookScreen({super.key});

  @override
  ConsumerState<ValidasiLogbookScreen> createState() =>
      _ValidasiLogbookScreenState();
}

class _ValidasiLogbookScreenState extends ConsumerState<ValidasiLogbookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // REVISI: Ubah tipe data dari Map menjadi LogbookModel
  List<LogbookModel> _allLogbooks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await DatabaseService.syncUsersFromServer();
    await DatabaseService.syncLogbooksFromServer();
    final list = await DatabaseService.getLogbooksForValidation();
    if (mounted) {
      setState(() {
        _allLogbooks = list;
        _loading = false;
      });
    }
  }

  // REVISI: Filter juga menggunakan tipe data LogbookModel
  List<LogbookModel> _filtered(String status) {
    return _allLogbooks.where((l) => l.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Validasi Logbook'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Menunggu'),
                  if (_filtered('menunggu').isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppTheme.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_filtered('menunggu').length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Disetujui'),
            const Tab(text: 'Ditolak'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LogbookValidasiList(
                    items: _filtered('menunggu'),
                    onAction: _load,
                    showActions: true,
                  ),
                  _LogbookValidasiList(
                    items: _filtered('disetujui'),
                    onAction: _load,
                    showActions: false,
                  ),
                  _LogbookValidasiList(
                    items: _filtered('ditolak'),
                    onAction: _load,
                    showActions: false,
                  ),
                ],
              ),
            ),
    );
  }
}

class _LogbookValidasiList extends ConsumerWidget {
  final List<LogbookModel> items; // REVISI: Gunakan LogbookModel
  final VoidCallback onAction;
  final bool showActions;

  const _LogbookValidasiList({
    required this.items,
    required this.onAction,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 52, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text(
              'Tidak ada data',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _LogbookValidasiCard(
        item: items[i],
        showActions: showActions,
        onAction: (status, catatan) async {
          final user = ref.read(authProvider).valueOrNull;
          await DatabaseService.validateLogbook(
            uid: items[i].uid,
            status: status,
            guruId: user?.uid ?? '',
            catatan: catatan ?? '',
          );
          await DatabaseService.syncUsersFromServer();
          onAction();
        },
      ),
    );
  }
}

class _LogbookValidasiCard extends StatelessWidget {
  final LogbookModel item; // REVISI: Gunakan LogbookModel
  final bool showActions;
  final Function(String status, String? catatan) onAction;

  const _LogbookValidasiCard({
    required this.item,
    required this.showActions,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    String dateLabel = item.tanggal;
    try {
      final parsed = DateTime.parse(item.tanggal);
      dateLabel = DateFormat('d MMM yyyy', 'id_ID').format(parsed);
    } catch (_) {}

    final statusColor = item.status == 'disetujui'
        ? AppTheme.success
        : item.status == 'ditolak'
        ? AppTheme.danger
        : AppTheme.warning;

    final String alamatLabel;
    if (item.locationAddress != null && item.locationAddress!.isNotEmpty) {
      alamatLabel = item.locationAddress!;
    } else if (item.locationLat != null && item.locationLng != null) {
      alamatLabel =
          '${item.locationLat!.toStringAsFixed(5)}, ${item.locationLng!.toStringAsFixed(5)}';
    } else {
      alamatLabel = 'Tidak tersedia';
    }

    return InkWell(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<UserModel?>(
              future: DatabaseService.getUserById(item.userId),
              builder: (context, snapshot) {
                final student = snapshot.data;
                final photoUrl = student?.photoUrl;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primary.withValues(alpha: 31),
                      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                          ? FileImage(File(photoUrl))
                          : null,
                      child: (photoUrl == null || photoUrl.isEmpty)
                          ? Text(
                              student?.nama.isNotEmpty == true
                                  ? student!.nama[0].toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student?.nama ?? 'Siswa tidak diketahui',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 31),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Alamat: $alamatLabel',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.kegiatan,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            if (item.fotoBukti != null && item.fotoBukti!.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, index) {
                    final photos = item.fotoBukti!.split(',');
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: photos[index].startsWith('http')
                          ? Image.network(
                              photos[index],
                              width: 100,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            )
                          : Image.file(
                              File(photos[index]),
                              width: 100,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 90,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: item.fotoBukti!.split(',').length,
                ),
              ),
            if (item.catatanGuru != null && item.catatanGuru!.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Catatan Guru:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.catatanGuru!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showValidasiDialog(context, 'ditolak'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppTheme.danger,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(0, 38),
                      ),
                      child: const Text(
                        'TOLAK',
                        style: TextStyle(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _showValidasiDialog(context, 'disetujui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        minimumSize: const Size(0, 38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SETUJUI',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    String dateLabel = item.tanggal;
    try {
      final parsed = DateTime.parse(item.tanggal);
      dateLabel = DateFormat('d MMM yyyy', 'id_ID').format(parsed);
    } catch (_) {}

    final String detailAlamatLabel;
    if (item.locationAddress != null && item.locationAddress!.isNotEmpty) {
      detailAlamatLabel = item.locationAddress!;
    } else if (item.locationLat != null && item.locationLng != null) {
      detailAlamatLabel =
          '${item.locationLat!.toStringAsFixed(5)}, ${item.locationLng!.toStringAsFixed(5)}';
    } else {
      detailAlamatLabel = 'Tidak tersedia';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Text(
                  'Detail Logbook',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                FutureBuilder<UserModel?>(
                  future: DatabaseService.getUserById(item.userId),
                  builder: (context, snapshot) {
                    final student = snapshot.data;
                    final photoUrl = student?.photoUrl;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primary.withValues(alpha: 31),
                        backgroundImage:
                            (photoUrl != null && photoUrl.isNotEmpty)
                            ? FileImage(File(photoUrl))
                            : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? Text(
                                student?.nama.isNotEmpty == true
                                    ? student!.nama[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        student?.nama ?? 'Siswa tidak diketahui',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        student?.noInduk ?? item.userId,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _detailRow('Tanggal', dateLabel),
                _detailRow('Alamat', detailAlamatLabel),
                _detailRow('Status', item.statusLabel),
                const SizedBox(height: 12),
                const Text(
                  'Catatan Logbook',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.kegiatan,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
                if (item.fotoBukti != null && item.fotoBukti!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Foto Bukti',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: item.fotoBukti!.split(',').length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final photos = item.fotoBukti!.split(',');
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: photos[index].startsWith('http')
                              ? Image.network(
                                  photos[index],
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                )
                              : Image.file(
                                  File(photos[index]),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 120,
                                    height: 120,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
                if (item.catatanGuru != null &&
                    item.catatanGuru!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Catatan Guru',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.catatanGuru!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (showActions) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showValidasiDialog(context, 'ditolak');
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppTheme.danger,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(0, 44),
                          ),
                          child: const Text(
                            'TOLAK',
                            style: TextStyle(
                              color: AppTheme.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showValidasiDialog(context, 'disetujui');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'SETUJUI',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showValidasiDialog(BuildContext context, String status) {
    final catatanCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          status == 'disetujui' ? 'Setujui Logbook' : 'Tolak Logbook',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status == 'disetujui'
                  ? 'Apakah Anda yakin ingin menyetujui logbook ini?'
                  : 'Berikan alasan penolakan logbook ini',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catatanCtrl,
              decoration: const InputDecoration(hintText: 'Catatan (opsional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAction(status, catatanCtrl.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'disetujui'
                  ? AppTheme.success
                  : AppTheme.danger,
            ),
            child: Text(status == 'disetujui' ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
  }
}
