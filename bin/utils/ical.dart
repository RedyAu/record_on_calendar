import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:icalendar_parser/icalendar_parser.dart';

import 'Event.dart';
import 'ftp.dart';
import 'globals.dart';

import 'recording.dart';

Future<Event?> getNext() async {
  try {
    return events
        .lastWhere((event) => event.startWithOffset().isAfter(DateTime.now()));
  } catch (e) {
    return null;
  }
}

Future<List<Event>> getCurrents() async {
  return events
      .where((event) =>
          event.startWithOffset().isBefore(DateTime.now()) &&
          event.endWithOffset().isAfter(DateTime.now()))
      .toList();
}

Future updateICal() async {
  events = [];
  print("\n\n\n\n${DateTime.now().toIso8601String()} | Updating Calendar");
  print("  Downloading");
  var req = await get(iCalUri);
  String iCalString = req.body;

  print("  Parsing");
  ICalendar iCalendar = ICalendar.fromString(iCalString);
  for (Map vEvent in iCalendar.data.where((data) => data["type"] == "VEVENT")) {
    var event = Event(
        vEvent["uid"],
        DateTime.parse((vEvent["dtstart"] as IcsDateTime).dt).toLocal(),
        DateTime.parse((vEvent["dtend"] as IcsDateTime).dt).toLocal(),
        vEvent["summary"],
        vEvent["description"] ?? "");
    if (matchEventName.hasMatch(event.title + event.description))
      events.add(event);
  }
  events.sort((a, b) => b.start.compareTo(a.start));
  print("  Done. Got ${events.length} items.");
}
