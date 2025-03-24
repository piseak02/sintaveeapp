import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class ProductModel {
  @HiveField(0)
  final String id; // 🔑 ใช้เชื่อมกับ LotModel

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double retailPrice;

  @HiveField(3)
  final double wholesalePrice;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String? barcode;

  @HiveField(6)
  final String? imageUrl; // เพิ่มถ้ามีรูป

  ProductModel({
    required this.id,
    required this.name,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.category,
    this.barcode,
    this.imageUrl,
  });

  get key => null;
}
