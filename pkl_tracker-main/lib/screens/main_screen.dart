import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/attendance_model.dart';
import '../../utils/app_theme.dart';

// Koordinat lokasi PKL (bisa diganti sesuai kebutuhan)
const double _officeLat = -6.9828;
const double _officeLng = 110.4091;
const double _allowedRadiusMeters = 100; // 100 meter

class PresensiScreen extends ConsumerStatefulWidget {
  const PresensiScreen({super.key});

  @override
  ConsumerState<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends ConsumerState<PresensiScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  AttendanceModel? _todayAttendance;
  bool _loadingLocation = false;
  bool _loadingAction = false;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
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

  Future<void> _loadTodayAttendance() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;
    final att = await DatabaseService.getTodayAttendance(user.uid);
    if (mounted) setState(() => _todayAttendance = att);
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

  double? get _distanceToOffice {
    if (_currentPosition == null) return null;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _officeLat,
      _officeLng,
    );
  }

  bool get _isInRange {
    final dist = _distanceToOffice;
    return dist != null && dist <= _allowedRadiusMeters;
  }

  Future<void> _handleCheckIn() async {
    if (!_isInRange) {
      _showSnack(
          'Anda berada di luar jangkauan lokasi PKL (${_distanceToOffice?.toStringAsFixed(0)} m)',
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
      await _loadTodayAttendance();
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
    final success = await DatabaseService.checkOut(
      userId: user.uid,
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
    );
    if (success) {
      await _loadTodayAttendance();
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
              isInRange: _isInRange,
              isLoading: _loadingLocation,
              distance: _distanceToOffice,
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
                            CameraUpdate.newLatLngZoom(
                              LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              16,
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
                      mapToolbarEnabled: true,
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
                        const Marker(
                          markerId: MarkerId('office'),
                          position: LatLng(_officeLat, _officeLng),
                          infoWindow: InfoWindow(title: 'Lokasi PKL'),
                        ),
                      },
                      circles: {
                        Circle(
                          circleId: const CircleId('radius'),
                          center: const LatLng(_officeLat, _officeLng),
                          radius: _allowedRadiusMeters,
                          fillColor: AppTheme.primary.withValues(alpha: 25),
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

            // Check-in / Check-out info row
            if (_todayAttendance != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.success.withValues(alpha: 77)),
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
                            '${_todayAttendance!.checkIn ?? "-"} WIB',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (_todayAttendance!.checkOut != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Check-out',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                  fontSize: 13)),
                          Text(
                            '${_todayAttendance!.checkOut} WIB',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            if (_todayAttendance == null)
              _ActionButton(
                label: 'PRESENSI MASUK',
                color: AppTheme.success,
                onTap: _loadingAction ? null : _handleCheckIn,
                isLoading: _loadingAction,
              )
            else if (_todayAttendance!.checkOut == null)
              _ActionButton(
                label: 'PRESENSI KELUAR',
                color: AppTheme.danger,
                onTap: _loadingAction ? null : _handleCheckOut,
                isLoading: _loadingAction,
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
            ? 'Anda berada di sekitar lokasi PKL'
            : 'Anda diluar area lokasi PKL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 77)),
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
                    '${distance!.toStringAsFixed(0)} meter dari lokasi PKL',
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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
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
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}