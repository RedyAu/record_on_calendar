//import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';

import 'utils/recordable.dart';
import 'utils/history.dart';

final String version = "2.0.0";

final String ps = Platform.pathSeparator;

final Directory homeDir = Directory('RecordOnCalendar');
final File configFile = File('${homeDir.path}${ps}config.yaml');
final Directory soxDir = Directory('${homeDir.path}${ps}sox');
final Directory soxVersionDir = Directory('${soxDir.path}${ps}sox-14.4.1');
final File soxExe = File('${soxVersionDir.path}${ps}sox.exe');
final File recordedListFile = File('${homeDir.path}${ps}recorded.dat');
final Directory recordingsDir = Directory('${homeDir.path}${ps}recordings');
final File historyFile = File(homeDir.path + ps + "history.json");
final Directory logDir = Directory(homeDir.path + ps + 'logs');

int startEarlierByMinutes = 5;
int endLaterByMinutes = 30;
int keepRecordings = 0;
RegExp matchEventName = RegExp(r".");
Uri iCalUri = Uri();
int iCalUpdateFrequencyMinutes = 30;

String? smtpHost;
int smtpPort = 0;
String smtpUser = "";
String smtpPassword = "";

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

List<Recordable> events = [];

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
