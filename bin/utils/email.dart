import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import 'recordable.dart';
import 'history.dart';
import '../globals.dart';
import 'log.dart';

sendDailyEmail() async {
  if (smtpHost == null || !dailyEmail) {
    log.print("\nEmail disabled, skipping sending daily email.");
    return;
  }
  log.print("\nSending daily email.");

  sendEmail(dailyEmailSenderName, dailyEmailRecipients, dailyEmailSubject,
      renderEmailContent(dailyEmailContent));
}

sendCalendarEmail() async {
  if (smtpHost == null || !calendarEmail) {
    log.print("\nEmail disabled, skipping sending calendar update email.");
    return;
  }
  log.print("\nSending calendar update email.");

  sendEmail(calendarEmailSenderName, calendarEmailRecipients,
      calendarEmailSubject, renderEmailContent(calendarEmailContent));
}

sendEmail(String senderName, List<String> recipients, String subject,
    String content) async {
  final smtpServer = SmtpServer(
    smtpHost!,
    port: smtpPort,
    username: smtpUser,
    password: smtpPassword,
    ssl: true,
  );

  final message = Message()
    ..from = Address(smtpUser, senderName)
    ..recipients.addAll(recipients)
    ..subject = subject
    ..text = renderEmailContent(content);

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
  List<Recordable> futureEvents = events.reversed
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
              (futureEvents.length > 10) ? 10 : futureEvents.length,
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
          .where((element) =>
              element == EventStatus.successful.name ||
              element == EventStatus.uploaded.name)
          .length
          .toString());
  template = template.replaceFirst(
      '[stat - failed count]',
      history()
          .values
          .where((element) => !(element == EventStatus.successful.name ||
              element == EventStatus.uploaded.name))
          .length
          .toString());

  return template;
}
