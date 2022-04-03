import 'dart:convert';

import 'globals.dart';

class LogData {
  DateTime? _lastRead;

  Map<String, dynamic>? _logData;

  Map<String, dynamic> getData() {
    _lastRead ??= DateTime.now();

    if (!logFile.existsSync()) {
      logFile.createSync();
      logFile.writeAsStringSync("{}");
    }

    if (_logData == null ||
        _lastRead!.isBefore(DateTime.now().subtract(Duration(seconds: 60)))) {
      return _logData = jsonDecode(logFile.readAsStringSync());
    } else {
      return _logData!;
    }
  }

  void saveData(Map<String, dynamic> data) {
    _logData = data;
    _lastRead = DateTime.now();

    logFile.createSync();

    logFile.writeAsStringSync(jsonEncode(data));
  }
}

Map<String, dynamic> logData() => logDataInstance.getData();
void saveData(Map<String, dynamic> data) => logDataInstance.saveData(data);
