import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

import '../globals.dart';
import 'page.dart';

void startServer() async {
  if (webPort == null) {
    print('''

Web port is is not defined, won't start server.
If you would like to see a web status page, please define a web port in config.yaml
''');
    return;
  }

  var handler =
      const Pipeline().addHandler(_echoRequest);
  var server = await serve(handler, 'localhost', webPort!);
  server.autoCompress = true;

  print('''

Web status page available at http://${server.address.host}:${server.port}
''');
}

Response _echoRequest(Request request) => Response.ok(
      pageTemplate(statusPage()),
      headers: {
        'Content-Type': 'text/html; charset=UTF-8',
      },
    );

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
    <div class="alert alert-secondary">
      <div class="spinner-border spinner-border-sm text-secondary" role="status"></div>
      <span id="countdown">5</span>
    </div>
  </div>
  <script>
    var refreshInterval = 4; // Refresh page every 5 seconds
    var countdown = document.getElementById('countdown');
    var remaining = refreshInterval;

    function updateCountdownAndRefreshPage() {
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
