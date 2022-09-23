// ignore_for_file: deprecated_member_use

import '../globals.dart';

import 'dart:io';

import 'package:path/path.dart' as p;

Logger logger = Logger();

/*
main() {
  logger.log("halo");
  logger.log("halloooo");
  exit(0);
}
*/
class Logger {
  late File logFile;

  Logger() {
    logFile =
        File(p.join(logDir.path, DateTime.now().toFormattedString() + '.log'));
  }

  String log(Object? object) {
    final String line = '$object'; //only do conversion once
    print(line);

    logFile.createSync(recursive: true);
    logFile.writeAsStringSync('$line\n', mode: FileMode.writeOnlyAppend);

    return line;
  }
}
