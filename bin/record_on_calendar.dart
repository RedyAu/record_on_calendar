import 'dart:async';
import 'dart:io';

import 'utils/app_status.dart';
import 'utils/event_class.dart';
import 'globals.dart';
import 'utils/config.dart';
import 'utils/calendar.dart';
import 'utils/log.dart';
import 'utils/email.dart';
import 'utils/recording.dart';

void main() async {
  await setup();

  //! Watchdog
  DateTime lastTick = DateTime.now();
  Timer.periodic(Duration(seconds: 1), (timer) {
    if (lastTick.isBefore(DateTime.now().subtract(Duration(seconds: 5)))) {
      log.print(
          "\n${DateTime.now().toFormattedString()}\n=======\nWARNING\n=======\nProgram was unresponsive for ${lastTick.difference(DateTime.now())}!\nInresponsive since: $lastTick");
    }
    lastTick = DateTime.now();
    currentStatus.printStatus();
  });

  //! iCal update
  Timer.periodic(Duration(minutes: iCalUpdateFrequencyMinutes), (_) async {
    await updateICal();
    currentStatus.printStatus();
  });

  Recordable? currentRecordable;
  Recordable? nextRecordable;

  //! Recording
  List<Recordable> currents = [];
  nextRecordable = getNext();

  while (true) {
    try {
      //? update currents
      currents = getCurrents();

      //? update next
      nextRecordable = getNext();

      //? if first in currents differs from current, stop and start
      Recordable? updatedCurrent;
      if (currents.isNotEmpty) {
        updatedCurrent = currents.first;
      } else {
        updatedCurrent = null;
      }

      if (currentRecordable != updatedCurrent) {
        //? Stop recording
        if (currentRecordable != null) {
          log.print(
              "\n\n\n============================\n${DateTime.now().toFormattedString()} | ■ Stopping recording of $currentRecordable\n\n");
          currentStatus.update(AppStatus.idle, currentRecordable);

          currentRecordable.stopRecord().then((_) {
            //? If no more events today, send email
            if (((nextRecordable != null &&
                        !nextRecordable.start.isSameDate(DateTime.now())) ||
                    nextRecordable == null) &&
                updatedCurrent == null) {
              sendDailyEmail();
            }
          });
        }

        currentRecordable = updatedCurrent;

        //? Start recording
        if (currentRecordable != null && currentRecordable.shouldRecord()) {
          currentStatus.update(AppStatus.recording, currentRecordable);
          log.print(
              "\n\n\n============================\n${DateTime.now().toFormattedString()} | >> Starting recording of $currentRecordable\n\n");

          await currentRecordable.startRecord();
        }
      }

      await Future.delayed(Duration(seconds: 5));
    } catch (e, s) {
      log.print('An exception occured in the main loop: $e\n$s');
    }
  }
}

setup() async {
  log.print(
      '${DateTime.now().toFormattedString()} | Record on Calendar version $version by Benedek Fodor');
  if (!homeDir.existsSync() || !configFile.existsSync()) {
    configFile.createSync(recursive: true);
    log.print(
        'Created directory with configuration file. Please edit and run again.');
    configFile.writeAsStringSync(generateConfigText());

    stdin.readLineSync();
    exit(0);
  }
  
  loadConfig();

  if (!soxExe.existsSync()) {
    await getRuntime();
  }

  await updateICal();

  recordingsDir.createSync();
}
