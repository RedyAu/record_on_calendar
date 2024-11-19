import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

import '../calendar/calendar.dart';
import '../globals.dart';
import '../recording/device_config.dart';
import '../utils/log.dart';
import 'page_hu.dart';

void startServer() async {
  if (webPort == null) {
    logger.log('''

Web port is is not defined, won't start server.
If you would like to see a web status page, please define a web port in config.yaml
''');
    return;
  }
  try {
    var handler = const Pipeline().addHandler(requestHandler);
    var server = await serve(handler, 'localhost', webPort!);
    server.autoCompress = true;

    logger.log('''

Web status page available at http://${server.address.host}:${server.port}
''');
  } catch (e, s) {
    logger.log('Error while starting status page server, continuing...\n$e\n$s', true);
  }
}

DateTime lastUpdate = DateTime.now();

Future<Response> requestHandler(Request request) async {
  if (lastUpdate.isBefore(DateTime.now().add(Duration(seconds: 5)))) {
    if (request.url.path.contains('updateCalendar')) {
      await updateGoogleCalendar();
      return Response.found('/');
    } else if (request.url.path.contains('updateDevices')) {
      updateDeviceConfigurations();
      return Response.found('/');
    }
  }
  return Response.ok(
    pageTemplate(statusPage()),
    headers: {
      'Content-Type': 'text/html; charset=UTF-8',
    },
  );
}

String pageTemplate(String content) => '''
<!DOCTYPE html>
<html data-bs-theme="dark">

<head>
  <title>RecordOnCalendar $version</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet"
    integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"
    integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL"
    crossorigin="anonymous"></script>
</head>

<body>
  <div class="container mt-5">
    $content
  <div>
  <div class="position-fixed top-0 end-0 p-3" style="z-index: 1030;">
    <div class="alert alert-secondary" id="countdown-alert">
      <div class="spinner-border spinner-border-sm text-secondary" role="status" id="spinner-icon"></div>
      <span id="close-icon" style="cursor: pointer;">❌</span>
      <span id="countdown">5</span>
    </div>
  </div>
  <style>
    #close-icon {
      display: none;
    }
    #countdown-alert:hover #spinner-icon {
      display: none;
    }
    #countdown-alert:hover #close-icon {
      display: inline-block;
    }
  </style>
  <script>
    var refreshInterval = 4; // Refresh page every 5 seconds
    var countdown = document.getElementById('countdown');
    var remaining = refreshInterval;
    var refreshDisabled = false;

    countdown.addEventListener('click', function() {
      refreshDisabled = true;
      document.getElementById('countdown-alert').style.display = 'none';
    });

    var countdownAlert = document.getElementById('countdown-alert');
    countdownAlert.addEventListener('click', function() {
      refreshDisabled = true;
      countdownAlert.style.display = 'none';
    });

    function updateCountdownAndRefreshPage() {
      if (refreshDisabled) return;
      countdown.textContent = remaining.toString();
      remaining--;

      if (remaining < 0) {
        location.reload();
      }
    }

    setInterval(updateCountdownAndRefreshPage, 1000);
  </script>
</body>

</html>
''';
