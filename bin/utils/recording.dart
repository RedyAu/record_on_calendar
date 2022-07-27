import 'dart:io';

import 'package:http/http.dart';
import 'package:archive/archive_io.dart';

import '../globals.dart';
import 'log.dart';
import 'tracks.dart';

deleteFilesOverKeepLimit() async {
  if (keepRecordings == 0) return;

  logger.print("  Deleting files over keep limit...");
  try {
    List<FileSystemEntity> entities = recordingsDir.listSync().toList();
    entities.sort(
        (a, b) => b.tryLastModifiedSync().compareTo(a.tryLastModifiedSync()));
    if (entities.length > keepRecordings) {
      entities = entities.toList().sublist(keepRecordings);

      for (var entity in entities) {
        logger.print("    Deleting item: ${entity.path}");
        try {
          entity.deleteSync(recursive: true);
        } catch (e, s) {
          logger.print('Error while deleting file $entity: $e\n$s');
        }
      }
    }
  } catch (e, s) {
    logger.print('Error while deleting files: $e\n$s');
  }
  return;
}

Future<Process> startRecordWithName(String recordingTitle) async {
  deleteFilesOverKeepLimit();
  updateDevices();

  Directory currentDir = Directory(
      recordingsDir.path + ps + recordingTitle.getSanitizedForFilename());
  currentDir.createSync(recursive: true);

  var process = await Process.start(
      ffmpegExe.path,
      devicesToRecord
          .asMap()
          .entries
          .map((e) => [
                '-f',
                'dshow',
                '-i',
                'audio=${e.value.id}',
                '-map',
                '${e.key}',
                '${e.value.fileName}.mp3'
              ])
          .reduce((value, element) => value.followedBy(element).toList()),
      //runInShell: true,
      workingDirectory: currentDir.path,
      mode: ProcessStartMode.inheritStdio); //TODO removeme

  await Future.delayed(Duration(milliseconds: 300));
  return process;
}

Future getRuntime() async {
  if (ffmpegDir.existsSync()) ffmpegDir.deleteSync(recursive: true);

  logger.print(
      'Downloading and unzipping ffmpeg media library. This will take a while.');

  await get(Uri.parse(
          "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"))
      .then((resp) {
    File zipFile = File('${ffmpegDir.path}${ps}ffmpeg.zip');
    zipFile.createSync(recursive: true);
    zipFile.writeAsBytesSync(resp.bodyBytes);

    logger.print("  Done downloading. Starting extracting.");

    ffmpegDir.createSync(recursive: true);
    extractFileToDisk('${ffmpegDir.path}${ps}ffmpeg.zip', ffmpegDir.path);

    logger.print("  Done extracting.");
  });
}
