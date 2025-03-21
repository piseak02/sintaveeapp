import 'package:hive/hive.dart';

part 'bill_model.g.dart'; // ต้องรัน build_runner เพื่อสร้างไฟล์นี้

@HiveType(typeId: 2) // กำหนด typeId ให้ไม่ซ้ำกับ Model อื่น
class BillItem {
  @HiveField(0)
  final String productName;   // ชื่อสินค้า

  @HiveField(1)
  final double price;         // ราคาต่อหน่วย (ปลีกหรือส่งก็ได้)

  @HiveField(2)
  final int quantity;         // จำนวน

  @HiveField(3)
  final double discount;      // ส่วนลดของรายการนี้ (ถ้าไม่มีให้เป็น 0)

  // ถ้าต้องการเก็บราคารวมสุทธิของรายการ
  // สามารถคำนวณได้: (price * quantity) - discount
  // หรือจะเก็บเป็น field ก็ได้ แล้วแต่ออกแบบ
  double get itemNetTotal => (price * quantity) - discount;

  BillItem({
    required this.productName,
    required this.price,
    required this.quantity,
    this.discount = 0.0,
  });
}

@HiveType(typeId: 3) // กำหนด typeId ให้ไม่ซ้ำกับ Model อื่น
class BillModel {
  @HiveField(0)
  final String billId;              // รหัสบิล (เช่น สร้างจาก datetime หรือ running number)

  @HiveField(1)
  final DateTime billDate;          // วันที่ออกบิล

  @HiveField(2)
  final List<BillItem> items;       // รายการสินค้าในบิล

  @HiveField(3)
  final double totalDiscount;       // ส่วนลดรวม (ถ้ามีส่วนลดทั้งบิล)

  @HiveField(4)
  final double netTotal;            // ราคารวมสุทธิ (รวมทุก itemNetTotal - totalDiscount)
  
  @HiveField(5)
  final double moneyReceived;       // เงินที่รับจากลูกค้า

  @HiveField(6)
  final double change;              // เงินทอน

  BillModel({
    required this.billId,
    required this.billDate,
    required this.items,
    this.totalDiscount = 0.0,
    required this.netTotal,
    required this.moneyReceived,
    required this.change,
  });
}
