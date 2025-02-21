import 'package:flutter/material.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';

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
    return SafeArea(
      child: Scaffold(
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
                  alignment: WrapAlignment.start, //  จัดให้อยู่ตรงกลาง
                  spacing: 20, //  ระยะห่างระหว่างไอคอนในแถวเดียวกัน
                  runSpacing: 15, //  ระยะห่างระหว่างแถว
                  children: [
                    _buildShortcut(icon: Icons.add, title: "เพิ่มรายการ"),
                    _buildShortcut(icon: Icons.edit, title: "แก้ไขรายการ"),
                    _buildShortcut(icon: Icons.assignment, title: "แสดงรายการ"),
                    _buildShortcut(
                        icon: Icons.priority_high, title: "สินค้าใกล้หมดอายุ"),
                    _buildShortcut(
                        icon: Icons.price_change, title: "แก้ไขราคา"),
                    _buildShortcut(
                        icon: Icons.production_quantity_limits_sharp,
                        title: "เพิ่มสต็อก"),
                    _buildShortcut(
                        icon: Icons.barcode_reader, title: "คำนวนราคา"),
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
      ),
    );
  }

  Widget _buildShortcut({required IconData icon, required String title}) {
    return SizedBox(
      width: 100, //  กำหนดขนาดปุ่มให้เท่ากัน
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(185, 15, 10, 1), //  สีพื้นหลังของปุ่ม
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                size: 28, color: const Color.fromARGB(255, 243, 242, 242)),
          ),
          SizedBox(height: 8), //  ระยะห่างระหว่างไอคอนกับข้อความ
          Text(
            title,
            textAlign: TextAlign.center, //  จัดให้อยู่ตรงกลาง
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
