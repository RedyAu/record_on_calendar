import 'package:googleapis/calendar/v3.dart' as g;
import 'package:googleapis_auth/googleapis_auth.dart';

import '../globals.dart';
import '../utils/email.dart';
import 'event.dart';
import '../utils/log.dart';

List<Event> getNextXEvents(int x) {
  return events.where((event) => event.startWithOffset.isAfter(DateTime.now())).take(x).toList();
}

Event? getNextEvent({bool today = false}) {
  try {
    if (today) {
      return events.firstWhere(
          (event) => event.startWithOffset.isAfter(DateTime.now()) && event.start.isSameDate(DateTime.now()));
    } else {
      return events.firstWhere((event) => event.startWithOffset.isAfter(DateTime.now()));
    }
  } catch (e) {
    return null;
  }
}

Event? getCurrentEvent() {
  try {
    return events.lastWhere((element) =>
        element.startWithOffset.isBefore(DateTime.now()) && element.endWithOffset.isAfter(DateTime.now()));
  } catch (_) {
    return null;
  }
}

DateTime? calendarLastUpdated;

Future updateGoogleCalendar() async {
  logger.log("\n${DateTime.now().toFormattedString()} | Updating Calendar");

  int nextEventsHash =
      events.where((element) => element.start.isAfter(DateTime.now())).take(10).join().hashCode;

  try {
    List<Event> _events = [];

    g.CalendarApi calendar = await g.CalendarApi(clientViaApiKey(googleApiKey));

    for (g.Event gEvent in (await calendar.events.list(
      googleCalendarId,
      singleEvents: true, // THANK YOU GOOGLE 💖
      timeMin: DateTime.now().subtract(Duration(days: 1)).toUtc(),
      maxResults: 100,
      orderBy: "startTime",
      timeZone: "Europe/Budapest",
    ))
        .items!) {
      try {
        var event = Event(
          gEvent.iCalUID!,
          gEvent.start!.dateTime!.toLocal(),
          gEvent.end!.dateTime!.toLocal(),
          gEvent.summary!,
          gEvent.description ?? "",
        );
        if (eventSelectedForRecordMatcher.hasMatch(event.title + '\n' + event.description)) {
          _events.add(event);
        }
      } catch (e) {
        logger.log("Couldn't parse an event from the calendar, skipping: $e");
        continue;
      }
    }

    _events.sort((a, b) => a.title.compareTo(b.title));
    _events.sort((a, b) => a.start.compareTo(b.start));

    events.clear();
    events.addAll(_events);

    logger.log("Got ${events.length} events marked for recording.");

    calendarLastUpdated = DateTime.now();
  } catch (e, s) {
    logger
        .log("Exception occured while updating calendar: $e\nContinuing with already downloaded events.\n$s");
  }

  int updatedNextEventsHash =
      events.where((element) => element.start.isAfter(DateTime.now())).take(10).join().hashCode;

  if (nextEventsHash != updatedNextEventsHash) {
    sendCalendarEmail();
  }
}
