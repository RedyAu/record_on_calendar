import '../globals.dart';
import 'event_class.dart';
import 'calendar.dart';

enum AppStatus { idle, recording }

class CurrentStatus {
  AppStatus _currentStatus = AppStatus.idle;
  Recordable? _current;

  void update(AppStatus newStatus, Recordable current) {
    _currentStatus = newStatus;
    _current = current;
    printStatus();
  }

  AppStatus get currentStatus => _currentStatus;

  int i = 0;
  void printStatus() async {
    i++;
    if (i > 3) i = 0;

    Recordable? _next = getNext();
    switch (_currentStatus) {
      case AppStatus.idle:
        print("""

${DateTime.now().toFormattedString()} | ZzZ Not recording.
  Next to record: ${_next ?? "No future events!"}""");
        break;
      case AppStatus.recording:
        if (_current != null) {
          print("""

${DateTime.now().toFormattedString()} ${progressIndicator[i]} Recording $_current
  Recording ends at: ${_current!.endWithOffset().toFormattedString()}
  Next to record: ${_next ?? "No future events!"}
""");
        } else {
          print("""

${DateTime.now().toFormattedString()} | ERROR
  App state is 'recording', but no current event is set!
""");
        }
        break;
    }
  }
}

CurrentStatus currentStatus = CurrentStatus();
