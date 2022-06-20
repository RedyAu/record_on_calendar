import 'dart:convert';

import '../globals.dart';

class HistoryData {
  Map<String, dynamic>? _historyData;

  Map<String, dynamic> getData() {
    if (!historyFile.existsSync()) {
      historyFile.createSync();
      historyFile.writeAsStringSync("{}");
    }

    if (_historyData == null) {
      return _historyData = jsonDecode(historyFile.readAsStringSync());
    } else {
      return _historyData!;
    }
  }

  void saveData(Map<String, dynamic> data) {
    _historyData = data;

    historyFile.createSync();

    historyFile.writeAsStringSync(jsonEncode(data));
  }
}

Map<String, dynamic> history() => historyDataInstance.getData();
void saveData(Map<String, dynamic> data) => historyDataInstance.saveData(data);
