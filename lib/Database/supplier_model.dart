import 'package:hive/hive.dart';

part 'supplier_model.g.dart';

@HiveType(typeId: 5)
class SupplierModel {
  @HiveField(0)
  final String name;

  // เก็บ path ของภาพบิลที่ถ่ายลงในเครื่อง (ถ้ามีหลายรูป ให้คั่นด้วย comma)
  @HiveField(1)
  final String? billImagePath;

  // เก็บจำนวนเงินที่จ่าย (ยอดรวม)
  @HiveField(2)
  final double paymentAmount;

  // วันที่บันทึกข้อมูล
  @HiveField(3)
  final DateTime recordDate;

  SupplierModel({
    required this.name,
    this.billImagePath,
    required this.paymentAmount,
    DateTime? recordDate,
  }) : recordDate = recordDate ?? DateTime.now();
}
