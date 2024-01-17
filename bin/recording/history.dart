import 'dart:convert';

import '../globals.dart';
import '../calendar/event.dart';

enum EventStatus {
  started,
  failed,
  successful,
  noData,
}

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
void replaceHistoryWith(Map<String, dynamic> data) =>
    historyDataInstance.saveData(data);

EventStatus getStatusFor(Event event) {
  return EventStatus.values.byName(
    history()['${event.hashCode}'] ?? 'noData',
  );
}

void saveStatusFor(Event event, EventStatus status) {
  var _history = history();
  _history.update('${event.hashCode}', (_) => status.name,
      ifAbsent: () => status.name);
  replaceHistoryWith(_history);
}
