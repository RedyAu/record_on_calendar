import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';

import 'globals.dart';

uploadFile(File file) async {
  if (ftpHost == null) return;

  FTPConnect ftpConnect = FTPConnect(ftpHost!,
      user: ftpUsername ?? 'anonymous', pass: ftpPassword ?? '');

  print("Uploading file...");

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
        ftpConnect.deleteFile(item.name);
      }
    }
  }

  try {
    await ftpConnect.connect();
    ftpConnect
        .uploadFileWithRetry(file, pRetryCount: 3)
        .then((_) => ftpConnect.disconnect());
  } catch (e) {
    throw ("Error while uploading file!\n$e");
  }
}
