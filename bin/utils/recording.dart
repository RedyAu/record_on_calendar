import 'dart:io';

import 'package:http/http.dart';
import 'package:archive/archive_io.dart';

import '../globals.dart';
import 'log.dart';

deleteFilesOverKeepLimit() async {
  if (keepRecordings == 0) return;

  logger.print("  Deleting files over keep limit...");

  List<FileSystemEntity> entities = recordingsDir.listSync().toList();
  entities.sort(
      (a, b) => b.tryLastModifiedSync().compareTo(a.tryLastModifiedSync()));
  if (entities.length > keepRecordings) {
    entities = entities.toList().sublist(keepRecordings);

    for (var file in entities) {
      logger.print("    Deleting file: ${file.path}");

      file.delete();
    }
  }
  return;
}

Future<Process> startRecordWithName(String filename) async {
  deleteFilesOverKeepLimit();

  filename = "$filename.mp3".getSanitizedForFilename();

  var process = await Process.start(
      soxExe.path,
      [
        "-t",
        "waveaudio",
        "-d",
        filename,
      ],
      //runInShell: true,
      workingDirectory: recordingsDir.path);

  await Future.delayed(Duration(milliseconds: 300));
  return process;
}

Future getRuntime() async {
  if (soxDir.existsSync()) soxDir.deleteSync(recursive: true);

  logger.print(
      'Downloading and unzipping SoX (Sound library). This may take a few minutes.');

  await get(Uri.parse(
          "https://altushost-swe.dl.sourceforge.net/project/sox/sox/14.4.1/sox-14.4.1a-win32.zip"))
      .then((resp) {
    File zipFile = File('${soxDir.path}${ps}sox.zip');
    zipFile.createSync(recursive: true);
    zipFile.writeAsBytesSync(resp.bodyBytes);

    logger.print("  Done downloading. Starting extracting.");

    soxDir.createSync(recursive: true);
    extractFileToDisk('${soxDir.path}${ps}sox.zip', soxDir.path);

    logger.print("  Done extracting.");
  });

  logger.print(
      'Downloading and unzipping Lame MP3 encoder. This may take a few minutes.');

  await get(Uri.parse(
          "https://www.rarewares.org/files/mp3/libmp3lame-3.100x86.zip"))
      .then((resp) {
    File zipFile = File('${soxDir.path}${ps}lame.zip');
    zipFile.createSync(recursive: true);
    zipFile.writeAsBytesSync(resp.bodyBytes);

    logger.print("  Done downloading. Starting extracting.");

    soxDir.createSync(recursive: true);
    extractFileToDisk('${soxDir.path}${ps}lame.zip', soxDir.path);

    File lamedll = File('${soxDir.path}${ps}libmp3lame.dll');
    lamedll.renameSync('${soxVersionDir.path}${ps}libmp3lame.dll');

    logger.print("  Done extracting.");
  });
}
