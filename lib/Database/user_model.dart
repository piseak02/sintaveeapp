import 'package:hive/hive.dart';

part "user_model.g.dart";

// *** สำคัญ: ใช้ typeId ที่ไม่ซ้ำกับ Model อื่นๆ ของคุณ ***
// เช่น ถ้า Model ของคุณใช้ typeId 0-6, ให้เริ่มที่ 7 หรือ 100
@HiveType(typeId: 100) 
class UserModel extends HiveObject {
  @HiveField(0)
  late String username;

  @HiveField(1)
  late String password; // ในแอปจริงควรเข้ารหัสรหัสผ่านก่อนเก็บ

  UserModel({required this.username, required this.password});
}