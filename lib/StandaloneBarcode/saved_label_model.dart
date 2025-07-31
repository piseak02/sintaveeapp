import 'package:hive/hive.dart';

part 'saved_label_model.g.dart'; // ไฟล์นี้จะถูกสร้างอัตโนมัติ

@HiveType(typeId: 8) // (สำคัญ) กำหนด typeId ไม่ให้ซ้ำกับ Model อื่น
class SavedLabelModel extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late String price;

  @HiveField(2)
  late String barcode;

  @HiveField(3)
  // ใช้ barcode เป็น ID เฉพาะตัว
  String get id => barcode;
}
