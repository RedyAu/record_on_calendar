import 'dart:io';

import 'history.dart';
import 'ftp.dart';
import 'globals.dart';
import 'log.dart';
import 'recording.dart';

/// started, failed, successful, noData
enum EventStatus { started, failed, successful, uploaded, uploadFailed, noData }

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
    String name = '${start.toFormattedString()} - $title';
    recorderProcess = await startRecordWithName(name);
    audioFile = File(recordingsDir.path +
        ps +
        "$name.mp3".replaceAll(RegExp(r'[<>:"/\\|?*őű]'), "_"));
    log.print("  Started process with PID ${recorderProcess!.pid}");
  }

  Future<bool> stopRecord() async {
    if (recorderProcess == null) {
      log.print("  Couldn't stop recording, no process associated with event!");
      saveStatus(EventStatus.failed);
      return false;
    } else {
      if (recorderProcess!.kill(ProcessSignal.sigterm)) {
        saveStatus(EventStatus.successful);
      } else {
        saveStatus(EventStatus.failed);
      }
      log.print("  Stopped process with PID ${recorderProcess!.pid}");
      await Future.delayed(Duration(milliseconds: 300));
      saveStatus(await uploadFile(audioFile!));
      return true;
    }
  }

  //! Status

  bool saveStatus(EventStatus status) {
    Map<String, dynamic> data = history();

    data.update(uid, (_) => status.name, ifAbsent: () => status.name);
    saveData(data);

    return true;
  }

  EventStatus getStatus() {
    if (!historyFile.existsSync()) return EventStatus.noData;

    return EventStatus.values.byName(
      history()[uid] ?? "noData",
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
    bool result = other is Event && other.start == start;
    return result;
  }

  @override
  String toString() => "${start.toFormattedString()} | $title";

  ///Returns start time subtracted with global start earlier offset
  DateTime startWithOffset() =>
      start.subtract(Duration(minutes: startEarlierByMinutes));

  ///Returns end time added with global end alter offset
  DateTime endWithOffset() => end.add(Duration(minutes: endLaterByMinutes));
}
