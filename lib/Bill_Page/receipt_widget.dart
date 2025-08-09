import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Database/bill_model.dart';

// Widget หลักสำหรับจัดการ State และการโหลดข้อมูล
class ReceiptWidget extends StatefulWidget {
  final BillModel bill;
  final double paperWidth;

  const ReceiptWidget({
    Key? key,
    required this.bill,
    required this.paperWidth,
  }) : super(key: key);

  @override
  State<ReceiptWidget> createState() => _ReceiptWidgetState();
}

class _ReceiptWidgetState extends State<ReceiptWidget> {
  String? _logoPath;
  String _footerLine1 = "";
  String _footerLine2 = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _logoPath = prefs.getString('bill_logo_path');
        _footerLine1 = prefs.getString('bill_footer_line1') ??
            "เวลาทำการ: เปิดทุกวัน 04.00 - 18.00";
        _footerLine2 =
            prefs.getString('bill_footer_line2') ?? "ขอบคุณที่ใช้บริการ";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.paperWidth,
        height: 300,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Container นี้สำคัญมากสำหรับตอนจับภาพหน้าจอ
    return Container(
      width: widget.paperWidth,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: ReceiptContent(
        bill: widget.bill,
        paperWidth: widget.paperWidth, // ✅ ส่งต่อความกว้างกระดาษ
        logoPath: _logoPath,
        footerLine1: _footerLine1,
        footerLine2: _footerLine2,
      ),
    );
  }
}

// Widget สำหรับแสดงเนื้อหาใบเสร็จ (ไม่มี State)
class ReceiptContent extends StatelessWidget {
  final BillModel bill;
  final double paperWidth; // ✅ รับความกว้างกระดาษ
  final String? logoPath;
  final String footerLine1;
  final String footerLine2;

  const ReceiptContent({
    Key? key,
    required this.bill,
    required this.paperWidth,
    this.logoPath,
    required this.footerLine1,
    required this.footerLine2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double totalAmount = bill.netTotal + bill.totalDiscount;
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'th_TH');

    // 🔎 ตรวจว่ากระดาษเป็น 58mm/80mm (ที่ 203dpi มัก ~384px/576px)
    final bool is80mm = paperWidth >= 520 && paperWidth <= 700;
    final bool is58mm = paperWidth < 520;
    final bool isThermal = is80mm || is58mm;

    // ขนาดตัวอักษรให้พอดีกับ 58mm/80mm
    final double base = is58mm ? 14 : (is80mm ? 18 : 18);
    final double baseBold = base + 1;
    final double big = is58mm ? 16 : (is80mm ? 20 : 20);

    final TextStyle regularStyle = TextStyle(
      fontSize: base,
      color: Colors.black,
      fontFamily: 'Sarabun',
    );
    final TextStyle boldStyle = TextStyle(
      fontSize: baseBold,
      fontWeight: FontWeight.bold,
      color: Colors.black,
      fontFamily: 'Sarabun',
    );
    final TextStyle biggerBoldStyle = TextStyle(
      fontSize: big,
      fontWeight: FontWeight.bold,
      color: Colors.black,
      fontFamily: 'Sarabun',
    );
    final TextStyle dimStyle = TextStyle(
      fontSize: base - 1,
      color: Colors.black87,
      fontFamily: 'Sarabun',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (logoPath != null && File(logoPath!).existsSync())
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Image.file(File(logoPath!), height: is58mm ? 50 : 60),
          ),
        Text('ใบเสร็จรับเงิน', style: biggerBoldStyle),
        Text('เลขที่: ${bill.billId}', style: regularStyle),
        Text('วันที่: ${dateFormat.format(bill.billDate)}',
            style: regularStyle),
        const SizedBox(height: 5),
        const Divider(color: Colors.black, height: 10, thickness: 0.5),

        // 📌 ส่วนหัวตารางแสดงเฉพาะกรณี "ไม่ใช่" 80/58mm
        if (!isThermal)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('รายการ', style: boldStyle),
                Text('ราคารวม', style: boldStyle),
              ],
            ),
          ),
        if (!isThermal)
          const Divider(color: Colors.black, height: 10, thickness: 0.5),

        // ✅ แสดงรายการแบบบล็อก 3 บรรทัดสำหรับ 80mm/58mm
        if (isThermal)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(bill.items.length, (index) {
              final item = bill.items[index];

              // ป้องกัน quantity = 0 และลอง parse เป็นตัวเลขกรณี type แปลก
              // ignore: unnecessary_type_check
              final num qty = (item.quantity is num)
                  ? item.quantity as num
                  : (num.tryParse(item.quantity.toString()) ?? 1);
              final double lineTotal = item.itemNetTotal;
              final double unitPrice = qty > 0 ? (lineTotal / qty) : lineTotal;

              String qtyStr;
              if (qty % 1 == 0) {
                qtyStr = qty.toInt().toString();
              } else {
                qtyStr = qty.toString();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // บรรทัดชื่อสินค้า
                  Text(item.productName, style: boldStyle),
                  const SizedBox(height: 1),
                  // บรรทัดราคา: unit x qty
                  Text('ราคา : ${unitPrice.toStringAsFixed(2)} x$qtyStr',
                      style: dimStyle),
                  // บรรทัดรวม (ชิดขวา)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('รวม ${lineTotal.toStringAsFixed(2)} บาท',
                        style: regularStyle),
                  ),
                  // เส้นคั่น (ยกเว้นรายการสุดท้าย)
                  if (index != bill.items.length - 1)
                    const Divider(
                      color: Colors.black26,
                      height: 12,
                      thickness: 0.7,
                    ),
                ],
              );
            }),
          ),

        // 🔁 รูปแบบเดิมสำหรับหน้ากระดาษอื่น (เช่น A4)
        if (!isThermal)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: bill.items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.productName} x${item.quantity}',
                        style: regularStyle,
                      ),
                    ),
                    Text(
                      item.itemNetTotal.toStringAsFixed(2),
                      style: regularStyle,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

        const Divider(color: Colors.black, height: 10, thickness: 0.5),
        _buildTotalRow(
            'รวมเป็นเงิน:', totalAmount.toStringAsFixed(2), regularStyle),
        _buildTotalRow(
            'ส่วนลด:', bill.totalDiscount.toStringAsFixed(2), regularStyle),
        const Divider(
            color: Colors.black54,
            indent: 120,
            endIndent: 0,
            height: 5,
            thickness: 0.5),
        _buildTotalRow(
            'ยอดสุทธิ:', bill.netTotal.toStringAsFixed(2), boldStyle),
        const SizedBox(height: 5),
        _buildTotalRow(
            'รับเงิน:', bill.moneyReceived.toStringAsFixed(2), regularStyle),
        _buildTotalRow(
            'เงินทอน:', bill.change.toStringAsFixed(2), biggerBoldStyle),
        const Divider(color: Colors.black, height: 20, thickness: 0.5),
        Text(footerLine1, style: regularStyle, textAlign: TextAlign.center),
        Text(footerLine2, style: regularStyle, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
