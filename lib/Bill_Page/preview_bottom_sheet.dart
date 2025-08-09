import 'dart:typed_data';
import 'package:flutter/material.dart';

class PreviewBottomSheet extends StatelessWidget {
  final Uint8List imageBytes;
  final String printerIp;

  const PreviewBottomSheet({
    Key? key,
    required this.imageBytes,
    required this.printerIp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ใช้ DraggableScrollableSheet เพื่อให้ปรับขนาดและเลื่อนได้
    return DraggableScrollableSheet(
      initialChildSize: 0.7, // ขนาดเริ่มต้น 70%
      minChildSize: 0.4, // ขนาดเล็กสุด 40%
      maxChildSize: 0.9, // ขนาดใหญ่สุด 90%
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // แถบสำหรับลาก
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Text(
                'ตัวอย่างก่อนพิมพ์',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              // --- ส่วนเนื้อหาที่เลื่อนได้ ---
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController, // เชื่อม controller
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Image.memory(imageBytes, fit: BoxFit.contain),
                        const SizedBox(height: 16),
                        Text(
                          'จะพิมพ์ไปยัง IP: $printerIp',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        // เพิ่มที่ว่างด้านล่างสุดของเนื้อหา
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              // --- ส่วนปุ่ม ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('ยกเลิก'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('ยืนยันการพิมพ์'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
