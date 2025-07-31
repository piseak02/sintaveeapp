import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'standalone_label_model.dart';
import 'barcode_label_widget.dart';

class StandalonePrintPreview extends StatelessWidget {
  final List<StandaloneLabel> labels;

  const StandalonePrintPreview({Key? key, required this.labels})
      : super(key: key);

  /// [สมบูรณ์] ฟังก์ชันสร้าง PDF โดยนำฉลากขนาดจริงมาเรียงบนหน้า A4
  Future<void> _generateA4PdfWithFixedSizeLabels() async {
    final pdf = pw.Document();

    // กำหนดขนาดของฉลากแต่ละดวง (หน่วยเป็น mm)
    const double labelWidthMm = 37.29;
    const double labelHeightMm = 25.93;

    // แปลงเป็นหน่วย pdf point
    const double labelWidth = labelWidthMm * PdfPageFormat.mm;
    const double labelHeight = labelHeightMm * PdfPageFormat.mm;

    // คำนวณจำนวนฉลากที่พอดีในหนึ่งหน้า A4
    // A4 width ~210mm, height ~297mm
    const int cols = 5; // ~210 / 37.29 = 5.6 -> ปัดลงเป็น 5 คอลัมน์
    const int rows = 11; // ~297 / 25.93 = 11.4 -> ปัดลงเป็น 11 แถว
    const int itemsPerPage = cols * rows; // 55 ดวงต่อหน้า

    final List<List<StandaloneLabel>> pages = [];
    for (int i = 0; i < labels.length; i += itemsPerPage) {
      pages.add(labels.sublist(i,
          i + itemsPerPage > labels.length ? labels.length : i + itemsPerPage));
    }

    for (final pageLabels in pages) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin:
              const pw.EdgeInsets.all(10 * PdfPageFormat.mm), // ขอบกระดาษ 1 ซม.
          build: (pw.Context context) {
            return pw.Wrap(
              spacing: 0, // ระยะห่างแนวนอน
              runSpacing: 0, // ระยะห่างแนวตั้ง
              children: pageLabels.map((label) {
                // สร้าง Container ขนาดตายตัวสำหรับแต่ละฉลาก
                return pw.Container(
                  width: labelWidth,
                  height: labelHeight,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 1.5 * PdfPageFormat.mm,
                      vertical: 1.5 * PdfPageFormat.mm),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    mainAxisSize: pw.MainAxisSize.min,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        label.name,
                        maxLines: 1,
                        style: pw.TextStyle(
                            fontSize: 7, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        'ราคา: ${label.price} บาท',
                        style: const pw.TextStyle(fontSize: 6),
                      ),
                      pw.SizedBox(height: 2),
                      pw.BarcodeWidget(
                        color: PdfColors.black,
                        barcode: pw.Barcode.code128(),
                        data: label.barcode,
                        height: 12,
                        drawText: false,
                      ),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        label.barcode,
                        style:
                            const pw.TextStyle(fontSize: 6, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    // อัตราส่วนของฉลากสำหรับแสดงผลบนหน้าจอ
    const double labelAspectRatio = 37.29 / 25.93;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตัวอย่างบน A4'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'พิมพ์ลง A4',
            onPressed: _generateA4PdfWithFixedSizeLabels,
          )
        ],
      ),
      // แสดงตัวอย่างเป็นตาราง A4 ที่สวยงาม
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // แสดงตัวอย่าง 3 คอลัมน์ในแอป
          childAspectRatio: labelAspectRatio,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: labels.length,
        itemBuilder: (context, index) {
          final label = labels[index];
          // ใช้ BarcodeLabelWidget เดิมเพื่อแสดงผลในแอป
          return BarcodeLabelWidget(
            name: label.name,
            price: label.price,
            barcode: label.barcode,
          );
        },
      ),
    );
  }
}
