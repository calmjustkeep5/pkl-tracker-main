import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:apk_pkl_tracker/utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart'; // Import provider sinkronisasi
import '../../services/api_service.dart';
import '../../services/database_service.dart';
import 'form_izin_screen.dart';

// Default koordinat lokasi PKL jika guru belum menyimpan lokasi
const double _defaultOfficeLat = -6.966727656952764;
const double _defaultOfficeLng = 110.40244215284025;
const double _allowedRadiusMeters = 100; // Radius toleransi 100 meter

class PresensiScreen extends ConsumerStatefulWidget {
  const PresensiScreen({super.key});

  @override
  ConsumerState<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends ConsumerState<PresensiScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _loadingLocation = false;
  bool _loadingAction = false;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Layanan lokasi tidak aktif', isError: true);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Izin lokasi ditolak', isError: true);
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() => _currentPosition = pos);
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
        );
      }
    } catch (e) {
      _showSnack('Gagal mendapatkan lokasi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  double _officeLatFor(UserModel? pklLocation) => pklLocation?.pklLatitude ?? _defaultOfficeLat;
  double _officeLngFor(UserModel? pklLocation) => pklLocation?.pklLongitude ?? _defaultOfficeLng;

  double? _distanceToOffice(UserModel? pklLocation) {
    if (_currentPosition == null) return null;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _officeLatFor(pklLocation),
      _officeLngFor(pklLocation),
    );
  }

  // Cek apakah lokasi berada di dalam radius
  bool _isInRange(UserModel? pklLocation) {
    final dist = _distanceToOffice(pklLocation);
    return dist != null && dist <= _allowedRadiusMeters;
  }

  // Cek apakah waktu saat ini berada antara pukul 07:00 dan 16:59
  bool get _isTimeValid {
    final hour = _now.hour;
    return hour >= 7 && hour < 17;
  }

  // Cek gabungan: Harus di dalam lokasi DAN waktu yang valid
  bool _isEligible(UserModel? pklLocation) {
    return _isInRange(pklLocation) && _isTimeValid;
  }

  Future<void> _handleCheckIn(UserModel? pklLocation) async {
    if (!_isInRange(pklLocation)) {
      _showSnack(
          'Anda berada di luar jangkauan lokasi PKL (${_distanceToOffice(pklLocation)?.toStringAsFixed(0)} m)',
          isError: true);
      return;
    }
    setState(() => _loadingAction = true);
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;
    
    final success = await DatabaseService.checkIn(
      userId: user.uid,
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
    );
    if (success) {
      final attendance = await DatabaseService.getTodayAttendance(user.uid);
      if (attendance != null) {
        await ApiService().submitAttendance(attendance);
      }
      ref.invalidate(todayAttendanceProvider);
      _showSnack('Check-in berhasil! ✅');
    } else {
      _showSnack('Anda sudah check-in hari ini', isError: true);
    }
    setState(() => _loadingAction = false);
  }

  Future<void> _handleCheckOut() async {
    if (_currentPosition == null) {
      _showSnack('Lokasi belum terdeteksi', isError: true);
      return;
    }
    setState(() => _loadingAction = true);
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;
    
    final attendanceBefore = await DatabaseService.getTodayAttendance(user.uid);
    final success = await DatabaseService.checkOut(
      userId: user.uid,
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
    );
    if (success) {
      if (attendanceBefore != null) {
        final updatedAttendance = attendanceBefore.copyWith(
          checkOut: '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
          checkOutLat: _currentPosition!.latitude,
          checkOutLng: _currentPosition!.longitude,
        );
        await ApiService().submitAttendance(updatedAttendance);
      }
      ref.invalidate(todayAttendanceProvider);
      _showSnack('Check-out berhasil! ✅');
    } else {
      _showSnack('Gagal check-out', isError: true);
    }
    setState(() => _loadingAction = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss').format(_now);
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_now);

    // Memantau data absensi hari ini secara reaktif dari provider
    final todayAttendanceAsync = ref.watch(todayAttendanceProvider);
    final todayAttendance = todayAttendanceAsync.valueOrNull;
    final currentUser = ref.watch(authProvider).valueOrNull;
    final officeLat = _officeLatFor(currentUser);
    final officeLng = _officeLngFor(currentUser);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Presensi'),
        leading: const SizedBox.shrink(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Location Status Banner
            _LocationBanner(
              isInRange: _isInRange(currentUser),
              isLoading: _loadingLocation,
              distance: _distanceToOffice(currentUser),
              onRefresh: _getCurrentLocation,
            ),
            const SizedBox(height: 20),

            // Clock Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lokasi PKL siswa
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lokasi PKL untuk Presensi',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    currentUser != null && currentUser.pklPlaceName != null && currentUser.pklPlaceName!.isNotEmpty
                        ? currentUser.pklPlaceName!
                        : 'Belum ada nama tempat PKL. Hubungi guru untuk menambahkan.',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser != null && currentUser.pklPlaceAddress != null && currentUser.pklPlaceAddress!.isNotEmpty
                        ? currentUser.pklPlaceAddress!
                        : 'Belum ada alamat PKL. Hubungi guru untuk menambahkan.',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Map
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              clipBehavior: Clip.hardEdge,
              child: _currentPosition == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_searching,
                              color: AppTheme.textSecondary, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            _loadingLocation
                                ? 'Mencari lokasi...'
                                : 'Lokasi tidak tersedia',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : GoogleMap(
                      onMapCreated: (c) {
                        _mapController = c;
                        if (_currentPosition != null) {
                          _mapController?.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                zoom: 16,
                              ),
                            ),
                          );
                        }
                      },
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        zoom: 16,
                      ),
                      mapType: MapType.normal,
                      zoomControlsEnabled: true,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      compassEnabled: true,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      markers: {
                        Marker(
                          markerId: const MarkerId('user'),
                          position: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
                        ),
                        Marker(
                          markerId: const MarkerId('office'),
                          position: LatLng(officeLat, officeLng),
                          infoWindow: InfoWindow(title: currentUser?.pklPlaceName ?? 'Lokasi PKL'),
                        ),
                      },
                      circles: {
                        Circle(
                          circleId: const CircleId('radius'),
                          center: LatLng(officeLat, officeLng),
                          radius: _allowedRadiusMeters,
                          fillColor: AppTheme.primary.withValues(alpha: 0.1),
                          strokeColor: AppTheme.primary,
                          strokeWidth: 2,
                        ),
                      },
                    ),
            ),

            if (_currentPosition != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_pin,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Lokasi Anda: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('Lihat di peta',
                        style:
                            TextStyle(fontSize: 11, color: AppTheme.primary)),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // TAMPILAN STATUS ABSENSI HARI INI MENGGUNAKAN PROVIDER
            todayAttendanceAsync.when(
              data: (attendance) {
                if (attendance == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppTheme.success, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sudah Check-in',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.success,
                                    fontSize: 13)),
                            Text(
                              '${attendance.checkIn ?? "-"} WIB',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (attendance.checkOut != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Check-out',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                    fontSize: 13)),
                            Text(
                              '${attendance.checkOut} WIB',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                  child: Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Action Buttons
            if (todayAttendance == null)
              Column(
                children: [
                  if (!_isTimeValid)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Presensi hanya dibuka pukul 07:00 - 17:00',
                        style: TextStyle(
                            color: AppTheme.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  _ActionButton(
                    label: 'PRESENSI MASUK',
                    color: AppTheme.success,
                    onTap: (_isEligible(currentUser) && !_loadingAction) ? () => _handleCheckIn(currentUser) : null,
                    isLoading: _loadingAction,
                  ),
                ],
              )
            else if (todayAttendance.checkOut == null)
              Column(
                children: [
                  if (!_isTimeValid)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Presensi hanya dibuka pukul 07:00 - 17:00',
                        style: TextStyle(
                            color: AppTheme.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  _ActionButton(
                    label: 'PRESENSI KELUAR',
                    color: AppTheme.danger,
                    onTap: (_isEligible(currentUser) && !_loadingAction) ? _handleCheckOut : null,
                    isLoading: _loadingAction,
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Presensi hari ini sudah selesai ✅',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _ActionButton(
              label: 'IZIN TIDAK MASUK',
              color: AppTheme.primary,
              onTap: (todayAttendance?.status == 'izin') ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FormIzinScreen()),
                );
              },
              isLoading: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  final bool isInRange;
  final bool isLoading;
  final double? distance;
  final VoidCallback onRefresh;

  const _LocationBanner({
    required this.isInRange,
    required this.isLoading,
    required this.distance,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final color = isInRange ? AppTheme.success : AppTheme.warning;
    final label = isLoading
        ? 'Mendeteksi lokasi...'
        : isInRange
            ? 'Anda berada di area lokasi PKL'
            : 'Anda di luar area lokasi PKL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isInRange ? Icons.location_on : Icons.location_off,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                if (distance != null && !isLoading)
                  Text(
                    '${distance!.toStringAsFixed(0)} meter dari titik PKL',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.refresh, color: color, size: 20),
            onPressed: isLoading ? null : onRefresh,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null && !isLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? Colors.grey.shade400 : color,
          disabledBackgroundColor: Colors.grey.shade400,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: onTap,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(label,
                style: TextStyle(
                    color: isDisabled ? Colors.grey.shade700 : Colors.white, 
                    fontWeight: FontWeight.w700)),
      ),
    );
  }
}