// lib/HomepageApp/my_homepage.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'package:sintaveeapp/services/auth_service.dart';
import 'package:sintaveeapp/Bill_Page/bill_settings_page.dart'; //  <-- 1. เพิ่ม import นี้
import 'package:sintaveeapp/StandaloneBarcode/standalone_barcode_page.dart'; // <-- เพิ่ม import

class MyHomepage extends StatefulWidget {
  final VoidCallback onLogout;

  const MyHomepage({
    super.key,
    required this.onLogout,
  });

  @override
  State<MyHomepage> createState() => _MyHomepagaState();
}

class _MyHomepagaState extends State<MyHomepage> {
  String _username = ''; // ✅ 1. ตัวแปรสำหรับเก็บชื่อผู้ใช้
  bool _isDialogShowing = false;
  final AuthService _authService = AuthService();
  late Future<void> _initHiveBoxesFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initHiveBoxesFuture = _openRequiredBoxes();
    _loadUsername(); // ✅ 3. เรียกใช้ฟังก์ชันโหลดชื่อ
  }

  /// ✅ 2. ฟังก์ชันสำหรับโหลดชื่อผู้ใช้จาก SharedPreferences
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? 'ผู้ใช้';
      });
    }
  }

  /// --- ฟังก์ชันสำหรับตรวจสอบ "กฎ 30 วัน" ในเครื่อง ---
  Future<void> _checkThirtyDayRuleAndLogout() async {
    if (!mounted || _isDialogShowing) return;

    final prefs = await SharedPreferences.getInstance();
    final lastLoginTimestamp = prefs.getString('last_login_timestamp');

    if (lastLoginTimestamp == null) {
      _handleLogout("ข้อมูลการเข้าสู่ระบบไม่สมบูรณ์ กรุณาล็อกอินใหม่");
      return;
    }

    final lastLoginDate = DateTime.parse(lastLoginTimestamp);
    final difference = DateTime.now().toUtc().difference(lastLoginDate);

    ////////difference.inMinutes >= 1  เปลี่ยนเป็นนาทีใช้คำสั่งนี้
    /// difference.inDays >= 30 คำสั่งนี้ เปลี่ยนเป็นวัน
    if (difference.inDays >= 30) {
      _showReLoginDialog("ซีซั่นของคุณหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง");
    }
  }

  /// ฟังก์ชันสำหรับแสดง Pop-up
  void _showReLoginDialog(String message) {
    if (_isDialogShowing) return;
    setState(() => _isDialogShowing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("แจ้งเตือน"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('ตกลง'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    ).then((_) {
      _handleLogout(null); // Logout โดยไม่ต้องแสดงข้อความซ้ำ
    });
  }

  /// ฟังก์ชันสำหรับจัดการการ Logout
  Future<void> _handleLogout(String? message) async {
    await _authService.logout();
    if (mounted && message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.blue),
      );
    }
    widget.onLogout();
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
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(
                      'เกิดข้อผิดพลาดในการโหลดข้อมูล: ${snapshot.error}')));
        }
        return _buildHomePageContent();
      },
    );
  }

  Widget _buildHomePageContent() {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 10,
        toolbarHeight: 70,
        centerTitle: false,
        title: Row(
          children: [
            const Icon(Icons.person, size: 40, color: Colors.black),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ยินดีต้อนรับ",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                // ✅ 4. นำชื่อผู้ใช้ที่โหลดมาแสดงผล
                Text(_username,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              ],
            ),
          ],
        ),
        actions: [
          ////ปุุ่มแจ้งเตือน
          // *******************************
          // IconButton(
          // icon: const Icon(Icons.notifications),
          //color: Colors.black,
          // onPressed: () {},
          //  ),
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
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      TextButton(
                        child: const Text('ยืนยัน'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _handleLogout(null);
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
        // ✅ 5. แก้ไขให้พื้นหลังกลับมาแสดงผล
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/wallpaper.jpg"),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        // ✅ 6. แก้ไขให้ปุ่มอยู่ตรงกลาง
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              alignment: WrapAlignment.center,
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
                _buildShortcut(
                    icon: Icons.settings,
                    title: "ตั้งค่าใบเสร็จ",
                    context: context),
                _buildShortcut(
                    icon: Icons.label_important_outline,
                    title: "เครื่องมือสร้างฉลาก",
                    context: context),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
        onHomeButtonPressed: _checkThirtyDayRuleAndLogout,
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
      "แก้ไขรายการ": const EditProduct(),
      "เพิ่มรายการ": const MyAddProduct(),
      "แสดงรายการ": const List_Product(),
      "แก้ไขราคา": const EditPriceProduct(),
      "สินค้าใกล้หมดอายุ": const ExpiryRankingPage(),
      "จัดการสต็อก": const EditStockProduct(),
      "คำนวนราคา": const SalePage(),
      "เพิ่มบิล(ซัพพายเออร์)": const add_Supplier(),
      "รับข้อมูล/ส่งออกข้อมูล": const ImportExportPage(),
      "ตั้งค่าใบเสร็จ": const BillSettingsPage(), // <-- 2. เพิ่ม route นี้
      "เครื่องมือสร้างฉลาก": const StandaloneBarcodePage(), //
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
