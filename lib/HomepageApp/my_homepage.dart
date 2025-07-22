// lib/HomepageApp/my_homepage.dart

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';
import 'package:sintaveeapp/Database/bill_model.dart';
import 'package:sintaveeapp/Database/category_model.dart';
import 'package:sintaveeapp/Database/lot_model.dart';
import 'package:sintaveeapp/Database/product_model.dart';
import 'package:sintaveeapp/Database/supplier_model.dart';
import 'package:sintaveeapp/Database/supplier_name_model.dart';
import 'package:sintaveeapp/Import_Export_File/import_export_file.dart';
import 'package:sintaveeapp/Product/EditProduct.dart';
import 'package:sintaveeapp/Product/Edit_Price_Product.dart';
import 'package:sintaveeapp/Product/Edit_Stock_Product.dart';
import 'package:sintaveeapp/Product/add_Product.dart';
import 'package:sintaveeapp/Product/list_exp_date_product.dart';
import 'package:sintaveeapp/Product/list_product.dart';
import 'package:sintaveeapp/Sale_Page/sale_product.dart';
import 'package:sintaveeapp/Supplier/add_supplier.dart';

class MyHomepage extends StatefulWidget {
  final VoidCallback onLogout;

  // ✅ เอา onRefresh ออกไปแล้ว
  const MyHomepage({
    super.key,
    required this.onLogout,
  });

  @override
  State<MyHomepage> createState() => _MyHomepagaState();
}

class _MyHomepagaState extends State<MyHomepage> {
  late Future<void> _initHiveBoxesFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initHiveBoxesFuture = _openRequiredBoxes();
  }

  Future<void> _openRequiredBoxes() async {
    await Future.wait([
      if (!Hive.isBoxOpen('lots')) Hive.openBox<LotModel>('lots'),
      if (!Hive.isBoxOpen('products')) Hive.openBox<ProductModel>('products'),
      if (!Hive.isBoxOpen('categories'))
        Hive.openBox<CategoryModel>('categories'),
      if (!Hive.isBoxOpen('bills')) Hive.openBox<BillModel>('bills'),
      if (!Hive.isBoxOpen('suppliers'))
        Hive.openBox<SupplierModel>('suppliers'),
      if (!Hive.isBoxOpen('supplierNames'))
        Hive.openBox<SupplierNameModel>('supplierNames'),
    ]);
  }

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initHiveBoxesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: ${snapshot.error}'),
            ),
          );
        }
        return _buildHomePageContent();
      },
    );
  }

  Widget _buildHomePageContent() {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 10,
        toolbarHeight: 70,
        centerTitle: false,
        title: Row(
          children: const [
            Icon(Icons.person, size: 40, color: Colors.black),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ยินดีต้อนรับ",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                Text("ภิเษก",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              ],
            ),
          ],
        ),
        actions: [
          // ✅ เอาปุ่ม Refresh ออกไปแล้ว
          IconButton(
            icon: const Icon(Icons.notifications),
            color: Colors.black,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            color: Colors.black,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('ยืนยันการออกจากระบบ'),
                    content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('ยกเลิก'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('ยืนยัน'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          widget.onLogout();
                        },
                      ),
                    ],
                  );
                },
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
                  title: "จัดการสต็อก",
                  context: context),
              _buildShortcut(
                  icon: Icons.barcode_reader,
                  title: "คำนวนราคา",
                  context: context),
              _buildShortcut(
                  icon: Icons.business,
                  title: "เพิ่มบิล(ซัพพายเออร์)",
                  context: context),
              _buildShortcut(
                  icon: Icons.file_upload,
                  title: "รับข้อมูล/ส่งออกข้อมูล",
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

  Widget _buildShortcut({
    required IconData icon,
    required String title,
    required BuildContext context,
  }) {
    int badgeCount = 0;
    if (title == "สินค้าใกล้หมดอายุ") {
      badgeCount = _getNearExpiryCount();
    }

    Map<String, Widget> routes = {
      "แก้ไขรายการ": EditProduct(),
      "เพิ่มรายการ": MyAddProduct(),
      "แสดงรายการ": List_Product(),
      "แก้ไขราคา": EditPriceProduct(),
      "สินค้าใกล้หมดอายุ": ExpiryRankingPage(),
      "จัดการสต็อก": EditStockProduct(),
      "คำนวนราคา": SalePage(),
      "เพิ่มบิล(ซัพพายเออร์)": add_Supplier(),
      "รับข้อมูล/ส่งออกข้อมูล": ImportExportPage(),
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
              clipBehavior: Clip.none,
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
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                      child: Center(
                        child: Text(
                          badgeCount.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
