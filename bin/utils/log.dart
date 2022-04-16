// ignore_for_file: deprecated_member_use

import 'globals.dart';

import 'dart:io';
import 'dart:cli';

Log log = Log();

main() {
  log.print("halo");
  log.print("halloooo");
}

class Log {
  late File logFile;

  Log() {
    logFile =
        File(logDir.path + ps + DateTime.now().toFormattedString() + ".log");
  }

  String print(Object? object) {
    String line = "$object"; //copied from dart api
    _printToConsole(line);

    logFile.createSync(recursive: true);
    var f = logFile.openWrite(mode: FileMode.writeOnlyAppend);
    f.writeln(line);

    // HACK | deprecated, needed to replace print()
    waitFor(f.flush());
    waitFor(f.close());

    return line;
  }
}

_printToConsole(Object? object) => print(object); //HACK