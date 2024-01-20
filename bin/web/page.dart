import '../app_status.dart';
import '../calendar/calendar.dart';
import '../calendar/event.dart';
import '../globals.dart';
import '../recording/history.dart';
import '../utils/log.dart';

String statusPage() {
  bool recording = currentStatus.currentStatus == AppStatus.recording;
  Event? _current = getCurrentEvent();
  Event? _next = getNextEvent(today: true);

  Iterable<Event> _nextToday = events.where((event) =>
      event.start.isSameDate(DateTime.now()) &&
      event.startWithOffset.isAfter(DateTime.now()));

  Iterable<Event> _nextFuture = events.where((event) =>
      !event.start.isSameDate(DateTime.now()) &&
      event.startWithOffset.isAfter(DateTime.now()));

  Iterable<Event> _pastToday = events.where((event) =>
      event.start.isSameDate(DateTime.now()) &&
      event.endWithOffset.isBefore(DateTime.now()));

  return """

<h1 class="mb-5" style="text-align: center">RecordOnCalendar $version</h1>
<div class="alert ${recording ? (currentError.isNotEmpty ? 'alert-warning' : 'alert-danger') : 'alert-light'}">
  ${recording ? '''
  <div class="spinner-grow spinner-grow-sm text-danger" role="status"></div> Recording — <b>$_current</b>''' : '💤  Idling...'}
  ${currentError.isNotEmpty ? '<div><b>${currentError.reversed.take(5).map((e) => e.replaceAll('\n', '<br />')).join('<br />')}</b></div>' : ''}
</div>

<div class="row">
  <div class="col-lg-6 mb-3">
    <div class="card">
      <div class="card-body">
        <h4 class="card-title">Calendar</h4>
        <div><i>Last updated: ${calendarLastUpdated?.toFormattedString() ?? "<b>Couldn't update calendar!</b>"}</i></div>
        <h5 class="card-title mt-4 mb-1">Next up today</h5>
      </div>
      <div class="list-group list-group-flush">
      <div class="card-header">
        ${_next ?? '<i>No more events today!</i>'}
      </div>
    ${(_next != null && _nextToday.length > 1) ? """
      ${_nextToday.skip(1).map((event) => """
        <div class="list-group-item">${event}</div>
      """).join()}
    """ : ''}
      </div>
    ${(_nextFuture.isNotEmpty) ? """
      <div class="card-body">
        <h5 class="card-title mt-1 mb-1">Future 10 events</h5>
      </div>
      <div class="list-group list-group-flush">
      ${_nextFuture.take(10).map((event) => """
        <div class="list-group-item">${event}</div>
        """).join()}
      </div>
    """ : ''}
    </div>
  </div>

  <div class="col col-lg-6 mb-3">
    <div class="card">
      <div class="card-body">
        <h4 class="card-title">History</h4>
        <h5 class="card-title mt-4 mb-1">Past events today</h5>
      </div>
      <div class="list-group list-group-flush">
      ${_pastToday.map((event) => (event, getStatusFor(event))).map((record) => """
        <div class="list-group-item ${record.$2 == EventStatus.successful ? 'text-success' : 'text-bg-danger'}">${record.$1} — <b>${record.$2.name}</b></div>
    """).join()}
      </div>
    </div>
  </div>
</div>
<div class="row">
  <div class="col-lg-6 mb-3">
    <div class="card">
      <div class="card-body">
        <h4 class="card-title">Log</h4>
        <p>
          <pre style="overflow-y: auto; height: 500px;" id="logPre">
            <code>
${lastLog.join('<br />').replaceAll('\n', '<br />')}
            </code>
          </pre>
        </p>
      </div>
    </div>
  </div>
  <div class="col-lg-6 mb-3">
    <div class="card">
      <div class="card-body">
        <h4 class="card-title">FFmpeg</h4>
        <p>
          <pre style="overflow-y: auto; height: 500px;" id="ffmpegPre">
            <code>
${ffmpegOutput.map((e) => """<span class="${e.$2 ? 'text-warning' : ''}">${e.$1}</span>""").join()}
            </code>
          </pre>
        </p>
      </div>
    </div>
  </div>
</div>
<script>
  document.addEventListener("DOMContentLoaded", function() {
    var logPre = document.getElementById('logPre');
    logPre.scrollTop = logPre.scrollHeight;
    var ffmpegPre = document.getElementById('ffmpegPre');
    ffmpegPre.scrollTop = ffmpegPre.scrollHeight;
  });
</script>
""";
}