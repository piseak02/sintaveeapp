import 'package:flutter/material.dart';
import '../Database/product_model.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

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
            Text("ราคาปลีก: ${product.Retail_price} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("ราคาส่ง: ${product.Wholesale_price} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("จำนวน: ${product.quantity}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("วันหมดอายุ: ${product.expiryDate ?? 'ไม่มีข้อมูล'}",
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
