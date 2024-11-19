// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../globals.dart';

Logger logger = Logger();

List<String> currentError = [];
List<String> lastLog = [];

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
    logFile = File(p.join(logDir.path, DateTime.now().toFormattedString() + '.log'));
  }

  String log(Object? object, [bool error = false]) {
    // TODO make error named parameter
    final String line = '$object'; //only do conversion once
    print(line);

    logFile.createSync(recursive: true);
    logFile.writeAsStringSync('$line\n', mode: FileMode.writeOnlyAppend);
    if (error) {
      currentError.add(line);
    }

    lastLog.add(line);
    if (lastLog.length > 100) lastLog.removeAt(0);

    return line;
  }
}

List<(String, bool)> ffmpegOutput = [];
void streamToOutput(Stream stream, bool error) async {
  try {
    await for (var event in stream) {
      var line = Utf8Decoder().convert(event);
      ffmpegOutput.add((line, error));
      if (debug) print(line);
      if (ffmpegOutput.length > 100) ffmpegOutput.removeAt(0);
    }
    if (debug || error) {
      stream.listen((event) {});
    }
  } catch (e, s) {
    logger.log('Error while streaming output: $e\n$s');
    // reset stream and unsubscribe
  }
}
