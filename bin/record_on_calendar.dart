import 'dart:async';
import 'dart:io';

import 'utils/globals.dart';
import 'utils/configFile.dart';
import 'utils/ical.dart';
import 'utils/recording.dart';

program() async {
  //! Startup

  print(
      '${DateTime.now().toIso8601String()} | Record on Calendar version $version by Benedek Fodor');
  if (!homeDir.existsSync() || !configFile.existsSync()) {
    configFile.createSync(recursive: true);
    print(
        'Created directory with configuration file. Please edit and run again.');
    configFile.writeAsStringSync(getConfigFileText());
    
    exitWithPrompt(0);
  }
  print('Loading config file');
  loadConfig();

  if (!soxExe.existsSync()) {
    await getRuntime();
  }

  await updateICal();

  //! Read already recorded events.
  if (recordedListFile.existsSync()) {
    recorded = recordedListFile.readAsLinesSync();
  } else {
    recordedListFile.createSync(recursive: true);
  }
  recordingsDir.createSync();

  //! Timers

  //! iCal update
  var icalTimer = Timer.periodic(Duration(minutes: iCalUpdateFrequencyMinutes), (_) async {
    updateICal();
  });

  //! Recording
  List<Event> currents = [];
  Event? current;
  Event? next = await getNext();

  print(
      "\n\n\n\n${DateTime.now().toIso8601String()} | 💤 Not currently recording.\n  Next to record: ${next ?? "No future events!"}");

  var recTimer = Timer.periodic(Duration(seconds: 1), (_) async {
    //? update currents
    currents = await getCurrents();

    //? update next
    next = await getNext();

    //? if first in currents differs from current, stop and start
    Event? _current;
    if (currents.isNotEmpty) {
      _current = currents.first;
    } else {
      _current = null;
    }

    if (current != _current) {
      if (current != null) {
        print(
            "\n\n\n\n============================\n${DateTime.now().toIso8601String()} | Stopping recording of $current\n  Next to record: $next");
        current!.stopRecord();
        await Future.delayed(Duration(milliseconds: 300));
      }

      current = _current;

      if (current != null && !recorded.contains(current!.uid)) {
        print(
            "\n\n\n\n${DateTime.now().toIso8601String()} | Starting recording of $current\n  Recording ends at: ${current!.endWithOffset().toIso8601String()}\n  Next to record: $next");
        await current!.startRecord();
      }
    }
  });
}

main() async {
  int error = 0;
  try {
    program();
  } catch (e) {
    print(
        "Uncaught error or exception while running the program! Trying to continue...");
    print(e);
    print("----------------------\n\n");

    error++;
    if (error > 10) {
      print("Error more than 10 times in a row. Exiting.");
      exitWithPrompt(2);
    } else {
      main(); //? Bad solution
    }
  }
}
