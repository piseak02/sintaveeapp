import 'package:flutter/material.dart';
import 'package:sintaveeapp/widgets/castom_shapes/Containers/primary_header_container.dart';
import 'package:sintaveeapp/Bottoom_Navbar/bottom_navbar.dart';

class Myaddproduct extends StatefulWidget {
  const Myaddproduct({super.key});

  @override
  State<Myaddproduct> createState() => _MyaddproductState();
}

class _MyaddproductState extends State<Myaddproduct> {
  int _selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            TPrimaryHeaderContainer(
              child: Column(
                children: [
                  Text("xxxxx"),
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
}
