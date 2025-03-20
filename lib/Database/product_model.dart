import 'package:hive/hive.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class ProductModel {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double Retail_price;

  @HiveField(2)
  final double Wholesale_price;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final String? expiryDate;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final String? barcode;

  ProductModel({
    required this.name,
    required this.Retail_price,
    required this.Wholesale_price,
    required this.quantity,
    this.expiryDate,
    required this.category,
    this.barcode,
  });

  get key => null;
}
