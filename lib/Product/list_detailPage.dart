import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../Database/product_model.dart';
import '../Database/lot_model.dart';


class ProductDetailPage extends StatelessWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  List<LotModel> _getLotsForProduct(String productId) {
  final lotBox = Hive.box<LotModel>('lots');
  return lotBox.values.where((lot) => lot.productId == productId).toList();
}

int _getTotalQuantity(String productId) {
  return _getLotsForProduct(productId).fold(0, (sum, lot) => sum + lot.quantity);
}

String _getNearestExpiry(String productId) {
  final lots = _getLotsForProduct(productId);
  if (lots.isEmpty) return 'ไม่มีข้อมูล';
  lots.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  final nearest = lots.first.expiryDate;
  return "${nearest.day.toString().padLeft(2, '0')}/"
         "${nearest.month.toString().padLeft(2, '0')}/"
         "${nearest.year}";
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
          255, 248, 247, 247), // เปลี่ยนสีพื้นหลังเป็นสีเทา
      appBar: AppBar(
        title: Text(product.name), // แสดงชื่อสินค้าบน AppBar
        backgroundColor: Colors.orange, // ใส่สี appbar เป็นสีส้ม
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ชื่อสินค้า: ${product.name}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),
            Text("หมวดหมู่: ${product.category}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("ราคาปลีก: ${product.retailPrice} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("ราคาส่ง: ${product.wholesalePrice} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("จำนวน: ${_getTotalQuantity(product.id)}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("วันหมดอายุที่ใกล้ที่สุด: ${_getNearestExpiry(product.id)}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("บาร์โค้ด: ${product.barcode ?? '-'}",
                style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
