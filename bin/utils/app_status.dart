import '../globals.dart';
import 'event.dart';
import 'calendar.dart';

enum AppStatus { idle, recording }

class CurrentStatus {
  AppStatus _currentStatus = AppStatus.idle;
  Event? _current;

  void update(AppStatus newStatus) {
    _currentStatus = newStatus;
  }

  AppStatus get currentStatus => _currentStatus;

  int i = 0;
  void printStatus() async {
    _current = getCurrentEvent();

    i++;
    if (i > 3) i = 0;

    Event? _next = getNextEvent();
    switch (_currentStatus) {
      case AppStatus.idle:
        print("""

${DateTime.now().toFormattedString()} | ZzZ Not recording.
  Next to record: ${_next ?? "No future events!"}
""");
        break;
      case AppStatus.recording:
        if (_current != null) {
          print("""

${DateTime.now().toFormattedString()} ${progressIndicator[i]} Recording $_current
  Recording ends at: ${_current!.endWithOffset.toFormattedString()}
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
