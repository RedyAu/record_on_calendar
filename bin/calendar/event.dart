import '../globals.dart';

class Event {
  String uid;
  DateTime start;
  DateTime end;
  String title;
  String description;

  Event(this.uid, this.start, this.end, this.title, this.description);

  String get fileName => '${start.toFormattedString()} - $title'.getSanitizedForFilename();

  //! Overrides and fields

  @override
  int get hashCode => '$uid${start.toIso8601String()}'.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    bool result =
        other is Event && '${other.uid}${other.start.toIso8601String()}' == '$uid${start.toIso8601String()}';
    return result;
  }

  @override
  String toString() => "${start.toFormattedString()} | $title";

  ///Returns start time subtracted with global start earlier offset
  DateTime get startWithOffset => start.subtract(Duration(minutes: startEarlierByMinutes));

  ///Returns end time added with global end alter offset
  DateTime get endWithOffset => end.add(Duration(minutes: endLaterByMinutes));
}
