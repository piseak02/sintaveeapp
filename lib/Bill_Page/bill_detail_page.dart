import 'dart:typed_data';
import 'package:flutter/material.dart';
// สำหรับ PdfPageFormat
import 'package:pdf/pdf.dart';
// สำหรับสร้าง PDF
import 'package:pdf/widgets.dart' as pw;
// สำหรับแสดง PDF Preview และสั่งพิมพ์
import 'package:printing/printing.dart';
import 'package:flutter/services.dart'
    show rootBundle; // สำหรับโหลดฟอนต์จาก assets

import '../Database/bill_model.dart'; // ไฟล์ Model บิล

// หน้าแสดงรายละเอียดบิล
class BillDetailPage extends StatelessWidget {
  final BillModel bill;

  const BillDetailPage({Key? key, required this.bill}) : super(key: key);

  // ฟังก์ชันสำหรับสร้าง PDF จากข้อมูลบิล
  // ฟังก์ชันสำหรับสร้าง PDF จากข้อมูลบิล
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final doc = pw.Document();

    // โหลดฟอนต์ไทยจาก assets
    final fontData = await rootBundle.load("assets/fonts/THSarabun.ttf");
    final fontThai = pw.Font.ttf(fontData.buffer.asByteData());
    final logoBytes =
        (await rootBundle.load('assets/logo1.png')).buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    doc.addPage(
      pw.Page(
          pageFormat: format,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ✅ โลโก้หัวบิล (ขนาดเล็ก)
                pw.Center(
                  child: pw.Image(logoImage, width: 100, height: 100),
                ),
                pw.SizedBox(height: 10),
                // ... ส่วนอื่น ๆ ต่อไปเหมือนเดิม ...
                pw.SizedBox(height: 10),

                // ✅ ชื่อหัวบิล
                // pw.Center(
                //   child: pw.Text("ใบเสร็จสินค้า",
                //       style: pw.TextStyle(
                //           font: fontThai,
                //           fontSize: 16,
                //           fontWeight: pw.FontWeight.bold)),
                // ),
                // pw.SizedBox(height: 5),

                pw.Text("บิลเลขที่: ${bill.billId}",
                    style: pw.TextStyle(font: fontThai, fontSize: 12)),
                pw.Text("วันที่: ${bill.billDate.toLocal()}",
                    style: pw.TextStyle(font: fontThai, fontSize: 12)),

                pw.SizedBox(height: 10),
                pw.Text("รายการสินค้า:",
                    style: pw.TextStyle(
                        font: fontThai,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold)),
                pw.Divider(),

                ...bill.items.map((item) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item.productName,
                          style: pw.TextStyle(
                              font: fontThai,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                          "ราคา: ${item.price} x ${item.quantity} (ส่วนลด: ${item.discount})",
                          style: pw.TextStyle(font: fontThai, fontSize: 12)),
                      pw.Text("รวม: ${item.itemNetTotal} บาท",
                          style: pw.TextStyle(font: fontThai, fontSize: 12)),
                      pw.Divider(),
                    ],
                  );
                }).toList(),

                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("รวมสุทธิ:",
                        style: pw.TextStyle(
                            font: fontThai, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${bill.netTotal} บาท",
                        style: pw.TextStyle(font: fontThai)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("รับเงิน:", style: pw.TextStyle(font: fontThai)),
                    pw.Text("${bill.moneyReceived} บาท",
                        style: pw.TextStyle(font: fontThai)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("ทอน:", style: pw.TextStyle(font: fontThai)),
                    pw.Text("${bill.change} บาท",
                        style: pw.TextStyle(font: fontThai)),
                  ],
                ),

                pw.SizedBox(height: 10),
                pw.Divider(),

                // ✅ Footer จัดกลาง
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text("เวลาทำการ: เปิดทุกวัน 08.00 - 19.00",
                          style: pw.TextStyle(font: fontThai)),
                      pw.Text("ขอบคุณที่ใช้บริการ",
                          style: pw.TextStyle(font: fontThai)),
                    ],
                  ),
                ),
              ],
            );
          }),
    );

    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("รายละเอียดบิล: ${bill.billId}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("รหัสบิล: ${bill.billId}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text("วันที่: ${bill.billDate.toLocal().toString().split(' ')[0]}",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("ยอดรวมสุทธิ: ${bill.netTotal.toStringAsFixed(2)} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("เงินที่รับ: ${bill.moneyReceived.toStringAsFixed(2)} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("เงินทอน: ${bill.change.toStringAsFixed(2)} บาท",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text("รายการสินค้า:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            ...bill.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.productName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      "ราคา: ${item.price.toStringAsFixed(2)} บาท  x  ${item.quantity}  (ส่วนลด: ${item.discount.toStringAsFixed(2)})",
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      "รวม: ${item.itemNetTotal.toStringAsFixed(2)} บาท",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Divider(),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),

            // ปุ่มแสดง PDF Preview
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  // เปิดหน้าแสดงตัวอย่าง PDF
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfPreviewPage(buildPdf: _generatePdf),
                    ),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text("แสดงตัวอย่าง/พิมพ์บิล"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// หน้าที่ใช้แสดงตัวอย่าง PDF Preview
class PdfPreviewPage extends StatelessWidget {
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;

  const PdfPreviewPage({Key? key, required this.buildPdf}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ตัวอย่าง PDF"),
      ),
      body: PdfPreview(
        build: (format) => buildPdf(format),
        pdfFileName: "bill.pdf",
      ),
    );
  }
}
