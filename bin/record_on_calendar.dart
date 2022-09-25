import 'dart:async';
import 'dart:io';

import 'utils/app_status.dart';
import 'utils/event.dart';
import 'globals.dart';
import 'utils/config.dart';
import 'utils/calendar.dart';
import 'utils/history.dart';
import 'utils/log.dart';
import 'utils/email.dart';
import 'utils/recording.dart';
import 'utils/tracks.dart';

void main() async {
  await setup();

  //! Watchdog and display
  DateTime lastTick = DateTime.now();
  Timer.periodic(Duration(seconds: 5), (timer) {
    if (lastTick.isBefore(DateTime.now().subtract(Duration(seconds: 10)))) {
      logger.log(
          "\n${DateTime.now().toFormattedString()}\n=======\nWARNING\n=======\nProgram was unresponsive for ${lastTick.difference(DateTime.now())}!\nUnresponsive since: $lastTick");
    }
    lastTick = DateTime.now();
    currentStatus.printStatus();
  });

  //! iCal update
  Timer.periodic(Duration(minutes: iCalUpdateFrequencyMinutes), (_) async {
    await updateICal();
    currentStatus.printStatus();
  });

  Event? last;
  Process? process;

  //! Recording
  while (true) {
    try {
      //? Update current
      Event? current = getCurrentEvent();

      if (last != current) {
        //? If recording is running, stop it (from last event)
        if (process != null) {
          logger.log(
              "\n\n\n============================\n${DateTime.now().toFormattedString()} | ■ Stopping recording of $last");
          bool? successful = await process?.kill();
          saveStatusFor(
            last!, //! If this is null, a serious mistake was made (last event can't be null if there is a process recording it. Was it not stopped or the process variable not updated?)
            successful ?? false ? EventStatus.successful : EventStatus.failed,
          );
          logger.log("  Process ${process?.pid} stopped.");
          checkAndSendDailyEmail();
          currentStatus.update(AppStatus.idle);
        }

        //? Start recording for the current event, if there is one
        if (current != null) {
          logger.log(
              "\n\n\n============================\n${DateTime.now().toFormattedString()} | >> Starting recording of $current");
          saveStatusFor(current, EventStatus.started); //At least we tried.
          try {
            process = await startRecordWithName(current.fileName);
            logger.log("  Started recording process ${process?.pid}.");
            process?.exitCode.whenComplete(() => process = null);
          } catch (_) {
            saveStatusFor(current, EventStatus.failed);
            rethrow;
          }
          currentStatus.update(AppStatus.recording);
        }
      }

      last = current;

      if (current != null) {
        //? If current hasn't changed, and there is a current recording
        if (process == null) {
          logger.log(
              '\nERROR: Currently a recording should be running, but no process is active!\nRestarting process...');
          last = null;
        }
      }

      await Future.delayed(Duration(seconds: 3));
    } catch (e, s) {
      logger.log(
          'An exception occured in the main loop, waiting 5 seconds.\n$e\n$s');
      await Future.delayed(Duration(seconds: 5));
    }
  }
}

setup() async {
  try {
    logger.log(
        '${DateTime.now().toFormattedString()} | Record on Calendar version $version by Benedek Fodor');
    if (!homeDir.existsSync() || !configFile.existsSync()) {
      configFile.createSync(recursive: true);
      logger.log(
          'Created directory with configuration file. Please edit and run again.');
      configFile.writeAsStringSync(generateConfigText());

      stdin.readLineSync();
      exit(0);
    }

    loadConfig();

    if (!ffmpegExe.existsSync()) {
      await getRuntime();
    }

    updateDevices();

    await updateICal();

    recordingsDir.createSync();
  } catch (e, s) {
    logger.log(
        "Couldn't start the program. If the error persists, delete the RecordOnCalendar folder, and let the program re-generate everything.\nError: $e\n$s");
    stdin.readLineSync();
    exit(1);
  }
}
