import 'package:flutter/material.dart';
import 'package:sintaveeapp/AccountPageApp/account_page.dart';
import '../HomepageApp/my_homepage.dart';

class BottomNavbar extends StatelessWidget {
  const BottomNavbar(
      {super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final Function(int) onTap;

  void _handleNavigation(int index, BuildContext context) {
    if (index == 0) {
      // นำทางไปหน้า MyHomepage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomepage()),
      );
    } else if (index == 1) {
      // นำทางไปหน้า Myaccount
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Myaccount()),
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
          const Color.fromARGB(230, 0, 0, 0), //  เปลี่ยนสีพื้นหลังของแถบบาร์
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedItemColor: const Color.fromARGB(255, 235, 157, 40),
      unselectedItemColor: const Color.fromARGB(255, 228, 221, 221),
      elevation: 0, //  ลดเงาของ BottomNavigationBar
      currentIndex: currentIndex,
      onTap: (index) => _handleNavigation(index, context),
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
    );
  }
}
//
