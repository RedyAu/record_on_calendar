import '../globals.dart';

enum DeviceState {
  enabledNotPresent,
  enabled,
  disabled,
  firstSeen,
}

class Device {
  String? id;
  String name;
  String? customName;
  String get fileName => (customName ?? name).getSanitizedForFilename();
  DeviceState state;

  @override
  String toString() => "${(customName == null) ? "" : "$customName: "}$name";

  String yaml() => """
  $name:
    fileName: ${customName ?? '~'}
    record: ${state == DeviceState.enabled || state == DeviceState.enabledNotPresent}
"""; //! IMPORTANT: don't change indentation

  factory Device.fromJson(String name, Map json) {
    try {
      return Device(
        name,
        json['record'] ? DeviceState.enabled : DeviceState.disabled,
        customName: json['fileName'],
      );
    } catch (e, s) {
      throw "Couldn't read properties of audio device $name!\nError: $e\nPlease check the tracks.yaml file\n$s";
    }
  }

  Device(this.name, this.state, {this.customName, this.id});

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is Device && other.name == name;
  }
}
