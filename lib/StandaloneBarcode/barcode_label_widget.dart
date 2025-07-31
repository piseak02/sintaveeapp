import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

class BarcodeLabelWidget extends StatelessWidget {
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
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 4, vertical: 4), // [แก้ไข] ลด Padding แนวตั้งเล็กน้อย
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // [แก้ไข] จัดให้อยู่กลางแนวตั้ง
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
          const SizedBox(height: 2), // [แก้ไข] ลดระยะห่าง
          // [แก้ไข] ลดความสูงของบาร์โค้ดลง
          BarcodeWidget(
            barcode: Barcode.code128(),
            data: barcode,
            height: 30, // <--- ลดจาก 40 เหลือ 30
            drawText: false,
            color: Colors.black,
          ),
          const SizedBox(height: 1), // [แก้ไข] ลดระยะห่าง
          Text(
            barcode,
            style: const TextStyle(
                fontSize: 9,
                letterSpacing: 1.0,
                color: Colors.black), // [แก้ไข] ลดขนาด Font และระยะห่าง
          ),
        ],
      ),
    );
  }
}
