// lib/StandaloneBarcode/standalone_label_model.dart
class StandaloneLabel {
  final String name;
  final String price;
  final String barcode;
  // เพิ่ม id เพื่อให้แต่ละรายการไม่ซ้ำกันใน List
  final String id = DateTime.now().millisecondsSinceEpoch.toString();

  StandaloneLabel({
    required this.name,
    required this.price,
    required this.barcode,
  });
}