import 'dart:convert';

import 'globals.dart';

class HistoryData {
  DateTime? _lastRead;

  Map<String, dynamic>? _historyData;

  Map<String, dynamic> getData() {
    _lastRead ??= DateTime.now();

    if (!historyFile.existsSync()) {
      historyFile.createSync();
      historyFile.writeAsStringSync("{}");
    }

    if (_historyData == null ||
        _lastRead!.isBefore(DateTime.now().subtract(Duration(seconds: 60)))) {
      return _historyData = jsonDecode(historyFile.readAsStringSync());
    } else {
      return _historyData!;
    }
  }

  void saveData(Map<String, dynamic> data) {
    _historyData = data;
    _lastRead = DateTime.now();

    historyFile.createSync();

    historyFile.writeAsStringSync(jsonEncode(data));
  }
}

Map<String, dynamic> history() => historyDataInstance.getData();
void saveData(Map<String, dynamic> data) => historyDataInstance.saveData(data);
