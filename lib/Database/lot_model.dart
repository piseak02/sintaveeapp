import 'package:hive/hive.dart';

part 'lot_model.g.dart';

@HiveType(typeId: 4)
class LotModel {
  @HiveField(0)
  final String lotId; // รหัสเฉพาะของล็อต เช่น UUID หรือ LOT-20250324-001

  @HiveField(1)
  final String productId; // ใช้เชื่อมกับ ProductModel.id

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final DateTime expiryDate;

  @HiveField(4)
  final DateTime recordDate;

  @HiveField(5)
  final String? note;

  LotModel({
    required this.lotId,
    required this.productId,
    required this.quantity,
    required this.expiryDate,
    required this.recordDate,
    this.note,
  });

  /// คืนจำนวนวันที่เหลือก่อนหมดอายุ
  int get daysToExpire => expiryDate.difference(DateTime.now()).inDays;

  /// คืน true ถ้าหมดอายุแล้ว
  bool get isExpired => expiryDate.isBefore(DateTime.now());
}
