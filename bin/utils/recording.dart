import 'dart:io';

import 'package:http/http.dart';
import 'package:archive/archive_io.dart';

import 'ftp.dart';
import 'globals.dart';

List<String> recorded = [];

addRecorded(String uid) {
  recorded.add(uid);
  recordedListFile.writeAsStringSync(recorded.join("\n"));
}

deleteFilesOverKeepLimit() {
  if (keepRecordings == 0) return;

  print("  Deleting files over keep limit...");

  List<File> files = recordingsDir.listSync().whereType<File>().toList();
  files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  if (files.length > keepRecordings) {
    files = files.toList().sublist(keepRecordings);
    for (var file in files) {
      print("    Deleting file from drive and FTP: ${file.path}");
      tryDeleteFileFromServer(file);
      file.delete();
    }
  }
}

Future<Process> startRecordWithName(String filename) async {
  deleteFilesOverKeepLimit();

  filename = "$filename.mp3".replaceAll(RegExp(r'[<>:"/\\|?*]'), "_");

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
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  await Future.delayed(Duration(milliseconds: 300));
  return process;
}

Future getRuntime() async {
  if (soxDir.existsSync()) soxDir.deleteSync(recursive: true);

  print(
      'Downloading and unzipping SoX (Sound library). This may take a few minutes.');

  await get(Uri.parse(
          "https://altushost-swe.dl.sourceforge.net/project/sox/sox/14.4.1/sox-14.4.1a-win32.zip"))
      .then((resp) {
    File zipFile = File('${soxDir.path}${ps}sox.zip');
    zipFile.createSync(recursive: true);
    zipFile.writeAsBytesSync(resp.bodyBytes);

    print("  Done downloading. Starting extracting.");

    soxDir.createSync(recursive: true);
    extractFileToDisk('${soxDir.path}${ps}sox.zip', soxDir.path);

    print("  Done extracting.");
  });

  print(
      'Downloading and unzipping Lame MP3 encoder. This may take a few minutes.');

  await get(Uri.parse(
          "https://www.rarewares.org/files/mp3/libmp3lame-3.100x86.zip"))
      .then((resp) {
    File zipFile = File('${soxDir.path}${ps}lame.zip');
    zipFile.createSync(recursive: true);
    zipFile.writeAsBytesSync(resp.bodyBytes);

    print("  Done downloading. Starting extracting.");

    soxDir.createSync(recursive: true);
    extractFileToDisk('${soxDir.path}${ps}lame.zip', soxDir.path);

    File lamedll = File('${soxDir.path}${ps}libmp3lame.dll');
    lamedll.renameSync('${soxVersionDir.path}${ps}libmp3lame.dll');

    print("  Done extracting.");
  });
}
