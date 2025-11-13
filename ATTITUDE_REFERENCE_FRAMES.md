# Attitude Reference Frames

This document explains how to use attitude reference frames in the flutter_airpods plugin to get precise orientation data from AirPods, including how to get attitude relative to the iPhone (similar to spatial audio).

## Overview

The plugin now supports specifying a `CMAttitudeReferenceFrame` when starting device motion updates. This allows you to choose how the attitude (orientation) data should be calculated relative to different reference frames.

## Available Reference Frames

### 1. `xArbitraryZVertical` (Default)
- **Value**: `1`
- **Description**: Z axis is vertical (aligned with gravity), X axis points in an arbitrary direction in the horizontal plane
- **Use case**: Simple orientation tracking where only up/down matters
- **Pros**: Always available, no calibration needed
- **Cons**: Yaw (heading) can drift over time

### 2. `xArbitraryCorrectedZVertical` (Recommended)
- **Value**: `2`
- **Description**: Same as `xArbitraryZVertical` but uses magnetometer to improve long-term yaw accuracy
- **Use case**: Better orientation tracking with stable yaw
- **Pros**: More stable yaw than uncorrected, widely available
- **Cons**: Requires magnetometer, can be affected by magnetic interference

### 3. `xMagneticNorthZVertical`
- **Value**: `4`
- **Description**: Z axis is vertical, X axis points toward magnetic north
- **Use case**: Compass-aligned orientation, navigation applications
- **Pros**: Absolute heading reference
- **Cons**: Requires calibrated magnetometer, affected by magnetic interference

### 4. `xTrueNorthZVertical`
- **Value**: `8`
- **Description**: Z axis is vertical, X axis points toward true north (corrects for magnetic declination)
- **Use case**: Precise navigation requiring true north reference
- **Pros**: Most accurate heading reference
- **Cons**: May not be available on all devices/locations, requires location services

## Basic Usage

### 1. Check Available Reference Frames

Always check which reference frames are available on the device before using them:

```dart
import 'package:flutter_airpods/flutter_airpods.dart';

// Get available frames as a bitmask
final int availableFrames = await FlutterAirpods.availableAttitudeReferenceFrames;

// Check if a specific frame is available
if (CMAttitudeReferenceFrame.isFrameAvailable(
    availableFrames, 
    CMAttitudeReferenceFrame.xMagneticNorthZVertical)) {
  print('Magnetic north frame is available');
}

// Get list of available frame names
final List<String> frameNames = 
    CMAttitudeReferenceFrame.getAvailableFrameNames(availableFrames);
print('Available frames: $frameNames');
```

### 2. Start Motion Updates with Default Frame

```dart
// No reference frame specified - uses default (xArbitraryZVertical)
FlutterAirpods.getAirPodsDeviceMotionUpdates().listen((data) {
  print('Pitch: ${data.attitude.pitch}');
  print('Roll: ${data.attitude.roll}');
  print('Yaw: ${data.attitude.yaw}');
});
```

### 3. Start Motion Updates with Specific Frame

```dart
// Use magnetic north reference frame
FlutterAirpods.getAirPodsDeviceMotionUpdates(
  referenceFrame: CMAttitudeReferenceFrame.xMagneticNorthZVertical,
).listen((data) {
  print('Heading (yaw): ${data.attitude.yaw}'); // Now relative to magnetic north
  print('Pitch: ${data.attitude.pitch}');
  print('Roll: ${data.attitude.roll}');
});
```

### 4. Choose Best Available Frame

```dart
Future<int?> getBestAvailableFrame() async {
  final frames = await FlutterAirpods.availableAttitudeReferenceFrames;
  
  // Prefer true north > magnetic north > corrected > arbitrary
  if (CMAttitudeReferenceFrame.isFrameAvailable(
      frames, CMAttitudeReferenceFrame.xTrueNorthZVertical)) {
    return CMAttitudeReferenceFrame.xTrueNorthZVertical;
  } else if (CMAttitudeReferenceFrame.isFrameAvailable(
      frames, CMAttitudeReferenceFrame.xMagneticNorthZVertical)) {
    return CMAttitudeReferenceFrame.xMagneticNorthZVertical;
  } else if (CMAttitudeReferenceFrame.isFrameAvailable(
      frames, CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical)) {
    return CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical;
  } else {
    return CMAttitudeReferenceFrame.xArbitraryZVertical;
  }
}

// Use it
final bestFrame = await getBestAvailableFrame();
FlutterAirpods.getAirPodsDeviceMotionUpdates(
  referenceFrame: bestFrame,
).listen((data) {
  // Process motion data
});
```

## Getting Attitude Relative to iPhone (Spatial Audio)

To get the AirPods attitude relative to the iPhone (similar to how spatial audio works), you need to:

1. Start device motion updates on **both** the iPhone and AirPods using the **same reference frame**
2. Compute the relative attitude in Dart or on the native side

### Approach 1: Compute in Dart (Recommended)

```dart
import 'package:vector_math/vector_math.dart' as vm;

class RelativeAttitudeTracker {
  vm.Quaternion? phoneQuaternion;
  vm.Quaternion? airpodsQuaternion;
  
  // Start tracking iPhone motion using CoreMotion
  void startPhoneTracking(int referenceFrame) {
    // You'll need to add a method to get phone motion data
    // This would require adding CMMotionManager support to your native code
    // For now, this is conceptual
  }
  
  // Start tracking AirPods motion
  void startAirPodsTracking(int referenceFrame) {
    FlutterAirpods.getAirPodsDeviceMotionUpdates(
      referenceFrame: referenceFrame,
    ).listen((data) {
      airpodsQuaternion = vm.Quaternion(
        data.attitude.quaternion.x,
        data.attitude.quaternion.y,
        data.attitude.quaternion.z,
        data.attitude.quaternion.w,
      );
      
      _computeRelativeAttitude();
    });
  }
  
  void _computeRelativeAttitude() {
    if (phoneQuaternion == null || airpodsQuaternion == null) return;
    
    // Compute relative quaternion: airpods * inverse(phone)
    final phoneInverse = phoneQuaternion!.conjugate();
    final relativeQuat = airpodsQuaternion! * phoneInverse;
    
    // Convert to Euler angles if needed
    final euler = relativeQuat.asRotationMatrix().getRotation();
    
    print('Relative Pitch: ${euler.x}');
    print('Relative Roll: ${euler.y}');
    print('Relative Yaw: ${euler.z}');
  }
}
```

### Approach 2: Compute in Native (Swift)

If you need better performance, you can compute the relative attitude on the native side:

```swift
// In Swift
var phoneMotionManager = CMMotionManager()
var headphoneMotionManager = CMHeadphoneMotionManager()

func startRelativeMotionUpdates() {
    let referenceFrame = CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical
    
    // Start phone motion
    phoneMotionManager.startDeviceMotionUpdates(
        using: referenceFrame,
        to: OperationQueue.current!
    ) { motion, error in
        guard let phoneMotion = motion else { return }
        self.updateRelativeAttitude(phone: phoneMotion)
    }
    
    // Start headphone motion
    headphoneMotionManager.startDeviceMotionUpdates(
        using: referenceFrame,
        to: OperationQueue.current!
    ) { motion, error in
        guard let headphoneMotion = motion else { return }
        self.updateRelativeAttitude(headphones: headphoneMotion)
    }
}

func computeRelativeAttitude(phone: CMAttitude, headphones: CMAttitude) -> CMAttitude {
    // Create a copy of the headphones attitude
    let relativeAttitude = headphones.copy() as! CMAttitude
    
    // Multiply by inverse of phone attitude
    relativeAttitude.multiply(byInverseOf: phone)
    
    return relativeAttitude
}
```

## Best Practices

### 1. Always Check Availability
```dart
final frames = await FlutterAirpods.availableAttitudeReferenceFrames;
if (!CMAttitudeReferenceFrame.isFrameAvailable(frames, desiredFrame)) {
  // Fall back to a supported frame
}
```

### 2. Use Same Frame for Phone and AirPods
When computing relative attitude, both devices must use the same reference frame:

```dart
// ❌ Wrong - different frames
final phoneStream = getPhoneMotion(referenceFrame: CMAttitudeReferenceFrame.xArbitraryZVertical);
final airpodsStream = FlutterAirpods.getAirPodsDeviceMotionUpdates(
  referenceFrame: CMAttitudeReferenceFrame.xMagneticNorthZVertical
);

// ✅ Correct - same frame
final frame = CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical;
final phoneStream = getPhoneMotion(referenceFrame: frame);
final airpodsStream = FlutterAirpods.getAirPodsDeviceMotionUpdates(referenceFrame: frame);
```

### 3. Handle Magnetic Interference
When using magnetometer-based frames, be aware of magnetic interference:

```dart
// Monitor magnetic field accuracy
FlutterAirpods.getAirPodsDeviceMotionUpdates(
  referenceFrame: CMAttitudeReferenceFrame.xMagneticNorthZVertical,
).listen((data) {
  if (data.magneticField.accuracy < 0) { // CMMagneticFieldCalibrationAccuracyUncalibrated
    print('Warning: Magnetometer not calibrated');
    // Consider falling back to a non-magnetometer frame
  }
});
```

### 4. Prefer Corrected Frames for Long Sessions
For applications running over extended periods, use magnetometer-corrected frames to prevent yaw drift:

```dart
// Good for long-running apps
final frame = CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical;
```

## Common Use Cases

### 1. Head Tracking for Spatial Audio
```dart
// Use corrected frame for stable tracking
FlutterAirpods.getAirPodsDeviceMotionUpdates(
  referenceFrame: CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical,
).listen((data) {
  // Use quaternion for 3D audio positioning
  updateSpatialAudio(data.attitude.quaternion);
});
```

### 2. Fitness/Gesture Tracking
```dart
// Simple frame sufficient for gesture detection
FlutterAirpods.getAirPodsDeviceMotionUpdates(
  referenceFrame: CMAttitudeReferenceFrame.xArbitraryZVertical,
).listen((data) {
  detectHeadNod(data.attitude.pitch);
  detectHeadShake(data.attitude.yaw);
});
```

### 3. Navigation/Compass
```dart
// Use magnetic or true north for absolute heading
FlutterAirpods.getAirPodsDeviceMotionUpdates(
  referenceFrame: CMAttitudeReferenceFrame.xMagneticNorthZVertical,
).listen((data) {
  final heading = data.attitude.yaw * 180 / pi; // Convert to degrees
  displayCompass(heading);
});
```

## Troubleshooting

### Frame Not Available
If a frame isn't available, the system will use the default frame. Always check availability first.

### Yaw Drift
If you experience yaw drift, switch to a magnetometer-corrected frame:
- `xArbitraryCorrectedZVertical` or
- `xMagneticNorthZVertical`

### Magnetometer Calibration
Some frames require magnetometer calibration. If accuracy is low, prompt the user to calibrate by moving the device in a figure-8 pattern.

### Performance
Using magnetometer-based frames may have slightly higher power consumption due to continuous magnetometer usage.

## Additional Resources

- [Apple CoreMotion Documentation](https://developer.apple.com/documentation/coremotion)
- [CMAttitudeReferenceFrame](https://developer.apple.com/documentation/coremotion/cmattitudereferenceframe)
- [CMMotionManager](https://developer.apple.com/documentation/coremotion/cmmotionmanager)
- [Spatial Audio WWDC Sessions](https://developer.apple.com/videos/play/wwdc2021/10265/)
