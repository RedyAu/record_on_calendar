import 'dart:io';

import '../globals.dart';
import 'history.dart';
import 'log.dart';
import 'recording.dart';

enum RecordingStatus {
  started,
  failed,
  successful,
  noData,
}

class Recordable {
  String uid;
  DateTime start;
  DateTime end;
  String title;
  String description;

  Recordable(this.uid, this.start, this.end, this.title, this.description);

  Process? recorderProcess;
  File? audioFile;

  //! Recording

  ///Returns Process from recording SoX process.
  startRecord() async {
    saveStatus(RecordingStatus.started);
    String name = '${start.toFormattedString()} - $title';
    recorderProcess = await startRecordWithName(name);
    audioFile =
        File(recordingsDir.path + ps + "$name.mp3".getSanitizedForFilename());
    log.print("  Started process with PID ${recorderProcess!.pid}");
  }

  Future<bool> stopRecord() async {
    if (recorderProcess == null) {
      log.print("  Couldn't stop recording, no process associated with event!");
      saveStatus(RecordingStatus.failed);
      return false;
    } else {
      if (recorderProcess!.kill(ProcessSignal.sigterm)) {
        saveStatus(RecordingStatus.successful);
      } else {
        saveStatus(RecordingStatus.failed);
      }
      log.print("  Stopped process with PID ${recorderProcess!.pid}");
      //await Future.delayed(Duration(milliseconds: 300)); //TODO why was this needed
      return true;
    }
  }

  //! Status

  bool saveStatus(RecordingStatus status) {
    Map<String, dynamic> data = history();

    data.update(uid, (_) => status.name, ifAbsent: () => status.name);
    saveData(data);

    return true;
  }

  RecordingStatus getStatus() {
    if (!historyFile.existsSync()) return RecordingStatus.noData;

    return RecordingStatus.values.byName(
      history()[uid] ?? "noData",
    );
  }

  bool shouldStartRecord() {
    RecordingStatus status = getStatus();
    return (status != RecordingStatus.successful) ||
        (status == RecordingStatus.started && recorderProcess == null);
  }

  //! Overrides and fields

  @override
  int get hashCode => uid.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    bool result = other is Recordable && other.start == start;
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
