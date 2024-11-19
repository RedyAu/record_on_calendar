import 'package:path/path.dart' as p;

import '../app_status.dart';
import '../calendar/calendar.dart';
import '../calendar/event.dart';
import '../globals.dart';
import '../recording/device.dart';
import '../recording/device_config.dart';
import '../recording/history.dart';
import '../utils/log.dart';

String statusPage() {
  bool recording = currentStatus.currentStatus == AppStatus.recording;
  Event? _current = getCurrentEvent();
  Event? _nextToday = getNextEvent(today: true);
  Event? _next = getNextEvent();

  Iterable<Event> _futureToday = events.where(
      (event) => event.start.isSameDate(DateTime.now()) && event.startWithOffset.isAfter(DateTime.now()));

  Iterable<Event> _future = events.where(
      (event) => !event.start.isSameDate(DateTime.now()) && event.startWithOffset.isAfter(DateTime.now()));

  Iterable<Event> _pastToday = events.where(
      (event) => event.start.isSameDate(DateTime.now()) && event.endWithOffset.isBefore(DateTime.now()));

  return """

<h1 class="mb-5" style="text-align: center">RecordOnCalendar $version</h1>
<div class="alert ${recording ? (currentError.isNotEmpty ? 'alert-warning' : 'alert-danger') : 'alert-light'}">
  ${recording ? '''
  <div class="spinner-grow spinner-grow-sm text-danger" role="status"></div> Felvétel – <b>$_current</b>''' : '💤  ${_next == null ? 'Nincsenek a jövőben rögzítésre jelölt események' : 'Következő esemény: <b>${_next.title}</b>, a felvétel kezdete: <i>${_next.startWithOffset.toFormattedString()}</i>'}'}
  ${currentError.isNotEmpty ? '<div><b>${currentError.reversed.take(5).map((e) => e.replaceAll('\n', '<br />')).join('<br />')}</b></div>' : ''}
</div>

<div class="row">
  <div class="col-lg-6">
    <div class="card mb-3">
      <div class="card-body">
        <h4 class="card-title">Naptár</h4>
        <button style="position: absolute; top: 10px; right: 10px" type="button" class="btn btn-primary"
          onclick="window.location.href='/updateCalendar'">Frissítés</button>
        <div><i>Utoljára frissítve: ${calendarLastUpdated?.toFormattedString() ?? "<b>Nem sikerült frissíteni a naptárt!</b>"}</i>
        </div>
        <div>Felvételre kijelölő RegEx kód: <code>${eventSelectedForRecordMatcher.pattern}</code></div>
        <h5 class="card-title mt-3">Mai elmúlt események</h5>
      </div>
      <div class="list-group list-group-flush">
        ${_pastToday.map((event) => (event, getStatusFor(event))).map((record) => """
        <div class="list-group-item ${record.$2 == EventStatus.successful ? 'text-success' : 'text-bg-danger'}">
          ${record.$1} — <b>${record.$2.name}</b></div>
        """).join()}
        ${_pastToday.isEmpty ? '<div class="list-group-item"><i>Nincs esemény</i></div>' : ''}
      </div>
      <div class="card-body">
        <h5 class="card-title mt-1">Mai következő események</h5>
      </div>
      <div class="list-group list-group-flush">
        <div class="card-header">
          ${_nextToday != null ? '<b>$_nextToday</b><span style="float: right"><i>${p.basenameWithoutExtension(getDeviceConfigurationFor(_nextToday, update: false).file.path)}</i></span>' : '<i>Nincs esemény</i>'}
        </div>
        ${(_nextToday != null && _futureToday.length > 1) ? """
        ${_futureToday.skip(1).map((event) => """
        <div class="list-group-item">
          ${event}<span style="float: right"><i>${p.basenameWithoutExtension(getDeviceConfigurationFor(event, update: false).file.path)}</i></span>
        </div>
        """).join()}
        """ : ''}
      </div>
      ${(_future.isNotEmpty) ? """
      <div class="card-body">
        <h5 class="card-title mt-1 mb-1">Következő 10 esemény</h5>
      </div>
      <div class="list-group list-group-flush">
        ${_future.take(10).map((event) => """
        <div class="list-group-item">${event}</div>
        """).join()}
      </div>
      """ : ''}
      <div class="card-body">
        <h5 class="card-title mt-1 mb-1">Statisztikák</h5>
        <div>Sikeres felvételek: ${history().values.where((element) => element == EventStatus.successful.name).length}</div>
        <div>Sikertelen felvételek: ${history().values.where((element) => element == EventStatus.failed.name).length}</div>
      </div>
    </div>
  </div>

  <div class="col col-lg-6">
    <div class="card mb-3">
      <div class="card-body">
        <button style="position: absolute; top: 10px; right: 10px" type="button" class="btn btn-primary"
          onclick="window.location.href='/updateDevices'">Frissítés</button>
        <h4 class="card-title mb-3">Eszköz konfigurációk</h4>
        ${deviceConfigurations.map((devices) => """
        <div class="list-group mb-2">
          <div class="list-group-item list-group-item-light"><b>${p.basenameWithoutExtension(devices.file.path)}</b> —
            <code>${devices.regex}</code> (${devices.format})</div>
          ${devices.list.map((device) => """
          <div class="list-group-item ${switch (device.state) {
                DeviceState.firstSeen => 'text-primary',
                DeviceState.enabled => 'text-success',
                DeviceState.disabled => 'text-secondary',
                DeviceState.enabledNotPresent => 'text-bg-danger'
              }}">
            ${device.name} ${device.customName != null ? '<i> (${device.customName})</i>' : ''} —
            <b>${device.state.name}</b>
          </div>
          """).join()}
        </div>
        """).join()}
      </div>
    </div>
  </div>
</div>

<div class="row">
  <div class="col-lg-6">
    <div class="card mb-3">
      <div class="card-body">
        <h4 class="card-title">Napló</h4>
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
  <div class="col-lg-6">
    <div class="card mb-3">
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
  document.addEventListener("DOMContentLoaded", function () {
    var logPre = document.getElementById('logPre');
    logPre.scrollTop = logPre.scrollHeight;
    var ffmpegPre = document.getElementById('ffmpegPre');
    ffmpegPre.scrollTop = ffmpegPre.scrollHeight;
  });
</script>
""";
}
