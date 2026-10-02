import 'package:hive/hive.dart';

part 'activity_model.g.dart';

@HiveType(typeId: 1)
class ActivityModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId; // Pemilik aktivitas
  @HiveField(2)
  final String title;
  @HiveField(3)
  final DateTime date;

  ActivityModel({required this.id, required this.userId, required this.title, required this.date});
}