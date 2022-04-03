import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';

import 'Event.dart';
import 'globals.dart';

import 'package:path/path.dart';

/// return false if unable
Future<bool> tryDeleteFileFromServer(File file) async {
  print("ftp delete $file basename: ${basename(file.path)}"); //TODO removeme

  FTPConnect ftpConnect = FTPConnect(ftpHost!,
      user: ftpUsername ?? 'anonymous', pass: ftpPassword ?? '');
  await ftpConnect.connect();
  bool result = false;
  try {
    bool result = await ftpConnect.deleteFile(basename(file.path));
    if (!result) {
      print("  Couldn't delete ${basename(file.path)} from FTP server!");
    }
  } catch (e) {
    print(
        "  Exception occured while uploading file ${basename(file.path)}:\n$e");
  }
  if (!result) return result;
}

Future<EventStatus> uploadFile(File file) async {
  if (ftpHost == null) {
    print("  FTP host unconfigured, skipping upload.");
    return EventStatus.successful;
  }

  FTPConnect ftpConnect = FTPConnect(ftpHost!,
      user: ftpUsername ?? 'anonymous', pass: ftpPassword ?? '');

  print("  Uploading file...");

  try {
    print("    Connecting to $ftpHost");
    await ftpConnect.connect();
  } catch (e) {
    print("      Couldn't connect!\n$e");
    return EventStatus.uploadFailed;
  }

  try {
    print("    Starting upload in background");
    await ftpConnect.uploadFileWithRetry(file, pRetryCount: 3);
    print("    Successfully uploaded ${file.path}. Disconnecting.");
    ftpConnect.disconnect();
    return EventStatus.uploaded;
  } catch (e) {
    print("      Error while uploading file!\n$e");
  }
  return EventStatus.uploadFailed;
}
