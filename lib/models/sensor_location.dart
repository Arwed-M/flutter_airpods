/// An object that indicates the location of the device
/// motion sensor that is providing the data.
enum SensorLocation {
  /// Raw values are defined as in [CMDeviceMotionSensorLocation]
  /// The default location for devices that don't specify a location.
  defaultLocation(0),

  /// The headphone's left ear cup or bud.
  headphoneLeft(1),

  /// The headphone's right ear cup or bud.
  headphoneRight(2);

  const SensorLocation(this.value);

  final int value;

  /// Returns a human-readable description of the sensor location
  String get description {
    switch (this) {
      case SensorLocation.defaultLocation:
        return 'Default';
      case SensorLocation.headphoneLeft:
        return 'Left AirPod';
      case SensorLocation.headphoneRight:
        return 'Right AirPod';
    }
  }

  /// Creates a SensorLocation from an integer value
  static SensorLocation fromValue(int value) {
    switch (value) {
      case 0:
        return SensorLocation.defaultLocation;
      case 1:
        return SensorLocation.headphoneLeft;
      case 2:
        return SensorLocation.headphoneRight;
      default:
        return SensorLocation.defaultLocation;
    }
  }
}
