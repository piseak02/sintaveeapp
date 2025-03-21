import 'package:flutter/material.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';
import 'package:sintaveeapp/Product/EditProduct.dart';
import 'package:sintaveeapp/Product/add_Product.dart';
import 'package:sintaveeapp/Product/list_product.dart';
import 'package:sintaveeapp/Sale_Page/sale_product.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          titleSpacing: 10,
          toolbarHeight: 70,
          centerTitle: false, //  ทำให้ title อยู่ชิดซ้าย
          title: Row(
            children: [
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
                        color: const Color.fromARGB(255, 7, 0, 0)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "ภิเษก",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 2, 0, 0)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),

          actions: [
            IconButton(
              icon: Icon(Icons.notifications),
              color: Colors.black,
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity, //  กำหนดให้กว้างเต็มหน้าจอ
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/po1.png"), //  ใช้รูปพื้นหลัง
            fit: BoxFit.cover, // ✅ ปรับให้รูปเต็มจอ
            alignment: Alignment.center, // ✅ ปรับตำแหน่งให้กึ่งกลาง
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, //  จัดให้เมนูชิดซ้าย
          children: [
            SizedBox(height: 30), //  เพิ่มระยะห่างด้านบน
            ///Spacer(),  //ทำให้ปุ่มทางลัดอยู่ด้านล่างคำสั่งนี้***
            Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        alignment: WrapAlignment.start,
        spacing: 20,
        runSpacing: 15,
        children: [
          _buildShortcut(icon: Icons.add, title: "เพิ่มรายการ", context: context),
          _buildShortcut(icon: Icons.edit, title: "แก้ไขรายการ", context: context),
          _buildShortcut(icon: Icons.assignment, title: "แสดงรายการ", context: context),
          _buildShortcut(icon: Icons.priority_high, title: "สินค้าใกล้หมดอายุ", context: context),
          _buildShortcut(icon: Icons.price_change, title: "แก้ไขราคา", context: context),
          _buildShortcut(icon: Icons.production_quantity_limits_sharp, title: "เพิ่มสต็อก", context: context),
          _buildShortcut(icon: Icons.barcode_reader, title: "คำนวนราคา", context: context),
        ],
      ),
    ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }

    Widget _buildShortcut({required IconData icon, required String title, required BuildContext context}) {
    Map<String, Widget> routes = {
      "แก้ไขรายการ": EditProduct(),
      "เพิ่มรายการ": MyAddProduct(),
      "แสดงรายการ": List_Product(),
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
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(185, 15, 10, 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 28, color: const Color.fromARGB(255, 243, 242, 242)),
            ),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
