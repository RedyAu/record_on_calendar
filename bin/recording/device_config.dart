import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import '../calendar/event.dart';
import '../globals.dart';
import '../utils/log.dart';
import 'device.dart';

import 'package:path/path.dart' as p;

List<DeviceConfiguration> deviceConfigurations = [];

class DeviceConfiguration {
  File file;
  late String regex;
  late String format;

  DeviceConfiguration(this.file, this.regex, this.format);
  List<Device> list = [];

  List<Device> get toRecord =>
      list.where((element) => element.state == DeviceState.enabled).toList();

  factory DeviceConfiguration.fromFile(File file) {
    return DeviceConfiguration(file, "", "")..update();
  }

  void update() {
    logger.log("\nUpdating $file...");

    String tracksFileContent = file.readAsStringSync();

    Map data;
    List<Device> devicesInFile = [];
    if (tracksFileContent.length >= 1) {
      try {
        data = loadYaml(tracksFileContent);
      } catch (e, s) {
        throw "ERROR: Couldn't load $file! Delete it and re-run the program to generate a new one.\nError: $e\n$s";
      }

      try {
        if (data['devices'] != null) {
          data['devices'].forEach((key, value) {
            devicesInFile.add(Device.fromJson(key, value));
          });
        }
        format = data['format'];
        regex = data['regex'];
      } catch (e, s) {
        throw "ERROR: Couldn't parse an audio device in $file: $e\n$s";
      }
    }

    List<Device> devicesPresent = getPresentDevices();
    devicesInFile.forEach((element) {
      if (element.state == DeviceState.enabled &&
          !devicesPresent.contains(element)) {
        element.state = DeviceState.enabledNotPresent;
      }
    });

    Iterable<Device> allDevices = devicesPresent.followedBy(devicesInFile);

    list.clear();
    for (Device device in allDevices) {
      Device? alreadyInList = list
          .cast<Device?>()
          .firstWhere((element) => element == device, orElse: () => null);
      if (alreadyInList == null) {
        list.add(device);
      } else {
        if (alreadyInList.state.index > device.state.index) {
          alreadyInList.state = device.state;
        }
        if (device.customName == null && alreadyInList.customName != null) {
          device.customName = alreadyInList.customName;
        }
        if (device.customName != null && alreadyInList.customName == null) {
          alreadyInList.customName = device.customName;
        }
      }
    }

    logger.log("""
  Devices that will be recorded: ${list.where((element) => element.state == DeviceState.enabled).toList()}
  Devices marked for recording but not present: ${list.where((element) => element.state == DeviceState.enabledNotPresent).toList()}
  New devices you should configure: ${list.where((element) => element.state == DeviceState.firstSeen).toList()}""");

    if (toRecord.isEmpty) {
      logger.log(
          'WARNING: You have no present devices enabled in this configuration.');
    }
  }

  String get yaml => """
version: $version # Don't change this!

# This is the configuration file for the multitrack recording feature.
# You can edit this file while the program is running, and it will update automatically.

# FORMAT
# Specify the format of the output files. You can use any ffmpeg format.
format: "$format"

# EVENT-SPECIFIC TRACKS
# Record events that match this regex with the following tracks.
# You can make multiple track configurations. They will be matched in reverse alphabetical order. The first match will be used.
# If you want to match all events, use '.' - this is the default. Make sure to name the file with the default regex to be alphabetically first.
regex: "$regex"

# DEVICES - TRACKS
# These are the audio devices the FFmpeg detected in your computer.
# Please select which ones you want to record.
# If you remove an enabled device from the system, it does not get removed from here.
# EXAMPLE:
# devices:
#   Example Microphone 1:    # Name of the input (this shows up in your OS; don't change)
#     filename: John Guitar  # You can specify a filename for this track. Leave on '~' to use the name of the device as track name.
#     record: true           # Set to true to record

devices:
${list.map((e) => e.yaml()).join('\n')}""";
}

void updateDeviceConfigurations() {
  logger.log("\nUpdating all device configurations...");
  deviceConfigurationsDir.createSync(recursive: true);
  List<File> files = deviceConfigurationsDir
      .listSync()
      .whereType<File>()
      .where((element) => p.extension(element.path) == '.yaml')
      .toList();

  if (files.isEmpty) {
    logger.log(
        "No device configurations found. Creating default configuration...");
    File defaultConfig =
        File(p.join(deviceConfigurationsDir.path, '00-default.yaml'));
    defaultConfig.createSync(recursive: true);
    defaultConfig
        .writeAsStringSync(DeviceConfiguration(defaultConfig, '.', 'mp3').yaml);
    files.add(defaultConfig);
  }

  deviceConfigurations.clear();

  for (var file in files) {
    var devices = DeviceConfiguration.fromFile(file);
    deviceConfigurations.add(devices);
    devices.file.writeAsStringSync(devices.yaml);
  }

  deviceConfigurations.sort(
      (a, b) => p.basename(b.file.path).compareTo(p.basename(a.file.path)));
}

DeviceConfiguration getDeviceConfigurationFor(Event event,
    {bool update = true}) {
  deviceConfigurations.sort(
      (a, b) => p.basename(b.file.path).compareTo(p.basename(a.file.path)));

  for (DeviceConfiguration devices in deviceConfigurations) {
    if (update) {
      devices.update();
    }
    if (RegExp(devices.regex).hasMatch(event.title + event.description)) {
      if (update) {
        logger
            .log("  Using ${p.basename(devices.file.path)} for ${event.title}");
      }
      return devices;
    }
  }

  throw "ERROR: No device configuration matched for ${event.title}!\nPlease make sure to include a configuration file that matches all events with regex value '.'";
}

List<Device> getPresentDevices() {
  String ffpmegOutput = Process.runSync(ffmpegExe.path,
          ['-list_devices', 'true', '-f', 'dshow', '-i', 'dummy'],
          stderrEncoding: Encoding.getByName('utf-8'))
      .stderr;

  List<String> allLines = ffpmegOutput
      .split('\n')
      .where(
        (element) => (element.startsWith('[dshow @')),
      )
      .map((e) => e.replaceAll(RegExp(r"\[dshow @.*\] "), ""))
      .toList();

  List<int> deviceLines = allLines
      .where((e) => RegExp(r"\(audio").hasMatch(e))
      .map((e) => allLines.indexOf(e))
      .toList();

  List<Device> _inputs = [];

  for (var i in deviceLines) {
    //There must be a simpler way of doing this...
    try {
      _inputs.add(
        Device(
          RegExp(r'(?<=").*(?=")').firstMatch(allLines[i])!.group(0)!,
          DeviceState.firstSeen,
          id: RegExp(r'(?<=").*(?=")').firstMatch(allLines[i + 1])!.group(0)!,
        ),
      );
    } catch (e, s) {
      logger.log("Error occured while parsing audio device list: $e\n$s");
    }
  }
  return _inputs;
}
