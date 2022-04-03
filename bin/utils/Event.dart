import 'dart:convert';
import 'dart:io';

import 'LogData.dart';
import 'ftp.dart';
import 'globals.dart';
import 'ical.dart';
import 'recording.dart';

/// started, failed, successful, noData
enum EventStatus { started, failed, successful, noData }

class Event {
  String uid;
  DateTime start;
  DateTime end;
  String title;
  String description;

  Event(this.uid, this.start, this.end, this.title, this.description);

  Process? recorderProcess;
  File? audioFile;

  //! Recording

  ///Returns Process from recording SoX process.
  startRecord() async {
    saveStatus(EventStatus.started);
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
      saveStatus(EventStatus.failed);
    } else {
      if (recorderProcess!.kill(ProcessSignal.sigterm)) {
        saveStatus(EventStatus.successful);
      } else {
        saveStatus(EventStatus.failed);
      }
      print("  Stopped process with PID ${recorderProcess!.pid}");
      uploadFile(audioFile!);
    }
  }

  //! Status

  bool saveStatus(EventStatus status) {
    Map<String, dynamic> data = logData();

    data.update(uid, (_) => status.name, ifAbsent: () => status.name);
    saveData(data);

    return true;
  }

  EventStatus getStatus() {
    if (!logFile.existsSync()) return EventStatus.noData;

    return EventStatus.values.byName(
      logData()[uid] ?? "noData",
    );
  }

  bool shouldRecord() {
    EventStatus status = getStatus();
    return (status == EventStatus.failed || status == EventStatus.noData);
  }

  //! Overrides and fields

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
