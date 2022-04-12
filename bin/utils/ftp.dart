import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';

import 'event_class.dart';
import 'globals.dart';

import 'package:path/path.dart';

import 'log.dart';

/// return false if unable
Future<bool> tryDeleteFileFromServer(File file) async {
  FTPConnect ftpConnect = FTPConnect(ftpHost!,
      user: ftpUsername ?? 'anonymous', pass: ftpPassword ?? '');
  await ftpConnect.connect();
  bool result = false;
  try {
    bool result = await ftpConnect.deleteFile(basename(file.path));
    if (!result) {
      log.print("  Couldn't delete ${basename(file.path)} from FTP server!");
    }
  } catch (e) {
    log.print(
        "  Exception occured while uploading file ${basename(file.path)}:\n$e");
  }
  if (!result) return result;
}

Future<EventStatus> uploadFile(File file) async {
  if (ftpHost == null) {
    log.print("  FTP host unconfigured, skipping upload.");
    return EventStatus.successful;
  }

  FTPConnect ftpConnect = FTPConnect(ftpHost!,
      user: ftpUsername ?? 'anonymous', pass: ftpPassword ?? '');

  log.print("  Uploading file...");

  try {
    log.print("    Connecting to $ftpHost");
    await ftpConnect.connect();
  } catch (e) {
    log.print("      Couldn't connect!\n$e");
    return EventStatus.uploadFailed;
  }

  try {
    log.print("    Starting upload in background");
    await ftpConnect.uploadFileWithRetry(file, pRetryCount: 5);
    log.print("    Successfully uploaded ${file.path}. Disconnecting.");
    ftpConnect.disconnect();
    return EventStatus.uploaded;
  } catch (e) {
    log.print("      Error while uploading file!\n$e");
  }
  return EventStatus.uploadFailed;
}
