import 'package:flutter/material.dart';

void main() {
  runApp(Myapp());
}

///สร้างวิตเจ็ต
class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "หน้าแรก",
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 226, 74, 28)),
          useMaterial3: true),
      home: MyHomepaga(),
    );
  }
}

class MyHomepaga extends StatefulWidget {
  const MyHomepaga({super.key});

  @overridee
  State<MyHomepaga> createState() => _MyHomepagaState();
}

class _MyHomepagaState extends State<MyHomepaga> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        leading: Container(
          padding: EdgeInsets.only(leftSafeArea: 10),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person,
                size: 28,
                color: const Color.fromARGB(255, 37, 39, 39),
              ),
              SizedBox(
                width: 10,
              ),
              Text("แสดงชื่อผู้ใช้",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent)),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("สวัสดีครับ"),
            Text("hello dart"),
            Text("hello flutter"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
      ),
    );
  }
}
