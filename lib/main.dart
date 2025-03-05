import 'package:flutter/material.dart';
// import 'HomepageApp/my_homepage.dart';
import 'package:sintaveeapp/Product/add_Product.dart';

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
      home: Myaddproduct(),
    );
  }
}
