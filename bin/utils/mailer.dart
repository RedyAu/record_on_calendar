import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import 'event_class.dart';
import 'history.dart';
import 'globals.dart';
import 'log.dart';

sendDailyEmail() async {
  if (smtpHost == null) {
    log.print("\nEmail not set up, skipping sending daily update.");
    return;
  }
  log.print("\nSending daily update email.");

  final smtpServer = SmtpServer(
    smtpHost!,
    port: smtpPort,
    username: smtpUser,
    password: smtpPassword,
    ssl: true,
  );

  final message = Message()
    ..from = Address(smtpUser, smtpEmailSenderName)
    ..recipients.addAll(smtpEmailRecipients)
    ..subject = smtpEmailSubject
    ..text = renderEmailContent(smtpEmailContent);

  send(message, smtpServer).then((value) => "  Email sent.\n$value");
}

///Replacements:
/// - `[today list]` List of today's recordings, and their state
/// - `[future list]` List of future recordings
/// - `[time]` Current time in ISO format
/// - `[stat - success count]` Count of successful recordings in log
/// - `[stat - failed count]` Count of failed recordings in log
String renderEmailContent(String template) {
  template = template.replaceFirst(
    '[today list]',
    events.reversed
        .where(
          (element) => element.start.isSameDate(DateTime.now()),
        )
        .map(
          (e) => "$e\n  ${e.getStatus().name}",
        )
        .join("\n"),
  );
  List<Event> futureEvents = events.reversed
      .where(
        (element) => element.start.isAfter(DateTime.now()),
      )
      .toList();
  template = template.replaceFirst(
    '[future list]',
    futureEvents.isNotEmpty
        ? futureEvents
            .sublist(
              0,
              (futureEvents.length > 5) ? 5 : (futureEvents.length - 1),
            )
            .map((e) => "$e")
            .join("\n")
        : '---',
  );
  template =
      template.replaceFirst('[time]', DateTime.now().toFormattedString());
  template = template.replaceFirst(
      '[stat - success count]',
      history()
          .values
          .where((element) => element == "successful" || element == "uploaded")
          .length
          .toString());
  template = template.replaceFirst(
      '[stat - failed count]',
      history()
          .values
          .where((element) => element == "failed")
          .length
          .toString());

  return template;
}
