// lib/StandaloneBarcode/standalone_print_preview.dart
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'standalone_label_model.dart';

class StandalonePrintPreview extends StatelessWidget {
  final List<StandaloneLabel> labels;

  const StandalonePrintPreview({Key? key, required this.labels})
      : super(key: key);

  Future<void> _generatePdfAndPrint() async {
    final pdf = pw.Document();

    const int itemsPerPage = 40; // 4 คอลัมน์ 10 แถว
    final List<List<StandaloneLabel>> pages = [];
    for (int i = 0; i < labels.length; i += itemsPerPage) {
      pages.add(labels.sublist(i,
          i + itemsPerPage > labels.length ? labels.length : i + itemsPerPage));
    }

    for (final pageLabels in pages) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            return pw.GridView(
              crossAxisCount: 4,
              childAspectRatio: 2.0,
              children: pageLabels.map((label) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.all(2.0),
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(label.name,
                          maxLines: 1,
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('ราคา: ${label.price} บาท',
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 4),
                      pw.BarcodeWidget(
                        color: PdfColors.black,
                        barcode: pw.Barcode.code128(),
                        data: label.barcode,
                        height: 35,
                        drawText: false,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(label.barcode,
                          style: const pw.TextStyle(
                              fontSize: 10, letterSpacing: 1.5)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตัวอย่างก่อนพิมพ์ (A4)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _generatePdfAndPrint,
          )
        ],
      ),
      body: Center(child: Text("หน้านี้สำหรับแสดงตัวอย่าง PDF เท่านั้น")),
    );
  }
}
