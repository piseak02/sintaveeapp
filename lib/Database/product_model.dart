import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class ProductModel {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double price;

  @HiveField(2)
  final int quantity;

  @HiveField(3)
  final String? expiryDate; // ✅ เปลี่ยนจาก String เป็น String?

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String? barcode; // ✅ เปลี่ยนจาก String เป็น String?

  ProductModel({
    required this.name,
    required this.price,
    required this.quantity,
    this.expiryDate, // ✅ ไม่บังคับต้องมีค่า
    required this.category,
    this.barcode, // ✅ ไม่บังคับต้องมีค่า
  });

  get key => null;
}
