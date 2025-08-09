import 'dart:typed_data';
import 'package:flutter/material.dart';

class ScrollablePreviewDialog extends StatelessWidget {
  final Uint8List imageBytes;
  final String printerIp;

  const ScrollablePreviewDialog({
    Key? key,
    required this.imageBytes,
    required this.printerIp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    return Container(
      // กำหนดความสูงสูงสุดของ Dialog ที่ 80% ของหน้าจอ
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'ตัวอย่างก่อนพิมพ์',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          // --- นี่คือหัวใจสำคัญ: ทำให้เนื้อหาตรงกลางเลื่อนได้ ---
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Image.memory(imageBytes, fit: BoxFit.contain),
                    const SizedBox(height: 16),
                    Text(
                      'จะพิมพ์ไปยัง IP: $printerIp',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    // เพิ่มที่ว่างด้านล่างสุดของเนื้อหาที่เลื่อนได้
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          // --- ส่วนของปุ่ม ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // คืนค่า false (ยกเลิก)
                  },
                  child: const Text('ยกเลิก'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // คืนค่า true (ยืนยัน)
                  },
                  child: const Text('ยืนยันการพิมพ์'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
