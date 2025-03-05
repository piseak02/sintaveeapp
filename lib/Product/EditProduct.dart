import 'package:flutter/material.dart';

class EditProduct extends StatelessWidget {
  const EditProduct({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("แก้ไขสินค้า"),
        backgroundColor: Colors.orange,
      ),
      body: Center(child: Text("แก้ไขสินค้า", style: TextStyle(fontSize: 20),),
      ),
    );
  }
}