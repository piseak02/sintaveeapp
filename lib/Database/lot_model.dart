import 'package:hive/hive.dart';

part 'lot_model.g.dart';

@HiveType(typeId: 4) // ต้องไม่ซ้ำกับ model อื่น
class LotModel {
  @HiveField(0)
  final DateTime recordDate; // วันที่บันทึกข้อมูล

  @HiveField(1)
  final String productName; // ชื่อสินค้า (ใช้เป็นตัวเชื่อมกับ Product)

  @HiveField(2)
  final int quantity; // จำนวน

  @HiveField(3)
  final String expiryDate; // วันหมดอายุ (หรือใช้ DateTime ก็ได้)

  LotModel({
    required this.recordDate,
    required this.productName,
    required this.quantity,
    required this.expiryDate,
  });
}
