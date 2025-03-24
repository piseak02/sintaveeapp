import 'package:hive/hive.dart';

part 'log_model.g.dart';

@HiveType(typeId: 5) // ตรวจสอบให้ typeId ไม่ซ้ำกับ model อื่น
class LogModel {
  @HiveField(0)
  final String logId; // รหัส log ที่ไม่ซ้ำกัน

  @HiveField(1)
  final String message; // ข้อความ log

  @HiveField(2)
  final DateTime timestamp; // เวลาที่เกิดเหตุการณ์

  @HiveField(3)
  final String eventType; // ประเภทของเหตุการณ์ เช่น "add", "edit", "delete", "sale"

  LogModel({
    required this.logId,
    required this.message,
    required this.timestamp,
    required this.eventType,
  });
}
