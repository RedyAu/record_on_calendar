//import 'dart:convert';
import 'dart:io';

import 'Event.dart';
import 'LogData.dart';

final String version = "1.1.0";
final String ps = Platform.pathSeparator;
final Directory homeDir = Directory('RecordOnCalendar');
final File configFile = File('${homeDir.path}${ps}config.txt');
final Directory soxDir = Directory('${homeDir.path}${ps}sox');
final Directory soxVersionDir = Directory('${soxDir.path}${ps}sox-14.4.1');
final File soxExe = File('${soxVersionDir.path}${ps}sox.exe');
final File recordedListFile = File('${homeDir.path}${ps}recorded.dat');
final Directory recordingsDir = Directory('${homeDir.path}${ps}recordings');
final File logFile = File(homeDir.path + ps + "log.json");

int startEarlierByMinutes = 5;
int endLaterByMinutes = 30;
int keepRecordings = 0;
RegExp matchEventName = RegExp(r".");
Uri iCalUri = Uri();
String? ftpUsername;
String? ftpPassword;
String? ftpHost;
int iCalUpdateFrequencyMinutes = 30;

String? smtpHost;
int smtpPort = 0;
String smtpUser = "";
String smtpPassword = "";
String smtpEmailSenderName = "";
List<String> smtpEmailRecipients = [];
String smtpEmailSubject = "";
String smtpEmailContent = "";

bool iCalUpdating = false;

List<Event> events = [];

LogData logDataInstance = LogData();

exitWithPrompt(int code) {
  print(
      "\n\n\n\n==================================\nProgram exited with code $code\nPress enter to close.");
  stdin.readLineSync();
  exit(code);
}

// https://stackoverflow.com/questions/52978195/comparing-only-dates-of-datetimes-in-dart
extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
