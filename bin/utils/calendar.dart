import 'package:http/http.dart';
import 'package:icalendar_parser/icalendar_parser.dart';

import 'email.dart';
import 'recordable.dart';
import '../globals.dart';
import 'log.dart';

Recordable? getNext() {
  try {
    return events
        .lastWhere((event) => event.startWithOffset().isAfter(DateTime.now()));
  } catch (e) {
    return null;
  }
}

List<Recordable> getCurrents() {
  return events
      .where((event) =>
          event.startWithOffset().isBefore(DateTime.now()) &&
          event.endWithOffset().isAfter(DateTime.now()))
      .toList();
}

Future updateICal() async {
  //log.print("\n\n\n\n${DateTime.now().getFormattedString()} | Updating Calendar");
  log.print("\n\n${DateTime.now().toFormattedString()} | Updating Calendar");

  int nextEventsHash = events.reversed
      .where(
        (element) => element.start.isAfter(DateTime.now()),
      )
      .join()
      .hashCode;

  try {
    var req = await get(iCalUri).timeout(Duration(seconds: 30));
    String iCalString = req.body;

    List<Recordable> _events = [];

    //log.print("  Parsing");
    ICalendar iCalendar = ICalendar.fromString(iCalString);

    for (Map vEvent
        in iCalendar.data.where((data) => data["type"] == "VEVENT")) {
      if (!(vEvent["rrule"] == null || vEvent["rrule"] == "")) {
        //! Skip events with recursion data - recursion is not calculated.
        continue;
      }

      var event = Recordable(
          vEvent["uid"],
          DateTime.parse((vEvent["dtstart"] as IcsDateTime).dt).toLocal(),
          DateTime.parse((vEvent["dtend"] as IcsDateTime).dt).toLocal(),
          vEvent["summary"],
          vEvent["description"] ?? "");
      if (matchEventName.hasMatch(event.title + event.description)) {
        _events.add(event);
      }
    }
    // remove duplicates (convert to Set, and then back)
    _events = [
      ...{..._events}
    ];

    _events.sort((a, b) => b.start.compareTo(a.start));

    events = _events;

    log.print("\nGot ${events.length} events marked for recording.");
  } catch (e, s) {
    log.print(
        "Exception occured while updating calendar: $e\nContinuing with already downloaded events.\n$s");
  }

  int updatedNextEventsHash = events.reversed
      .where(
        (element) => element.start.isAfter(DateTime.now()),
      )
      .join()
      .hashCode;

  if (nextEventsHash != updatedNextEventsHash) {
    sendCalendarEmail();
  }
}
