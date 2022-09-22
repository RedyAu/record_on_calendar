import 'dart:async';
import 'dart:io';

import 'utils/app_status.dart';
import 'utils/recordable.dart';
import 'globals.dart';
import 'utils/config.dart';
import 'utils/calendar.dart';
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

  //! Recording
  try {} catch (e, s) {
    logger.log('An exception occured in the main loop: $e\n$s');
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
    print(
        "Couldn't start the program. If the error persists, delete the RecordOnCalendar folder, and let the program re-generate everything.\nError: $e\n$s");
    stdin.readLineSync();
    exit(1);
  }
}
