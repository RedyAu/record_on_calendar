import 'dart:io';

import 'package:http/http.dart';
import 'package:icalendar_parser/icalendar_parser.dart';

import 'ftp.dart';
import 'globals.dart';
import 'recording.dart';

Future<Event?> getNext() async {
  try {
    return events
        .lastWhere((event) => event.startWithOffset().isAfter(DateTime.now()));
  } catch (e) {
    return null;
  }
}

Future<List<Event>> getCurrents() async {
  return events
      .where((event) =>
          event.startWithOffset().isBefore(DateTime.now()) &&
          event.endWithOffset().isAfter(DateTime.now()))
      .toList();
}

Future updateICal() async {
  events = [];
  print("\n\n\n\n${DateTime.now().toIso8601String()} | Updating Calendar");
  print("  Downloading");
  var req = await get(iCalUri);
  String iCalString = req.body;

  print("  Parsing");
  ICalendar iCalendar = ICalendar.fromString(iCalString);
  for (Map vEvent in iCalendar.data.where((data) => data["type"] == "VEVENT")) {
    var event = Event(
        vEvent["uid"],
        DateTime.parse((vEvent["dtstart"] as IcsDateTime).dt).toLocal(),
        DateTime.parse((vEvent["dtend"] as IcsDateTime).dt).toLocal(),
        vEvent["summary"],
        vEvent["description"] ?? "");
    if (matchEventName.hasMatch(event.title + event.description)) events.add(event);
  }
  events.sort((a, b) => b.start.compareTo(a.start));
  print("  Done. Got ${events.length} items.");
}

class Event {
  String uid;
  DateTime start;
  DateTime end;
  String title;
  String description;

  Event(this.uid, this.start, this.end, this.title, this.description);

  Process? recorderProcess;
  File? audioFile;

  ///Returns Process from recording SoX process.
  startRecord() async {
    addRecorded(uid);
    String name = '${start.toIso8601String()} - $title';
    recorderProcess = await startRecordWithName(name);
    audioFile = File(recordingsDir.path +
        ps +
        "$name.mp3".replaceAll(RegExp(r'[<>:"/\\|?*]'), "_"));
    print("  Started process with PID ${recorderProcess!.pid}");
  }

  stopRecord() {
    if (recorderProcess == null) {
      print("  Couldn't stop recording, no process associated with event!");
    } else {
      recorderProcess!.kill(ProcessSignal.sigterm);
      print("  Stopped process with PID ${recorderProcess!.pid}");
      uploadFile(audioFile!);
    }
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    bool result = other is Event && other.uid == uid;
    return result;
  }

  @override
  String toString() => "${start.toIso8601String()} | $title";

  ///Returns start time subtracted with global start earlier offset
  DateTime startWithOffset() =>
      start.subtract(Duration(minutes: startEarlierByMinutes));

  ///Returns end time added with global end alter offset
  DateTime endWithOffset() => end.add(Duration(minutes: endLaterByMinutes));
}
