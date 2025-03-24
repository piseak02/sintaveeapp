import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../database/log_model.dart';
import 'package:flutter/material.dart';

class LogService {
  static Future<void> addLog(String message, String eventType) async {
    // สร้าง logId โดยใช้ timestamp
    final logId = "LOG-${DateTime.now().millisecondsSinceEpoch}";
    final log = LogModel(
      logId: logId,
      message: message,
      timestamp: DateTime.now(),
      eventType: eventType,
    );
    // เปิด box สำหรับ log (สมมุติว่าเราใช้ box 'logs')
    final logBox = Hive.box<LogModel>('logs');
    await logBox.add(log);
  }

  static List<LogModel> getLogs() {
    final logBox = Hive.box<LogModel>('logs');
    return logBox.values.toList();
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logBox = Hive.box<LogModel>('logs');
    return Scaffold(
      appBar: AppBar(
        title: const Text("แจ้งเตือน/Log"),
      ),
      body: ValueListenableBuilder(
        valueListenable: logBox.listenable(),
        builder: (context, Box<LogModel> box, _) {
          final logs = box.values.toList();
          if (logs.isEmpty) {
            return const Center(child: Text("ยังไม่มีการแจ้งเตือน"));
          }
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                leading: CircleAvatar(child: Text("${index + 1}")),
                title: Text(log.message),
                subtitle: Text("${log.eventType} | ${log.timestamp.toLocal()}"),
              );
            },
          );
        },
      ),
    );
  }
}

