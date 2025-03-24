import 'package:flutter/material.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';
import 'package:sintaveeapp/Database/log_model.dart';
import 'package:sintaveeapp/Product/EditProduct.dart';
import 'package:sintaveeapp/Product/add_Product.dart';
import 'package:sintaveeapp/Product/list_product.dart';
import 'package:sintaveeapp/Sale_Page/sale_product.dart';
import 'package:sintaveeapp/Product/Edit_Price_Product.dart';
import 'package:sintaveeapp/Product/Edit_Stock_Product.dart';
import 'package:sintaveeapp/Product/list_exp_date_product.dart';
import 'package:sintaveeapp/Log/log_service.dart';
import 'package:hive/hive.dart';
import 'package:sintaveeapp/Database/lot_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MyHomepage extends StatefulWidget {
  const MyHomepage({super.key});

  @override
  State<MyHomepage> createState() => _MyHomepagaState();
}

class _MyHomepagaState extends State<MyHomepage> {
  int _selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// ฟังก์ชันสำหรับคำนวณจำนวนสินค้าที่จะหมดอายุ
  /// โดยนับจาก LotModel ที่เหลือวันหมดอายุ < 60 และยังไม่หมดอายุ
  int _getNearExpiryCount() {
    final lotBox = Hive.box<LotModel>('lots');
    int count = 0;
    for (var lot in lotBox.values) {
      int daysLeft = lot.expiryDate.difference(DateTime.now()).inDays;
      if (daysLeft < 60 && !lot.isExpired) {
        count += lot.quantity;
      }
    }
    return count;
  }

  Widget _buildShortcut({
    required IconData icon,
    required String title,
    required BuildContext context,
  }) {
    // หากเป็น "สินค้าใกล้หมดอายุ" ให้คำนวณ badge count
    int badgeCount = 0;
    if (title == "สินค้าใกล้หมดอายุ") {
      badgeCount = _getNearExpiryCount();
    }

    Map<String, Widget> routes = {
      "แก้ไขรายการ": EditProduct(),
      "เพิ่มรายการ": MyAddProduct(),
      "แสดงรายการ": List_Product(),
      "แก้ไขราคา": EditPriceProduct(),
      "สินค้าใกล้หมดอายุ": ExpiryRankingPage(), // ตัวอย่างหน้าสินค้าใกล้หมดอายุ
      "เพิ่มสต็อก": EditStockProduct(),
      "คำนวนราคา": SalePage(),
    };

    return GestureDetector(
      onTap: () {
        if (routes.containsKey(title)) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => routes[title]!),
          );
        }
      },
      child: SizedBox(
        width: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(185, 15, 10, 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon,
                      size: 28,
                      color: const Color.fromARGB(255, 243, 242, 242)),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        toolbarHeight: 70,
        centerTitle: false,
        title: Row(
          children: const [
            Icon(
              Icons.person,
              size: 40,
              color: Colors.black,
            ),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ยินดีต้อนรับ",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "ภิเษก",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
        actions: [
  ValueListenableBuilder(
    valueListenable: Hive.box<LogModel>('logs').listenable(),
    builder: (context, Box<LogModel> logBox, _) {
      final logCount = logBox.values.length;
      return GestureDetector(
        onTap: () {
          // นำทางไปยังหน้า NotificationsPage ที่แสดง log ทั้งหมด
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NotificationsPage()),
          );
        },
        child: Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              color: Colors.black,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsPage()),
                );
              },
            ),
            if (logCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      logCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  ),
],

      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/po1.png"),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            alignment: WrapAlignment.start,
            spacing: 20,
            runSpacing: 15,
            children: [
              _buildShortcut(
                  icon: Icons.add, title: "เพิ่มรายการ", context: context),
              _buildShortcut(
                  icon: Icons.edit, title: "แก้ไขรายการ", context: context),
              _buildShortcut(
                  icon: Icons.assignment,
                  title: "แสดงรายการ",
                  context: context),
              _buildShortcut(
                  icon: Icons.priority_high,
                  title: "สินค้าใกล้หมดอายุ",
                  context: context),
              _buildShortcut(
                  icon: Icons.price_change,
                  title: "แก้ไขราคา",
                  context: context),
              _buildShortcut(
                  icon: Icons.production_quantity_limits_sharp,
                  title: "เพิ่มสต็อก",
                  context: context),
              _buildShortcut(
                  icon: Icons.barcode_reader,
                  title: "คำนวนราคา",
                  context: context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}
