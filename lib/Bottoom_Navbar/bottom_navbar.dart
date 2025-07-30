// lib/Bottoom_Navbar/bottom_navbar.dart

import 'package:flutter/material.dart';
import 'package:sintaveeapp/FinancialReport/financial_report_page.dart';
import 'package:sintaveeapp/Supplier/list_supplier.dart';
import '../Bill_Page/BillSale_Page.dart';
import '../Sale_Page/sale_product.dart';
import '../Database/product_model.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:hive/hive.dart';
import 'package:audioplayers/audioplayers.dart';

class BottomNavbar extends StatelessWidget {
  BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onHomeButtonPressed, // ✅ เพิ่ม callback ที่เป็น optional
  });

  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback? onHomeButtonPressed; // ✅ ประกาศตัวแปร

  final AudioPlayer _audioPlayer = AudioPlayer();

  void _handleNavigation(int index, BuildContext context) async {
    // ✅ --- แก้ไข Logic การกดปุ่ม Home ---
    if (index == 0) {
      // 1. เรียกใช้ฟังก์ชันตรวจสอบก่อน (ถ้ามี)
      onHomeButtonPressed?.call();

      // 2. นำทางกลับไปหน้าแรก
      if (ModalRoute.of(context)?.isFirst ?? false) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    // --- Logic สำหรับปุ่มอื่นๆ ยังคงเหมือนเดิม ---
    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => FinancialReportPage()));
    } else if (index == 2) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const SimpleBarcodeScannerPage()),
      );
      if (result != null && result != '-1' && context.mounted) {
        final productBox = Hive.box<ProductModel>('products');
        final matching = productBox.values.firstWhere(
          (p) => p.barcode == result,
          orElse: () => ProductModel(
              id: '',
              name: 'ไม่พบสินค้า',
              retailPrice: 0,
              wholesalePrice: 0,
              category: 'ไม่ระบุ',
              barcode: ''),
        );
        if (matching.name != 'ไม่พบสินค้า') {
          await _audioPlayer.play(AssetSource('beep-313342.mp3'));
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SalePage(initialBarcode: result)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("ไม่พบสินค้าด้วยบาร์โค้ดนี้")));
        }
      }
    } else if (index == 3) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => BillSale_Page()));
    } else if (index == 4) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => SupplierListPage()));
    } else {
      onTap(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color.fromARGB(230, 0, 0, 0),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedItemColor: const Color.fromARGB(255, 235, 157, 40),
      unselectedItemColor: const Color.fromARGB(255, 228, 221, 221),
      elevation: 0,
      currentIndex: currentIndex,
      onTap: (index) => _handleNavigation(index, context),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าแรก"),
        BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: "บัญชี"),
        BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner), label: "สแกนบาร์โค้ด"),
        BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long), label: "บิลลูกค้า"),
        BottomNavigationBarItem(
            icon: Icon(Icons.description), label: "บิลซัพพายเออร์"),
      ],
    );
  }
}
