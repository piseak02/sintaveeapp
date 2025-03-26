import 'package:hive/hive.dart';

part 'supplier_name_model.g.dart';

@HiveType(typeId: 6)
class SupplierNameModel {
  @HiveField(0)
  final String name;

  SupplierNameModel({required this.name});
}
