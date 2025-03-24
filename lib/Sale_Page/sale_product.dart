import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../Database/product_model.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Database/bill_model.dart';
import '../Database/lot_model.dart';
import '../Bill_Page/bill_detail_page.dart';

/// Model สำหรับรายการขาย (SaleItem)
class SaleItem {
  final ProductModel product;
  int saleQuantity;

  SaleItem({required this.product, required this.saleQuantity});
}

class ProductSearchDelegate extends SearchDelegate<ProductModel?> {
  final Box<ProductModel> productBox;

  ProductSearchDelegate(this.productBox);

  @override
  String get searchFieldLabel => "ค้นหาสินค้า";
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = "";
        },
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(child: Text("ยังไม่ได้ค้นหา"));
    }
    final results = productBox.values
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ListTile(
          title: Text(product.name),
          subtitle: Text('ราคา: ${product.retailPrice}'),
          onTap: () {
            close(context, product);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(child: Text("ยังไม่ได้ค้นหา"));
    }
    final suggestions = productBox.values
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final product = suggestions[index];
        return ListTile(
          title: Text(product.name),
          subtitle: Text('ราคา: ${product.retailPrice}'),
          onTap: () {
            close(context, product);
          },
        );
      },
    );
  }
}

class SalePage extends StatefulWidget {
  final String? initialBarcode; // สามารถส่ง barcode มาเริ่มต้นได้

  const SalePage({Key? key, this.initialBarcode}) : super(key: key);

  @override
  _SalePageState createState() => _SalePageState();
}

class _SalePageState extends State<SalePage> {
  late Box<ProductModel> _productBox;
  List<SaleItem> _saleItems = [];
  late Box<BillModel> _billBox;
  late Box<LotModel> _lotBox;

  // Toggle flag สำหรับคำนวนราคาปลีก/ส่ง
  bool _useWholesale = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _productBox = Hive.box<ProductModel>('products');
    _billBox = Hive.box<BillModel>('bills');
    _lotBox = Hive.box<LotModel>('lots');

    if (widget.initialBarcode != null) {
      _addProductToSale(widget.initialBarcode!);
    }
  }

  /// คำนวณยอดรวมโดยใช้ราคาที่เลือก (ปลีกหรือส่ง)
  double get _grandTotal {
    double sum = 0.0;
    for (var item in _saleItems) {
      double price = _useWholesale
          ? item.product.wholesalePrice
          : item.product.retailPrice;
      sum += price * item.saleQuantity;
    }
    return sum;
  }

  /// ขออนุญาตใช้งานกล้อง
  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("จำเป็นต้องให้สิทธิ์ใช้งานกล้อง")),
      );
    }
  }

  /// ฟังก์ชันสแกนบาร์โค้ด
  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
          builder: (context) => const SimpleBarcodeScannerPage()),
    );

    if (result != null && result != '-1') {
      _addProductToSale(result);
    }
  }

  /// ฟังก์ชันค้นหาสินค้า
  Future<void> _searchProduct() async {
    final selectedProduct = await showSearch<ProductModel?>(
      context: context,
      delegate: ProductSearchDelegate(_productBox),
    );

    if (selectedProduct != null) {
      _addProductToSale(selectedProduct.barcode ?? '');
    }
  }

  /// เพิ่มสินค้าในรายการขายโดยใช้ barcode
  void _addProductToSale(String barcode) {
    final matchingProducts =
        _productBox.values.where((p) => p.barcode == barcode);
    if (matchingProducts.isNotEmpty) {
      final product = matchingProducts.first;
      int index =
          _saleItems.indexWhere((item) => item.product.barcode == barcode);
      setState(() {
        if (index != -1) {
          _saleItems[index].saleQuantity++;
        } else {
          _saleItems.add(SaleItem(product: product, saleQuantity: 1));
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่พบสินค้าด้วยบาร์โค้ดนี้")),
      );
    }
  }

  /// สร้าง Card สำหรับแต่ละรายการขาย
  Widget _buildSaleItemCard(SaleItem saleItem, int index) {
    double price = _useWholesale
        ? saleItem.product.wholesalePrice
        : saleItem.product.retailPrice;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แถวแรก: ชื่อสินค้าและราคารวมต่อรายการ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  saleItem.product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'ราคารวม: ${price * saleItem.saleQuantity}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // แถวที่สอง: ราคาต่อหน่วยและปุ่มควบคุมจำนวนสินค้า
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_useWholesale
                    ? "ราคาส่ง: ${saleItem.product.wholesalePrice}"
                    : "ราคาปลีก: ${saleItem.product.retailPrice}"),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          if (saleItem.saleQuantity > 1) {
                            saleItem.saleQuantity--;
                          }
                        });
                      },
                    ),
                    Text("${saleItem.saleQuantity}"),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          saleItem.saleQuantity++;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper function สำหรับตัดสต็อกของสินค้าตาม saleItem (FIFO)
  Future<void> _deductStock() async {
    for (var saleItem in _saleItems) {
      int quantityToDeduct = saleItem.saleQuantity;
      // ดึงรายการล็อตสำหรับสินค้านี้จาก lotBox แบบ key-value pair
      final lotEntries = _lotBox.toMap().entries
          .where((entry) => (entry.value as LotModel).productId == saleItem.product.id)
          .toList();
      // เรียงล็อตตามวันหมดอายุจากน้อยไปมาก (FIFO)
      lotEntries.sort((a, b) {
        LotModel lotA = a.value;
        LotModel lotB = b.value;
        return lotA.expiryDate.compareTo(lotB.expiryDate);
      });
      for (var entry in lotEntries) {
        if (quantityToDeduct <= 0) break;
        LotModel lot = entry.value;
        if (lot.quantity > quantityToDeduct) {
          // ถ้าล็อตมีจำนวนมากพอ แก้ไขจำนวนในล็อตนั้น
          LotModel updatedLot = LotModel(
            lotId: lot.lotId,
            productId: lot.productId,
            quantity: lot.quantity - quantityToDeduct,
            expiryDate: lot.expiryDate,
            recordDate: lot.recordDate,
            note: lot.note,
          );
          await _lotBox.put(entry.key, updatedLot);
          quantityToDeduct = 0;
        } else {
          // ถ้าล็อตมีจำนวนน้อยกว่าหรือเท่ากับที่ต้องการตัด
          quantityToDeduct -= lot.quantity;
          await _lotBox.delete(entry.key);
        }
      }
    }
  }

  /// Popup รับเงินและชำระเงิน (หลังจากชำระเงิน จะเปลี่ยนหน้าไปยัง BillDetailPage)
  void _showPaymentDialog() {
    final moneyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ชำระเงิน"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("ยอดรวมสุทธิ: ${_grandTotal.toStringAsFixed(2)} บาท"),
            const SizedBox(height: 16),
            TextField(
              controller: moneyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "จำนวนเงินที่รับ",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () async {
              final double? pay = double.tryParse(moneyController.text);
              if (pay == null || pay.isNaN) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("กรุณากรอกจำนวนเงินให้ถูกต้อง")),
                );
              } else if (pay < _grandTotal) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ยอดเงินไม่เพียงพอ")),
                );
              } else {
                final change = pay - _grandTotal;
                Navigator.pop(context); // ปิด Dialog

                // สร้างรายการ BillItem จาก _saleItems
                List<BillItem> billItems = _saleItems.map((saleItem) {
                  double price = _useWholesale
                      ? saleItem.product.wholesalePrice
                      : saleItem.product.retailPrice;
                  return BillItem(
                    productName: saleItem.product.name,
                    price: price,
                    quantity: saleItem.saleQuantity,
                    discount: 0.0,
                  );
                }).toList();

                // สร้าง BillModel ใหม่
                final newBill = BillModel(
                  billId: "BILL-${DateTime.now().millisecondsSinceEpoch}",
                  billDate: DateTime.now(),
                  items: billItems,
                  totalDiscount: 0.0,
                  netTotal: _grandTotal,
                  moneyReceived: pay,
                  change: change,
                );

                // บันทึก BillModel ลง Hive
                await _billBox.add(newBill);

                // ตัดสต็อกสินค้าออกจาก LotModel ตามยอดขาย (FIFO)
                await _deductStock();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "บันทึกบิลแล้ว\nยอดชำระเงิน: ${_grandTotal.toStringAsFixed(2)}\nเงินทอน: ${change.toStringAsFixed(2)}",
                    ),
                  ),
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BillDetailPage(bill: newBill),
                  ),
                );

                // เคลียร์รายการขาย
                setState(() {
                  _saleItems.clear();
                });
              }
            },
            child: const Text("ชำระเงิน"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("คำนวนสินค้า - ขายสินค้า"),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          // รายการสินค้า (Sale Items)
          Expanded(
            child: _saleItems.isEmpty
                ? const Center(child: Text("ยังไม่มีรายการขาย"))
                : ListView.builder(
                    itemCount: _saleItems.length,
                    itemBuilder: (context, index) {
                      final item = _saleItems[index];
                      return Dismissible(
                        key: ValueKey(item),
                        direction: DismissDirection.endToStart,
                        background: Container(),
                        secondaryBackground: Container(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete,
                              color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("ยืนยันการลบ"),
                                    content: Text(
                                        "ต้องการลบสินค้า \"${item.product.name}\" หรือไม่?"),
                                    actions: [
                                      TextButton(
                                        child: const Text("ยกเลิก"),
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                      ),
                                      TextButton(
                                        child: const Text("ลบ"),
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  );
                                },
                              ) ??
                              false;
                        },
                        onDismissed: (direction) {
                          setState(() {
                            _saleItems.removeAt(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "ลบ \"${item.product.name}\" เรียบร้อย")),
                          );
                        },
                        child: _buildSaleItemCard(item, index),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text("ราคาปลีก"),
                Switch(
                  value: _useWholesale,
                  onChanged: (value) {
                    setState(() {
                      _useWholesale = value;
                    });
                  },
                ),
                const Text("ราคาส่ง"),
              ],
            ),
          ),
          // แถวแสดงยอดรวมสุทธิ
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ยอดรวมสุทธิ:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${_grandTotal.toStringAsFixed(2)} บาท",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // ปุ่ม "ชำระเงิน"
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _showPaymentDialog,
              child: const Text("ชำระเงิน",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
