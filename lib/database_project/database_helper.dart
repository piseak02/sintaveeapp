import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // สร้าง Singleton สำหรับ DatabaseHelper
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Factory Constructor (เรียกใช้อันเดียวกันทุกครั้ง)
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Getter สำหรับ database
  Future<Database> get database async {
    // ถ้ามีฐานข้อมูลแล้ว คืนค่าทันที
    if (_database != null) return _database!;
    // ถ้ายังไม่มี ให้เรียกฟังก์ชัน _initDatabase
    _database = await _initDatabase();
    return _database!;
  }

  // ฟังก์ชันสร้างและเปิดฐานข้อมูล
  Future<Database> _initDatabase() async {
    // ได้ path ของ devices (Android/iOS/others)
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'my_products.db');

    // เปิดฐานข้อมูล
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        // สร้างตาราง add_product เช่น ชื่อสินค้า ราคา etc.
        return db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            name TEXT,
            price REAL,
            quantity INTEGER,
            expiryDate TEXT
          )
        ''');
      },
    );
  }

  // ฟังก์ชันเพิ่มข้อมูลสินค้า
  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.insert('products', product);
  }

  // ฟังก์ชันดึงข้อมูลสินค้าทั้งหมด
  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query('products', orderBy: 'id DESC');
  }

  // ฟังก์ชันลบสินค้าตาม ID
  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ฟังก์ชันอัปเดตข้อมูลสินค้า (ถ้าต้องการ)
  Future<int> updateProduct(Map<String, dynamic> product, int id) async {
    final db = await database;
    return await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
