import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sintaveeapp/HomepageApp/auth_wrapper.dart';
import 'package:sintaveeapp/Database/product_model.dart';
import 'package:sintaveeapp/Database/category_model.dart';
import 'package:sintaveeapp/Database/bill_model.dart';
import 'package:sintaveeapp/Database/lot_model.dart';
import 'package:sintaveeapp/Database/supplier_model.dart';
import 'package:sintaveeapp/Database/supplier_name_model.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✔️
import 'package:sintaveeapp/StandaloneBarcode/saved_label_model.dart'; // [เพิ่ม] 1. Import SavedLabelModel

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // โหลดข้อมูลวันที่–เดือน สำหรับ locale ไทย
  await initializeDateFormatting('th', null);

  // กำหนดที่เก็บข้อมูล Hive
  final Directory supportDir = await getApplicationSupportDirectory();
  final String hivePath = '${supportDir.path}/hive_data';
  await Directory(hivePath).create(recursive: true);
  await Hive.initFlutter(hivePath);

  // ลงทะเบียน Adapter ของโมเดลทั้งหมด
  Hive.registerAdapter(ProductModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(BillItemAdapter());
  Hive.registerAdapter(BillModelAdapter());
  Hive.registerAdapter(LotModelAdapter());
  Hive.registerAdapter(SupplierModelAdapter());
  Hive.registerAdapter(SupplierNameModelAdapter());
  Hive.registerAdapter(
      SavedLabelModelAdapter()); // [เพิ่ม] 2. ลงทะเบียน SavedLabelModelAdapter

  // เปิด Box ก่อนใช้งาน
  await Hive.openBox<CategoryModel>('categories');
  await Hive.openBox<ProductModel>('products');
  await Hive.openBox<LotModel>('lots');
  await Hive.openBox<SupplierModel>('suppliers');
  await Hive.openBox<SupplierNameModel>('supplier_names');
  await Hive.openBox<BillModel>('bills');
  await Hive.openBox<BillItem>('bill_items');
  await Hive.openBox<SavedLabelModel>(
      'saved_labels'); // [เพิ่ม] 3. เปิดกล่องสำหรับเก็บ "สมุดบันทึกฉลาก"
  await Hive.openBox('settings'); // เปิดกล่องสำหรับเก็บค่า counter ต่างๆ

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sintavee App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
