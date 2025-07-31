import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

class BarcodeLabelWidget extends StatelessWidget {
  // รับข้อมูลเป็น String ตรงๆ
  final String name;
  final String price;
  final String barcode;

  const BarcodeLabelWidget({
    Key? key,
    required this.name,
    required this.price,
    required this.barcode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ตรวจสอบว่ามีข้อมูลบาร์โค้ดส่งมาหรือไม่
    if (barcode.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.red),
        ),
        child: const Center(
          child: Text("ไม่มีบาร์โค้ด",
              style: TextStyle(color: Colors.red, fontSize: 10)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'ราคา: $price บาท',
            style: const TextStyle(fontSize: 9, color: Colors.black),
          ),
          const SizedBox(height: 4),
          BarcodeWidget(
            barcode: Barcode.code128(),
            data: barcode,
            height: 40,
            drawText: false,
            color: Colors.black,
          ),
          const SizedBox(height: 2),
          Text(
            barcode,
            style: const TextStyle(
                fontSize: 10, letterSpacing: 1.5, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
