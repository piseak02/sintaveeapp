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
                  size: 28,
                  color: const Color.fromARGB(255, 37, 39, 39),
                ),
                SizedBox(width: 20),
                Text(
                  "แสดงชื่อผู้ใช้",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),

            actions: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {},
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/ipad.jpg"), // ✅ ใช้รูปพื้นหลัง
              fit: BoxFit.cover, // ✅ ปรับให้รูปเต็มจอ
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "เพิ่มจำนวน",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  number.toString(),
                  style: TextStyle(
                    fontSize: 60,
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor:
              Color.fromARGB(240, 51, 51, 47), // ✅ เปลี่ยนสีพื้นหลังของแถบบาร์
          selectedItemColor: const Color.fromARGB(255, 235, 157, 40),
          unselectedItemColor: const Color.fromARGB(255, 228, 221, 221),
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
                icon: Icon(
                  Icons.receipt,
                ),
                label: "บิลลูกค้า"),
            BottomNavigationBarItem(
                icon: Icon(
                  Icons.business,
                ),
                label: "บิลซัพพายเออร์"),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              number++;
            });
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
