import 'package:http/http.dart';
import 'package:icalendar_parser/icalendar_parser.dart';

import 'event_class.dart';
import 'globals.dart';
import 'log.dart';

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
  //log.print("\n\n\n\n${DateTime.now().getFormattedString()} | Updating Calendar");
  //log.print("  Downloading");
  try {
    var req = await get(iCalUri).timeout(Duration(seconds: 30));
    String iCalString = req.body;

    //log.print("  Parsing");
    ICalendar iCalendar = ICalendar.fromString(iCalString);
    for (Map vEvent
        in iCalendar.data.where((data) => data["type"] == "VEVENT")) {
      var event = Event(
          vEvent["uid"],
          DateTime.parse((vEvent["dtstart"] as IcsDateTime).dt).toLocal(),
          DateTime.parse((vEvent["dtend"] as IcsDateTime).dt).toLocal(),
          vEvent["summary"],
          vEvent["description"] ?? "");
      if (matchEventName.hasMatch(event.title + event.description)) {
        events.add(event);
      }
    }
    // HACK remove duplicates (convert to Set, and then back)
    events = [
      ...{...events}
    ];

    events.sort((a, b) => b.start.compareTo(a.start));

    log.print(
        "\n\nUpdated calendar. Got ${events.length} events marked for recording.");
  } catch (e, s) {
    log.print(
        "Exception occured while updating calendar: $e\nContinuing with already downloaded events.\n$s");
  }
}
