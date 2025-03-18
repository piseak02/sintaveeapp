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
  final String expiryDate;

  @HiveField(4)
  final String category;

  ProductModel({
    required this.name,
    required this.price,
    required this.quantity,
    required this.expiryDate,
    required this.category,
  });
}
