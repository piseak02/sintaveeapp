import 'package:flutter/material.dart';
import 'package:sintaveeapp/AccountPageApp/account_page.dart';
import 'package:sintaveeapp/Supplier/list_supplier.dart';
// MyHomepage import is no longer needed here for navigation
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
  });

  final int currentIndex;
  final Function(int) onTap;

  // ประกาศ AudioPlayer ที่นี่
  final AudioPlayer _audioPlayer = AudioPlayer();

  void _handleNavigation(int index, BuildContext context) async {
    // ✅ --- แก้ไข Logic การเปลี่ยนหน้าทั้งหมด ---

    // ถ้าผู้ใช้อยู่หน้าอื่น แล้วกดปุ่ม "หน้าแรก" (index 0)
    // ให้ใช้วิธี "ย้อนกลับ" ไปยังหน้าแรกสุด แทนการสร้างหน้าใหม่
    if (index == 0) {
      // คำสั่งนี้จะปิดหน้าปัจจุบันทั้งหมด แล้วย้อนกลับไปที่หน้าแรกสุด (MyHomepage)
      // ทำให้เราไม่ต้องสร้าง MyHomepage ขึ้นมาใหม่ และแก้ปัญหา Error ได้
      Navigator.of(context).popUntil((route) => route.isFirst);
      return; // จบการทำงานสำหรับปุ่มหน้าแรก
    }

    // การเปลี่ยนหน้าสำหรับปุ่มอื่นๆ ยังคงเหมือนเดิม
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Myaccount()),
      );
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
            barcode: '',
          ),
        );

        if (matching.name != 'ไม่พบสินค้า') {
          // 🔊 เล่นเสียง beep เมื่อพบสินค้า
          await _audioPlayer.play(AssetSource('beep-313342.mp3'));

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SalePage(
                initialBarcode: result,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("ไม่พบสินค้าด้วยบาร์โค้ดนี้")),
          );
        }
      }
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BillSale_Page()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SupplierListPage()),
      );
    } else {
      onTap(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor:
          const Color.fromARGB(230, 0, 0, 0), // เปลี่ยนสีพื้นหลังของแถบบาร์
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedItemColor: const Color.fromARGB(255, 235, 157, 40),
      unselectedItemColor: const Color.fromARGB(255, 228, 221, 221),
      elevation: 0, // ลดเงาของ BottomNavigationBar
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
