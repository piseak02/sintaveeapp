import 'package:flutter/material.dart';

class AppbarAddProduct extends StatelessWidget implements PreferredSizeWidget {
  const AppbarAddProduct({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text("เพิ่มรายการสินค้า"),
      backgroundColor: Colors.orange,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}/////