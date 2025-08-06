import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Database/bill_model.dart';

class ReceiptWidget extends StatefulWidget {
  final BillModel bill;
  final double paperWidth;

  const ReceiptWidget({
    Key? key,
    required this.bill,
    required this.paperWidth,
  }) : super(key: key);

  @override
  _ReceiptWidgetState createState() => _ReceiptWidgetState();
}

class _ReceiptWidgetState extends State<ReceiptWidget> {
  String? _logoPath;
  String _footerLine1 = "เวลาทำการ: เปิดทุกวัน 04.00 - 18.00";
  String _footerLine2 = "ขอบคุณที่ใช้บริการ";
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
        _footerLine1 = prefs.getString('bill_footer_line1') ?? _footerLine1;
        _footerLine2 = prefs.getString('bill_footer_line2') ?? _footerLine2;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.paperWidth,
        height: 200,
        color: Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final double totalAmount = widget.bill.netTotal + widget.bill.totalDiscount;
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'th_TH');

    const TextStyle regularStyle =
        TextStyle(fontSize: 18, color: Colors.black, fontFamily: 'Sarabun');
    const TextStyle boldStyle = TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontFamily: 'Sarabun');
    const TextStyle biggerBoldStyle = TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        fontFamily: 'Sarabun');

    return Container(
      width: widget.paperWidth,
      padding: const EdgeInsets.symmetric(
          horizontal: 2.0, vertical: 8.0), // <--- แก้ไข: ลด Padding ด้านข้าง
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_logoPath != null && File(_logoPath!).existsSync())
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Image.file(File(_logoPath!), height: 60),
            ),
          Text('ใบเสร็จรับเงิน', style: biggerBoldStyle),
          Text('เลขที่: ${widget.bill.billId}', style: regularStyle),
          Text('วันที่: ${dateFormat.format(widget.bill.billDate)}',
              style: regularStyle),
          const SizedBox(height: 5),
          const Divider(color: Colors.black, height: 10, thickness: 0.5),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('รายการ', style: boldStyle),
                Text('ราคารวม', style: boldStyle),
              ],
            ),
          ),
          const Divider(color: Colors.black, height: 10, thickness: 0.5),
          for (var item in widget.bill.items)
            Padding(
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
            ),
          const Divider(color: Colors.black, height: 10, thickness: 0.5),
          _buildTotalRow(
              'รวมเป็นเงิน:', totalAmount.toStringAsFixed(2), regularStyle),
          _buildTotalRow('ส่วนลด:',
              widget.bill.totalDiscount.toStringAsFixed(2), regularStyle),
          const Divider(
              color: Colors.black54,
              indent: 120,
              endIndent: 0,
              height: 5,
              thickness: 0.5),
          _buildTotalRow(
              'ยอดสุทธิ:', widget.bill.netTotal.toStringAsFixed(2), boldStyle),
          const SizedBox(height: 5),
          _buildTotalRow('รับเงิน:',
              widget.bill.moneyReceived.toStringAsFixed(2), regularStyle),
          _buildTotalRow('เงินทอน:', widget.bill.change.toStringAsFixed(2),
              biggerBoldStyle),
          const Divider(color: Colors.black, height: 20, thickness: 0.5),
          Text(_footerLine1, style: regularStyle, textAlign: TextAlign.center),
          Text(_footerLine2, style: regularStyle, textAlign: TextAlign.center),
          const SizedBox(height: 10),
        ],
      ),
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
