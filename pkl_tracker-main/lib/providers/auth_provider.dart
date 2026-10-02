import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

// Inisialisasi provider untuk AuthNotifier
final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
      return AuthNotifier();
    });

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier() : super(const AsyncValue.data(null));

  // Fungsi untuk set data user saat login
  void setUser(UserModel user) {
    state = AsyncValue.data(user);
  }

  // --- FUNGSI LOGIN ---
  Future<String?> login(String email, String password) async {
    try {
      final response = await ApiService().loginUser(email.trim(), password);
      if (response != null &&
          response['ok'] == true &&
          response['user'] is Map) {
        final userData = Map<String, dynamic>.from(response['user'] as Map);
        userData['password'] = password;
        final user = UserModel.fromMap(userData);
        await DatabaseService.registerUser(user);
        setUser(user);
        return null;
      }

      final localUser = await DatabaseService.getUserByEmail(email);
      if (localUser != null && localUser.password == password) {
        setUser(localUser);
        return null;
      }
      return response?['error']?.toString() ?? 'Email atau password salah.';
    } catch (e) {
      return e.toString();
    }
  }

  // --- FUNGSI REGISTER ---
  Future<String?> register(UserModel newUser) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      final success = await DatabaseService.registerUser(newUser);
      if (!success) {
        return 'Gagal mendaftar. Email mungkin sudah digunakan.';
      }

      setUser(newUser);
      await ApiService().syncUser(newUser);
      return null; // Sukses, tidak ada error
    } catch (e) {
      return e.toString();
    }
  }

  // --- FUNGSI GANTI PASSWORD ---
  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      // TODO: Implementasi ganti password ke database/Firebase/API

      return null; // Sukses
    } catch (e) {
      return e.toString(); // Gagal
    }
  }

  // --- FUNGSI UPDATE PROFIL (Untuk Siswa) ---
  Future<void> updateUserProfile(UserModel updatedUser) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      await DatabaseService.updateUser(updatedUser);
      await ApiService().syncUser(updatedUser);
      state = AsyncValue.data(updatedUser);
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }

  // --- FUNGSI UPDATE PROFIL (Untuk Guru) ---
  Future<void> updateProfile(UserModel updatedUser) async {
    await updateUserProfile(updatedUser);
  }

  // --- FUNGSI LOGOUT ---
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    state = const AsyncValue.data(null);
  }
}
