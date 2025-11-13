# Flutter AirPods Plugin

[![pub package](https://img.shields.io/pub/v/flutter_airpods.svg)](https://pub.dev/packages/flutter_airpods)
[![pub points](https://img.shields.io/pub/points/flutter_airpods?color=2E8B57&label=pub%20points)](https://pub.dev/packages/flutter_airpods/score)

A Library for accessing AirPods data via CMHeadphoneMotionManager. Simplifies retrieval of information about currently connected AirPods with support for custom attitude reference frames.

It uses [CMHeadphoneMotionManager](https://developer.apple.com/documentation/coremotion/cmheadphonemotionmanager), and gathering information starts as soon as the user puts the AirPods into
the ear. Only iOS 14+ supports this functionality, so devices with a lower
version cannot use this package. Also, for Android currently, there are no comparable headphones
with that functionality, so there is no implementation for that platform.
Only AirPods (3. Generation), AirPods Pro, AirPods Max und Beats Fit Pro are supported!

## Features

- ✅ Real-time AirPods motion tracking (quaternion, pitch, roll, yaw)
- ✅ Gravity, user acceleration, and rotation rate data
- ✅ Magnetic field data with calibration accuracy
- ✅ **Custom attitude reference frames** (new!)
- ✅ Support for spatial audio-style relative orientation tracking
- ✅ Sensor location detection (left/right AirPod)

Below is the complete JSON data that you can expect:

```
{
    // The attitude of the device.

    // Returns a quaternion representing the device's attitude.

    quaternionY: 0.21538676246259386,
    quaternionX: -0.47675120121765957,
    quaternionW: 0.8522420297864675,
    quaternionZ: -0.0005364311021727928

    pitch: -0.9490214392332175,           // The pitch of the device, in radians.
    roll: 0.6807802035216475,             // The roll of the device, in radians.
    yaw: 0.3586524456166643,              // The yaw of the device, in radians.

    // The gravity acceleration vector expressed in the device's reference frame.

    gravityX: 0.3666117787361145,         // Gravity vector along the x-axis in G's
    gravityY: 0.8128458857536316,         // Gravity vector along the y-axis in G's
    gravityZ: -0.45263373851776123,       // Gravity vector along the z-axis in G's

    // The acceleration that the user is giving to the device.

    accelerationX: 0.005457472056150436,  // Acceleration along the x-axis in G's
    accelerationY: 0.01201944425702095,   // Acceleration along the y-axis in G's
    accelerationZ: -0.005634056404232979, // Acceleration along the z-axis in G's

    // The rotation rate of the device.

    rotationRateX: -0.0419556125998497,   // Rotation rate around the x-axis in radians per second
    rotationRateY: -0.01837937720119953,  // Rotation rate around the y-axis in radians per second
    rotationRateZ: 0.011555187404155731,  // Rotation rate around the z-axis in radians per second

    // Returns the magnetic field vector with respect to the device.

    magneticFieldAccuracy: -1,            // Indicates the calibration accuracy of a magnetic field estimate
    magneticFieldX: 0,                    // Magnetic field vector along the x-axis in microteslas
    magneticFieldY: 0,                    // Magnetic field vector along the y-axis in microteslas
    magneticFieldZ: 0,                    // Magnetic field vector along the z-axis in microteslas
    heading: 0,                           // This property contains a value in the range of 0.0 to 360.0 degrees.
                                          // A heading of 0.0 indicates that the attitude of the device matches the current reference frame.
    sensorLocation: 1                     // Indicates which AirPod is providing the motion data
                                          // 0 = Default, 1 = Left AirPod, 2 = Right AirPod
}
```

## Before you start!

1. Set the iOS Version of your project to at least `iOS 14`.

2. Inside of the `ios/Runner/Info.plist` you need to add `NSMotionUsageDescription` with a reason on why you want to use it:

```xml
<key>NSMotionUsageDescription</key>
<string>Get AirPods movement</string>
```

## Usage

To use this plugin, add `flutter_airpods` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/platform-integration/platform-channels).

### Basic Example

Here is a simple example of how to use this package:

```dart
import 'package:flutter_airpods/flutter_airpods.dart';

@override
Widget build(BuildContext context) {
  return StreamBuilder<DeviceMotionData>(
    stream: FlutterAirpods.getAirPodsDeviceMotionUpdates(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final data = snapshot.data!;
        return Column(
          children: [
            Text('Pitch: ${data.attitude.pitch}'),
            Text('Roll: ${data.attitude.roll}'),
            Text('Yaw: ${data.attitude.yaw}'),
          ],
        );
      } else {
        return const Text("Waiting for AirPods...");
      }
    },
  );
}
```

### Advanced Usage: Custom Reference Frames

The plugin supports custom attitude reference frames for precise orientation tracking. This is useful for applications like spatial audio, where you need the AirPods orientation relative to the iPhone.

#### Check Available Reference Frames

```dart
// Get available reference frames as a bitmask
final int availableFrames = await FlutterAirpods.availableAttitudeReferenceFrames;

// Check if a specific frame is available
if (CMAttitudeReferenceFrame.isFrameAvailable(
    availableFrames, 
    CMAttitudeReferenceFrame.xMagneticNorthZVertical)) {
  print('Magnetic north frame is available');
}

// Get list of available frame names
final frameNames = CMAttitudeReferenceFrame.getAvailableFrameNames(availableFrames);
print('Available frames: $frameNames');
```

#### Use a Specific Reference Frame

```dart
// Use magnetometer-corrected frame for stable yaw
FlutterAirpods.getAirPodsDeviceMotionUpdates(
  referenceFrame: CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical,
).listen((data) {
  print('Stable yaw: ${data.attitude.yaw}');
});

// Use magnetic north for compass applications
FlutterAirpods.getAirPodsDeviceMotionUpdates(
  referenceFrame: CMAttitudeReferenceFrame.xMagneticNorthZVertical,
).listen((data) {
  final heading = data.attitude.yaw * 180 / pi; // Convert to degrees
  print('Heading: $heading°');
});
```

#### Available Reference Frame Options

- `CMAttitudeReferenceFrame.xArbitraryZVertical` - Default, no magnetometer (may drift)
- `CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical` - ⭐ Recommended for most apps (stable yaw)
- `CMAttitudeReferenceFrame.xMagneticNorthZVertical` - Aligned to magnetic north
- `CMAttitudeReferenceFrame.xTrueNorthZVertical` - Aligned to true north (if available)

For detailed information about reference frames and how to compute relative attitude (similar to spatial audio), see [ATTITUDE_REFERENCE_FRAMES.md](ATTITUDE_REFERENCE_FRAMES.md).

## API Reference

### Methods

#### `FlutterAirpods.getAirPodsDeviceMotionUpdates({int? referenceFrame})`
Returns a stream of `DeviceMotionData` with real-time AirPods motion updates.

**Parameters:**
- `referenceFrame` (optional): A `CMAttitudeReferenceFrame` constant specifying the attitude reference frame to use.

**Returns:** `Stream<DeviceMotionData>`

#### `FlutterAirpods.availableAttitudeReferenceFrames`
Gets the available attitude reference frames supported by the device.

**Returns:** `Future<int>` - A bitmask of available reference frames

### Classes

#### `CMAttitudeReferenceFrame`
Contains constants for attitude reference frames and helper methods.

**Constants:**
- `xArbitraryZVertical` (1)
- `xArbitraryCorrectedZVertical` (2)
- `xMagneticNorthZVertical` (4)
- `xTrueNorthZVertical` (8)

**Methods:**
- `isFrameAvailable(int availableFrames, int frame)` - Check if a frame is available
- `getAvailableFrameNames(int availableFrames)` - Get human-readable frame names

## Example App

The example app demonstrates all features including:
- Real-time motion data display
- Reference frame selection
- Available frame detection

Run the example:
```bash
cd example
flutter run
```

## Platform Support

| Platform | Supported | Minimum Version |
|----------|-----------|----------------|
| iOS      | ✅        | iOS 14.0+      |
| macOS    | ✅        | macOS 14.0+    |
| Android  | ❌        | Not supported  |
| Web      | ❌        | Not supported  |
| Windows  | ❌        | Not supported  |
| Linux    | ❌        | Not supported  |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.


```
{
    // The attitude of the device.

    // Returns a quaternion representing the device's attitude.

    quaternionY: 0.21538676246259386,
    quaternionX: -0.47675120121765957,
    quaternionW: 0.8522420297864675,
    quaternionZ: -0.0005364311021727928

    pitch: -0.9490214392332175,           // The pitch of the device, in radians.
    roll: 0.6807802035216475,             // The roll of the device, in radians.
    yaw: 0.3586524456166643,              // The yaw of the device, in radians.

    // The gravity acceleration vector expressed in the device's reference frame.

    gravityX: 0.3666117787361145,         // Gravity vector along the x-axis in G's
    gravityY: 0.8128458857536316,         // Gravity vector along the y-axis in G's
    gravityZ: -0.45263373851776123,       // Gravity vector along the z-axis in G's

    // The acceleration that the user is giving to the device.

    accelerationX: 0.005457472056150436,  // Acceleration along the x-axis in G's
    accelerationY: 0.01201944425702095,   // Acceleration along the y-axis in G's
    accelerationZ: -0.005634056404232979, // Acceleration along the z-axis in G's

    // The rotation rate of the device.

    rotationRateX: -0.0419556125998497,   // Rotation rate around the x-axis in radians per second
    rotationRateY: -0.01837937720119953,  // Rotation rate around the y-axis in radians per second
    rotationRateZ: 0.011555187404155731,  // Rotation rate around the z-axis in radians per second

    // Returns the magnetic field vector with respect to the device.

    magneticFieldAccuracy: -1,            // Indicates the calibration accuracy of a magnetic field estimate
    magneticFieldX: 0,                    // Magnetic field vector along the x-axis in microteslas
    magneticFieldY: 0,                    // Magnetic field vector along the y-axis in microteslas
    magneticFieldZ: 0,                    // Magnetic field vector along the z-axis in microteslas
    heading: 0,                           // This property contains a value in the range of 0.0 to 360.0 degrees.
                                          // A heading of 0.0 indicates that the attitude of the device matches the current reference frame.
    sensorLocation: 1                     // Indicates which AirPod is providing the motion data
                                          // 0 = Default, 1 = Left AirPod, 2 = Right AirPod
}
```

## Before you start!

1. Set the iOS Version of your project to at least `iOS 14`.

2. Inside of the `ios/Runner/Info.plist` you need to add `NSMotionUsageDescription` with a reason on why you want to use it:

```
<key>NSMotionUsageDescription</key>
<string>Get AirPods movement</string>
```

## Usage

To use this plugin, add `flutter_airpods` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/platform-integration/platform-channels).

### Example

Here is an example of how to use this package:

```dart
@override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Airpods example app'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: StreamBuilder<DeviceMotionData>(
                stream: FlutterAirpods.getAirPodsDeviceMotionUpdates(),
                builder: (BuildContext context,
                    AsyncSnapshot<DeviceMotionData> snapshot) {
                  if (snapshot.hasData) {
                    return Text("${snapshot.data?.toJson()}");
                  } else {
                    return const Text("Waiting for incoming data...");
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
```
