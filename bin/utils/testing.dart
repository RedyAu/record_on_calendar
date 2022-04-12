import 'dart:async';

import 'log.dart';

main() async {
  Timer.periodic(Duration(seconds: 5), (timer) {
    log.print("2" + DateTime.now().toString());
  });

  while (true) {
    log.print("1" + DateTime.now().toString());
    await Future.delayed(Duration(seconds: 3));
  }
}
