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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart'; // ใช้หา path ที่ Flutter เขียนไฟล์ได้
import 'package:sintaveeapp/Database/supplier_model.dart';
import 'Database/product_model.dart';
import 'Database/category_model.dart';
import 'Database/bill_model.dart';
import 'Database/lot_model.dart';
import 'Database/supplier_name_model.dart';
import 'Database/printer_connection_model.dart';
import 'HomepageApp/my_homepage.dart';

Future<String> getDownloadsPath() async {
  Directory? downloadsDir;

  if (Platform.isAndroid) {
    Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      downloadsDir = Directory(
          '${externalDir.path}/data'); // บันทึกใน Android/data/<package_name>/files/data
    }
  } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    downloadsDir =
        Directory('${Platform.environment['USERPROFILE']}\\Downloads');
  }

  if (downloadsDir != null && await downloadsDir.exists()) {
    return downloadsDir.path;
  } else {
    // fallback ไปใช้โฟลเดอร์ที่ Flutter รองรับ
    return (await getApplicationDocumentsDirectory()).path;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ใช้ Downloads Path
  String hivePath = await getDownloadsPath();
  await Hive.initFlutter(hivePath); // ให้ Hive ใช้ Path ใน Downloads

  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(BillItemAdapter());
  Hive.registerAdapter(BillModelAdapter());
  Hive.registerAdapter(LotModelAdapter());
  Hive.registerAdapter(SupplierModelAdapter());
  Hive.registerAdapter(SupplierNameModelAdapter());
  Hive.registerAdapter(PrinterConnectionModelAdapter());

  await Hive.openBox<LotModel>('lots');
  await Hive.openBox<ProductModel>('products');
  await Hive.openBox<CategoryModel>('categories');
  await Hive.openBox<BillModel>('bills');
  await Hive.openBox<SupplierModel>('suppliers');
  await Hive.openBox<SupplierNameModel>('supplierNames');
  await Hive.openBox<PrinterConnectionModel>('printerBox');

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
      // home: MyHomepage(),
    );
  }
}
