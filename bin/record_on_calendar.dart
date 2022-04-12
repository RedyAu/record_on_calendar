import 'dart:async';
import 'dart:io';

import 'utils/event_class.dart';
import 'utils/globals.dart';
import 'utils/config.dart';
import 'utils/ical.dart';
import 'utils/log.dart';
import 'utils/mailer.dart';
import 'utils/recording.dart';

void main() async {
  String currentStatus = "";

  await setup();

  //! iCal update
  Timer.periodic(Duration(minutes: iCalUpdateFrequencyMinutes), (_) async {
    iCalUpdating = true;
    await updateICal();
    iCalUpdating = false;
    log.print(currentStatus);
  });

  //! Recording
  List<Event> currents = [];
  Event? current;
  Event? next = await getNext();

  currentStatus =
      "\n${DateTime.now().toFormattedString()} | 💤 Not recording.\n  Next to record: ${next ?? "No future events!"}";
  log.print("\n\n\n" + currentStatus);

  try {
    while (true) {
      // HACK Absolutely horrible solution
      if (iCalUpdating) continue;

      //? update currents
      currents = await getCurrents();

      //? update next
      next = await getNext();

      //? if first in currents differs from current, stop and start
      Event? updatedCurrent;
      if (currents.isNotEmpty) {
        updatedCurrent = currents.first;
      } else {
        updatedCurrent = null;
      }

      if (current != updatedCurrent) {
        if (current != null) {
          log.print(
              "\n\n\n============================\n${DateTime.now().toFormattedString()} | ■ Stopping recording of $current\n  Next to record: ${next ?? "No future events!"}");
          currentStatus =
              "\n${DateTime.now().toFormattedString()} | 💤 Not recording.\n  Next to record: ${next ?? "No future events!"}";

          current.stopRecord().then((_) {
            //? If no more events today, send email
            if (((next != null && !next.start.isSameDate(DateTime.now())) ||
                    next == null) &&
                updatedCurrent == null) {
              sendDailyEmail();
            }
          });
        }

        current = updatedCurrent;

        if (current != null && current.shouldRecord()) {
          currentStatus =
              "\n${DateTime.now().toFormattedString()} | ► Recording $current\n  Recording ends at: ${current.endWithOffset().toFormattedString()}\n  Next to record: ${next ?? "No future events!"}";
          log.print("\n\n\n" + currentStatus);
          await current.startRecord();
        }
      }

      await Future.delayed(Duration(seconds: 5));
    }
  } catch (e, s) {
    log.print('An exception occured in the main loop: $e\n$s');
  }
}

setup() async {
  log.print(
      '${DateTime.now().toFormattedString()} | Record on Calendar version $version by Benedek Fodor');
  if (!homeDir.existsSync() || !configFile.existsSync()) {
    configFile.createSync(recursive: true);
    log.print(
        'Created directory with configuration file. Please edit and run again.');
    configFile.writeAsStringSync(getConfigFileText());

    stdin.readLineSync();
    exit(0);
  }
  log.print('Loading config file');
  loadConfig();

  if (!soxExe.existsSync()) {
    await getRuntime();
  }

  await updateICal();

  recordingsDir.createSync();
}
