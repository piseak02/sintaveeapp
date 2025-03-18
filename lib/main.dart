// import 'package:flutter/material.dart';
// // import 'HomepageApp/my_homepage.dart';
// import 'package:sintaveeapp/Product/add_product.dart';

// void main() {
//   runApp(Myapp());
// }

// ///สร้างวิตเจ็ต
// class Myapp extends StatelessWidget {
//   const Myapp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData(
//         primaryColor: Colors.orange,
//       ),
//       title: "หน้าแรก",
//       home: MyAddProduct(),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'Database/product_model.dart';
import 'Database/category_model.dart';
import 'Product/add_product.dart';
import 'HomepageApp/my_homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // เริ่มต้น Hive และเปิดฐานข้อมูล
  await Hive.initFlutter();
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());

  await Hive.openBox<ProductModel>('products');
  await Hive.openBox<CategoryModel>('categories');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      title: "หน้าแรก",
      home: MyHomepage(),
    );
  }
}
