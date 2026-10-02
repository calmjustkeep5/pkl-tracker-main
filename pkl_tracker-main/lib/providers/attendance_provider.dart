import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/attendance_model.dart';
import 'auth_provider.dart';

// Provider ini yang akan memantau status absensi hari ini secara global
final todayAttendanceProvider = FutureProvider.autoDispose<AttendanceModel?>((ref) async {
  // Dia akan otomatis ikut memantau jika ada perubahan status auth
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) return null;
  
  return await DatabaseService.getTodayAttendance(user.uid);
});