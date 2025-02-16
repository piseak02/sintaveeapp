import 'package:flutter/material.dart';

void main() {
  runApp(Myapp());
}

///สร้างวิตเจ็ต
class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.orange,
      ),
      title: "หน้าแรก",
      home: MyHomepaga(),
    );
  }
}

class MyHomepaga extends StatefulWidget {
  const MyHomepaga({super.key});

  @override
  State<MyHomepaga> createState() => _MyHomepagaState();
}

class _MyHomepagaState extends State<MyHomepaga> {
  int number = 0;

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
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/po1.png"), // ✅ ใช้รูปพื้นหลัง
              fit: BoxFit.cover, // ✅ ปรับให้รูปเต็มจอ
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 30,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(200),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.insert_drive_file),
                        Text("เพิ่มรายการ"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color.fromARGB(
              199, 0, 0, 0), // ✅ เปลี่ยนสีพื้นหลังของแถบบาร์
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: const Color.fromARGB(255, 235, 157, 40),
          unselectedItemColor: const Color.fromARGB(255, 228, 221, 221),
          elevation: 0, // ✅ ลดเงาของ BottomNavigationBar
          items: [
            BottomNavigationBarItem(
                icon: Icon(
                  Icons.home,
                ),
                label: "หน้าแรก"),
            BottomNavigationBarItem(
                icon: Icon(
                  Icons.credit_card,
                ),
                label: "บัญชี"),
            BottomNavigationBarItem(
                icon: Icon(
                  Icons.menu,
                ),
                label: "เมนูหลัก"),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long), label: "บิลลูกค้า"),
            BottomNavigationBarItem(
                icon: Icon(Icons.description), label: "บิลซัพพายเออร์"),
          ],
        ),
      ),
    );
  }
}
