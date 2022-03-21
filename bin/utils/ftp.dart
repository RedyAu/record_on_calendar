import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';

import 'globals.dart';

uploadFile(File file) async {
  if (ftpHost == null) return;

  FTPConnect ftpConnect = FTPConnect(ftpHost!,
      user: ftpUsername ?? 'anonymous', pass: ftpPassword ?? '');

  print("Uploading file...");

  try {
    print("  Connecting to $ftpHost");
    await ftpConnect.connect();
  } catch (e) {
    print("    Couldn't connect!\n$e");
    return;
  }

  if (keepRecordings != 0) {
    print("  Deleting old file(s) from server");
    List<FTPEntry> items = await ftpConnect.listDirectoryContent();
    items =
        items.where((element) => element.type == FTPEntryType.FILE).toList();

    if (items.length > keepRecordings) {
      items.sort((a, b) => (a.modifyTime ??
              DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo((b.modifyTime ?? DateTime.fromMillisecondsSinceEpoch(0))));

      items = items.sublist(keepRecordings, items.length - 1);

      for (var item in items) {
        print("    Deleting ${item.name}");
        ftpConnect.deleteFile(item.name);
      }
    }
  }

  try {
    print("  Starting upload in background");
    ftpConnect.uploadFileWithRetry(file, pRetryCount: 3).then(
      (_) {
        print("  Successfully uploaded ${file.path}. Disconnecting.");
        ftpConnect.disconnect();
      },
    );
  } catch (e) {
    print("    Error while uploading file!\n$e");
  }
}
