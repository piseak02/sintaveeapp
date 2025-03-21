import 'package:flutter/material.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';

class Myaccount extends StatefulWidget {
  const Myaccount({super.key});

  @override
  State<Myaccount> createState() => _MyaccountState();
}

class _MyaccountState extends State<Myaccount> {
  int _selectedIndex = 1;

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          /// ส่วนหัวของแอพ
          Stack(
            alignment: Alignment.topCenter,
            children: [
              ////พื้นหลังส่วนบน
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/po1.png"), fit: BoxFit.cover),
                  color: Colors.orange,
                ),
              ),

              ///ไอคอนโปรไฟล์
              Positioned(
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),

              ////ข้อความวันที่และเวลาและชื่อ
              Positioned(
                top: 80,
                child: Column(
                  children: [
                    Text(
                      "บัญชีทั้งหมด",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "27 ก.พ 2568 15.13",
                      style: TextStyle(
                          fontSize: 14,
                          color: const Color.fromARGB(255, 12, 0, 0)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "บัญชีทั้งหมด",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                Text("สรุปข้อมูลบัญชี"),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}
