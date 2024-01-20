import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;

import '../globals.dart';
import '../utils/log.dart';
import 'tracks.dart';

deleteFilesOverKeepLimit() async {
  if (keepRecordings == 0) return;

  logger.log("  Deleting files over keep limit...");
  try {
    List<FileSystemEntity> entities = recordingsDir.listSync().toList();
    entities.sort(
        (a, b) => b.tryLastModifiedSync().compareTo(a.tryLastModifiedSync()));
    if (entities.length > keepRecordings) {
      entities = entities.sublist(keepRecordings);

      for (var entity in entities) {
        logger.log("    Deleting item: ${entity.path}");
        try {
          entity.deleteSync(recursive: true);
        } catch (e, s) {
          logger.log('      ERROR while deleting file $entity: $e\n$s', true);
        }
      }
    }
  } catch (e, s) {
    logger.log('      ERROR while deleting files: $e\n$s', true);
  }
  return;
}

Future<Process?> startRecordWithName(String recordingTitle) async {
  deleteFilesOverKeepLimit();
  updateDevices();

  Directory currentDir = Directory(p.join(
    recordingsDir.path,
    recordingTitle.getSanitizedForFilename(),
  ));

  if (currentDir.existsSync()) {
    logger.log(
        '  WARNING: Recording already exists. Renaming existing recording.',
        true);
    try {
      currentDir.renameSync('${currentDir.path}_${DateTime.now().hashCode}');
    } catch (e) {
      logger.log(
          '    ERROR: Rename failed: $e\nTrying to kill ffmpeg.\n\n', true);
      try {
        var process =
            await Process.start('taskkill', ['/F', '/IM', 'ffmpeg.exe']);
        await process.exitCode;
        return null;
      } catch (e) {
        logger.log("    ERROR: Couldn't kill ffmpeg: $e", true);
      }
    }
  }
  currentDir.createSync(recursive: true);

  if (devicesToRecord.isEmpty) {
    logger.log(
        "  ERROR: No devices available or enabled to record. Couldn't start recording.",
        true);
    return null;
  }

  try {
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
        workingDirectory: currentDir.path,
        mode: ProcessStartMode.normal);

    await Future.delayed(Duration(milliseconds: 300));

    streamToOutput(process.stdout, false);
    streamToOutput(process.stderr, true);

    return process;
  } catch (_) {
    logger.log("  ERROR: Couldn't start recorder process!", true);
    rethrow;
  }
}

Future getRuntime() async {
  if (ffmpegDir.existsSync()) ffmpegDir.deleteSync(recursive: true);

  logger.log(
      'Downloading and unzipping ffmpeg media library. This will take a while.');

  await get(Uri.parse(
          "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"))
      .then((resp) {
    File zipFile = File(p.join(ffmpegDir.path, 'ffmpeg.zip'));
    zipFile.createSync(recursive: true);
    zipFile.writeAsBytesSync(resp.bodyBytes);

    logger.log("  Done downloading. Starting extracting.");

    ffmpegDir.createSync(recursive: true);
    extractFileToDisk(p.join(ffmpegDir.path, 'ffmpeg.zip'), ffmpegDir.path);

    logger.log("  Done extracting.");
  });
}
