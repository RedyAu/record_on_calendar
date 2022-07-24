import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:yaml/yaml.dart';

import '../globals.dart';
import 'log.dart';

class AudioInput {
  String id;
  String name;
  String? _fileName;
  String get fileName => (_fileName ?? name).getSanitizedForFilename();
  bool enabled = false;

  String toString() => "AudioInput($name; $id; $fileName)";

  String toYamlSnippet({bool enabled = false}) => """
$name:
  filename: ~
  enabled: $enabled
  id: '$id'
""";

  factory AudioInput.fromJson(String name, Map json) {
    try {
      return AudioInput(json['id'], name, json['filename'], json['enabled']);
    } catch (e, s) {
      throw "Couldn't read properties of audio device $name!\nError: $e\nPlease check the tracks.yaml file\n$s";
    }
  }

  AudioInput(this.id, this.name, [this._fileName, this.enabled = false]);
}

List<AudioInput> inputs = [];
List<AudioInput> detectedInputs = [];

void main() async {
  inputs = getCurrentInputs();
  print(generateTracksYaml());
}

String generateTracksYaml() {
  return ("""
# These are the audio devices the program detected in your computer.
# Please configure them.
# If you remove a device, it will not be removed from here. If you add a device, it will be added at the top for you.

# EXAMPLE:

# Example Microphone 1: # Human readable name of the input (this shows up in Windows)
#   filename: front # You can specify a filename for this track. Leave on '~' to use the name of the device as track name.
#   enabled: true # Set to true to record
#   id: 'xxxxxxxxxxxx' # Used internally, don't change

""" +
      inputs.map((e) => e.toYamlSnippet()).join('\n'));
}

void readTracksFile() {
  Map data;
  try {
    data = loadYaml(tracksFile.readAsStringSync());
  } catch (e, s) {
    throw "Couln't load tracks.yaml! Delete file and re-run the program to generate a new one.\nError:$e\n$s";
  }
  getCurrentInputs();
}

List<AudioInput> getCurrentInputs() {
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
  return _inputs;
}
