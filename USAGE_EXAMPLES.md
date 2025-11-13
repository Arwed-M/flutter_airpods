# Flutter AirPods Usage Examples

## Working with Attitude Reference Frames

### Understanding the Bitmask

When you call `availableAttitudeReferenceFrames`, you get an integer bitmask where each bit represents a different reference frame:

```dart
final frames = await FlutterAirpods.availableAttitudeReferenceFrames;
print(frames); // e.g., 15
```

The value `15` means:
- Binary: `1111`
- Bit 0 (value 1): xArbitraryZVertical ✅
- Bit 1 (value 2): xArbitraryCorrectedZVertical ✅
- Bit 2 (value 4): xMagneticNorthZVertical ✅
- Bit 3 (value 8): xTrueNorthZVertical ✅

### Method 1: Get Human-Readable Frame Names (Easiest)

```dart
import 'package:flutter_airpods/flutter_airpods.dart';

// Get available frames as a list of names
final frameNames = await FlutterAirpods.availableAttitudeReferenceFrameNames;
print('Available frames: $frameNames');
// Output: Available frames: [xArbitraryZVertical, xArbitraryCorrectedZVertical, xMagneticNorthZVertical, xTrueNorthZVertical]
```

### Method 2: Check if Specific Frame is Available

```dart
import 'package:flutter_airpods/flutter_airpods.dart';

final framesBitmask = await FlutterAirpods.availableAttitudeReferenceFrames;

// Check if magnetic north frame is available
if (CMAttitudeReferenceFrame.isFrameAvailable(
  framesBitmask, 
  CMAttitudeReferenceFrame.xMagneticNorthZVertical
)) {
  print('Magnetic North frame is available!');
  
  // You can use it when starting motion updates
  FlutterAirpods.getAirPodsDeviceMotionUpdates(
    referenceFrame: CMAttitudeReferenceFrame.xMagneticNorthZVertical
  ).listen((data) {
    print('Yaw: ${data.attitude.yaw}');
  });
}
```

### Method 3: Manual Bit Checking

```dart
final frames = await FlutterAirpods.availableAttitudeReferenceFrames;

// Check each frame individually using bitwise AND
if (frames & CMAttitudeReferenceFrame.xArbitraryZVertical != 0) {
  print('xArbitraryZVertical is available');
}
if (frames & CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical != 0) {
  print('xArbitraryCorrectedZVertical is available');
}
if (frames & CMAttitudeReferenceFrame.xMagneticNorthZVertical != 0) {
  print('xMagneticNorthZVertical is available');
}
if (frames & CMAttitudeReferenceFrame.xTrueNorthZVertical != 0) {
  print('xTrueNorthZVertical is available');
}
```

## Complete Example: Choosing the Best Frame

```dart
import 'package:flutter_airpods/flutter_airpods.dart';

Future<int?> chooseBestAvailableFrame() async {
  final frames = await FlutterAirpods.availableAttitudeReferenceFrames;
  
  // Prefer frames in this order:
  // 1. True North (most accurate for world alignment)
  // 2. Magnetic North
  // 3. Arbitrary Corrected (magnetometer-corrected)
  // 4. Arbitrary (basic gravity-aligned)
  
  if (CMAttitudeReferenceFrame.isFrameAvailable(
      frames, CMAttitudeReferenceFrame.xTrueNorthZVertical)) {
    print('Using True North reference frame');
    return CMAttitudeReferenceFrame.xTrueNorthZVertical;
  } else if (CMAttitudeReferenceFrame.isFrameAvailable(
      frames, CMAttitudeReferenceFrame.xMagneticNorthZVertical)) {
    print('Using Magnetic North reference frame');
    return CMAttitudeReferenceFrame.xMagneticNorthZVertical;
  } else if (CMAttitudeReferenceFrame.isFrameAvailable(
      frames, CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical)) {
    print('Using Arbitrary Corrected reference frame');
    return CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical;
  } else if (CMAttitudeReferenceFrame.isFrameAvailable(
      frames, CMAttitudeReferenceFrame.xArbitraryZVertical)) {
    print('Using Arbitrary reference frame');
    return CMAttitudeReferenceFrame.xArbitraryZVertical;
  }
  
  return null; // No frames available (shouldn't happen on real devices)
}

// Usage
void startMotionTracking() async {
  final bestFrame = await chooseBestAvailableFrame();
  
  if (bestFrame != null) {
    FlutterAirpods.getAirPodsDeviceMotionUpdates(
      referenceFrame: bestFrame
    ).listen((data) {
      print('Pitch: ${data.attitude.pitch}');
      print('Roll: ${data.attitude.roll}');
      print('Yaw: ${data.attitude.yaw}');
    });
  }
}
```

## Reference Frame Descriptions

### `xArbitraryZVertical` (Value: 1)
- **Z-axis**: Points vertically (aligned with gravity)
- **X-axis**: Points in an arbitrary horizontal direction
- **Best for**: Simple tilt detection where absolute heading doesn't matter
- **Stability**: Good for pitch/roll, yaw drifts over time

### `xArbitraryCorrectedZVertical` (Value: 2)
- **Z-axis**: Points vertically (aligned with gravity)
- **X-axis**: Arbitrary but uses magnetometer to reduce yaw drift
- **Best for**: Applications needing stable yaw without true heading
- **Stability**: Better yaw stability than xArbitraryZVertical

### `xMagneticNorthZVertical` (Value: 4)
- **Z-axis**: Points vertically (aligned with gravity)
- **X-axis**: Points toward magnetic north
- **Best for**: Compass-like applications, spatial audio
- **Stability**: Good stability, but affected by magnetic interference

### `xTrueNorthZVertical` (Value: 8)
- **Z-axis**: Points vertically (aligned with gravity)
- **X-axis**: Points toward true north (corrected for magnetic declination)
- **Best for**: Navigation, precise world-aligned applications
- **Stability**: Best accuracy but may require location services
- **Note**: May not be available on all devices/configurations

## Important Notes

### ⚠️ CMHeadphoneMotionManager Limitation

**The AirPods motion stream does NOT actually support custom reference frames!** This is a limitation of Apple's `CMHeadphoneMotionManager` API.

The `availableAttitudeReferenceFrames` method returns the frames available **for the iPhone/iPad device**, not the AirPods. The AirPods always use a default reference frame (similar to `xArbitraryZVertical`).

To get attitude relative to the iPhone (like spatial audio), you would need to:
1. Track iPhone motion separately using `CMMotionManager`
2. Track AirPods motion using this plugin
3. Compute relative attitude by combining both

This limitation is documented in Apple's CoreMotion framework.
