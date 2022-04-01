//import 'dart:convert';
import 'dart:io';

import 'ical.dart';

final String version = "1.0.0";
final String ps = Platform.pathSeparator;
final Directory homeDir = Directory('RecordOnCalendar');
final File configFile = File('${homeDir.path}${ps}config.txt');
final Directory soxDir = Directory('${homeDir.path}${ps}sox');
final Directory soxVersionDir = Directory('${soxDir.path}${ps}sox-14.4.1');
final File soxExe = File('${soxVersionDir.path}${ps}sox.exe');
final File recordedListFile = File('${homeDir.path}${ps}recorded.dat');
final Directory recordingsDir = Directory('${homeDir.path}${ps}recordings');

int startEarlierByMinutes = 5;
int endLaterByMinutes = 30;
int keepRecordings = 0;
RegExp matchEventName = RegExp(r".");
Uri iCalUri = Uri();
String? ftpUsername;
String? ftpPassword;
String? ftpHost;
int iCalUpdateFrequencyMinutes = 30;

bool iCalUpdating = false;

List<Event> events = [];

exitWithPrompt(int code) {
  print(
      "\n\n\n\n==================================\nProgram exited with code $code\nPress enter to close.");
  stdin.readLineSync();
  exit(code);
}
