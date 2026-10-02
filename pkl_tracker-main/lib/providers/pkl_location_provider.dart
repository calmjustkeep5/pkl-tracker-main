import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

final activePklLocationProvider = FutureProvider.autoDispose<UserModel?>((ref) async {
  return await DatabaseService.getActivePklLocation();
});
