import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'database/user_model.dart';
import 'HomepageApp/auth_wrapper.dart';
import 'database/product_model.dart';
import 'database/category_model.dart';
import 'database/bill_model.dart';
import 'database/lot_model.dart';
import 'database/supplier_model.dart';
import 'database/supplier_name_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ส่วนของการตั้งค่า Hive Path ยังคงเหมือนเดิม
  final Directory supportDir = await getApplicationSupportDirectory();
  final String hivePath = '${supportDir.path}/hive_data';
  await Directory(hivePath).create(recursive: true);
  await Hive.initFlutter(hivePath);

  // ส่วนของการลงทะเบียน Adapter ทั้งหมด ยังคงเหมือนเดิม
  if (!Hive.isAdapterRegistered(ProductModelAdapter().typeId)) {
    Hive.registerAdapter(ProductModelAdapter());
  }
  if (!Hive.isAdapterRegistered(CategoryModelAdapter().typeId)) {
    Hive.registerAdapter(CategoryModelAdapter());
  }
  if (!Hive.isAdapterRegistered(BillItemAdapter().typeId)) {
    Hive.registerAdapter(BillItemAdapter());
  }
  if (!Hive.isAdapterRegistered(BillModelAdapter().typeId)) {
    Hive.registerAdapter(BillModelAdapter());
  }
  if (!Hive.isAdapterRegistered(LotModelAdapter().typeId)) {
    Hive.registerAdapter(LotModelAdapter());
  }
  if (!Hive.isAdapterRegistered(SupplierModelAdapter().typeId)) {
    Hive.registerAdapter(SupplierModelAdapter());
  }
  if (!Hive.isAdapterRegistered(SupplierNameModelAdapter().typeId)) {
    Hive.registerAdapter(SupplierNameModelAdapter());
  }
  if (!Hive.isAdapterRegistered(UserModelAdapter().typeId)) {
    Hive.registerAdapter(UserModelAdapter());
  }

  // --- จุดที่แก้ไข ---
  // เปิดเฉพาะ Box ที่จำเป็นสำหรับหน้าตรวจสอบการล็อกอินเท่านั้น
  // เพื่อให้แอปเริ่มต้นได้เร็วขึ้นและไม่ค้าง
  if (!Hive.isBoxOpen('users')) {
    await Hive.openBox<UserModel>('users');
  }

  // Box อื่นๆ จะถูกย้ายไปเปิดในหน้าที่ต้องการใช้งานแทน
  // เช่น 'lots', 'products' จะไปเปิดในหน้า MyHomepage

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
