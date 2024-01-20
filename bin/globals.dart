import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import 'calendar/event.dart';
import 'recording/history.dart';

//TODO changeme
final String version = "4.3.1";

final Directory homeDir = Directory('RecordOnCalendar');
final File configFile = File(p.join(homeDir.path, 'config.yaml'));
final Directory deviceConfigurationsDir =
    Directory(p.join(homeDir.path, 'devices'));
final Directory ffmpegDir = Directory(p.join(homeDir.path, 'ffmpeg'));
late final Directory ffmpegVersionDir;
final File ffmpegExe = File(p.join(ffmpegVersionDir.path, 'ffmpeg.exe'));
final Directory recordingsDir = Directory(p.join(homeDir.path, 'recordings'));
final File historyFile = File(p.join(homeDir.path, 'history.json'));
final Directory logDir = Directory(p.join(homeDir.path, 'logs'));

bool debug = false;
int startEarlierByMinutes = 5;
int endLaterByMinutes = 30;
int keepRecordings = 0;
RegExp eventSelectedForRecordMatcher = RegExp(r".");
String googleCalendarId = "";
String googleApiKey = "";
int iCalUpdateFrequencyMinutes = 30;

String? smtpHost;
int smtpPort = 0;
String smtpUser = "";
String smtpPassword = "";

int? webPort;

bool dailyEmail = false;
List<String> dailyEmailRecipients = [];
String dailyEmailSenderName = "";
String dailyEmailSubject = "";
String dailyEmailContent = "";

bool calendarEmail = false;
List<String> calendarEmailRecipients = [];
String calendarEmailSenderName = "";
String calendarEmailSubject = "";
String calendarEmailContent = "";

List<Event> events = [];

HistoryData historyDataInstance = HistoryData();

final Map progressIndicator = {0: r'\', 1: '|', 2: '/', 3: '-'};

// https://stackoverflow.com/questions/52978195/comparing-only-dates-of-datetimes-in-dart
extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

extension GetFormattedString on DateTime {
  String toFormattedString() {
    // If time is exact, don't show seconds.
    if (second == 0 && millisecond == 0 && microsecond == 0) {
      return DateFormat('yyyy-MM-dd HH.mm').format(this);
    } else {
      return DateFormat('yyyy-MM-dd HH.mm.ss').format(this);
    }
  }
}

extension EntityWithModifiedDate on FileSystemEntity {
  ///Returns lastModifiedSync for File; for a Directory, returns lastModifiedSync of the first file in it\
  ///Returns epoch if can't return date.
  DateTime tryLastModifiedSync() {
    if (this is File) {
      try {
        return (this as File).lastModifiedSync();
      } catch (e) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    } else if (this is Directory) {
      try {
        return (this as Directory)
            .listSync()
            .whereType<File>()
            .first
            .lastModifiedSync();
      } catch (e) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    } else {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}

extension SanitizeForFilename on String {
  String getSanitizedForFilename() =>
      this.replaceAll(RegExp(r'[<>:"/\\|?*]'), "_");
}
