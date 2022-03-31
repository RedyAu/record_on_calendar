import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';

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

uploadFile(File file) async {
  if (ftpHost == null) {
    print("  FTP host unconfigured, skipping upload.");
    return;
  }

  FTPConnect ftpConnect = FTPConnect(ftpHost!,
      user: ftpUsername ?? 'anonymous', pass: ftpPassword ?? '');

  print("  Uploading file...");

  try {
    print("    Connecting to $ftpHost");
    await ftpConnect.connect();
  } catch (e) {
    print("      Couldn't connect!\n$e");
    return;
  }
/*
  if (keepRecordings != 0) {
    print("    Deleting old file(s) from server");
    List<FTPEntry> items = await ftpConnect.listDirectoryContent();
    items =
        items.where((element) => element.type == FTPEntryType.FILE).toList();

    if (items.length > keepRecordings) {
      items.sort((a, b) => (a.modifyTime ??
              DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo((b.modifyTime ?? DateTime.fromMillisecondsSinceEpoch(0))));

      items = items.sublist(keepRecordings);

      for (var item in items) {
        print("      Deleting ${item.name}");
        ftpConnect.deleteFile(item.name);
      }
    }
  }
*/
  try {
    print("    Starting upload in background");
    ftpConnect.uploadFileWithRetry(file, pRetryCount: 3).then(
      (_) {
        print("    Successfully uploaded ${file.path}. Disconnecting.");
        ftpConnect.disconnect();
      },
    );
  } catch (e) {
    print("      Error while uploading file!\n$e");
  }
}
