import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../globals.dart';
import 'log.dart';

class AudioInput {
  String longName;
  String friendlyName;
  String? _fileName;
  String get fileName => (_fileName ?? friendlyName).getSanitizedForFilename();

  String toString() => "AudioInput($friendlyName; $longName; $fileName)";

  AudioInput(this.longName, this.friendlyName, [this._fileName]);
}

List<AudioInput> inputs = [];
List<AudioInput> enabledInputs = [];

void main() async {
  //TODO removeme
  await updateAudioInputs();
}

Future<void> updateAudioInputs() async {
  logger.print("Updating audio input device list...");

  String ffpmegOutput = Process.runSync(
          'ffmpeg', ['-list_devices', 'true', '-f', 'dshow', '-i', 'dummy'],
          stderrEncoding: Encoding.getByName('utf-8'))
      .stderr;

  List<String> allLines = ffpmegOutput
      .split('\n')
      .where(
        (element) => (element.startsWith('[dshow @')),
      )
      .map((e) => e.replaceAll(RegExp(r"\[dshow @.*\] "), ""))
      .toList();

  List<int> inputLines = allLines
      .where((e) => RegExp(r"\(audio").hasMatch(e))
      .map((e) => allLines.indexOf(e))
      .toList();

  List<AudioInput> _inputs = [];

  for (var i in inputLines) {
    //There must be a simpler way of doing this xd
    try {
      _inputs.add(AudioInput(
          RegExp(r'(?<=").*(?=")').firstMatch(allLines[i + 1])!.group(0)!,
          RegExp(r'(?<=").*(?=")').firstMatch(allLines[i])!.group(0)!));
    } catch (e, s) {
      logger.print("Error occured while getting an audio device: $e\n$s");
    }
  }

  inputs = _inputs;

  logger.print("  Got ${inputs.length} devices.");
}
