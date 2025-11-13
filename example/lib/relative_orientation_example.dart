import 'package:flutter_airpods/flutter_airpods.dart';
import 'package:flutter_airpods/relative_attitude.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';

void main() {
  trackRelativeOrientation();
}

void trackRelativeOrientation() {
  DeviceMotionData? latestAirpods;
  DeviceMotionData? latestPhone;

  void computeRelative() {
    if (latestAirpods == null || latestPhone == null) return;

    // Get quaternions
    final airpodsQuat = latestAirpods!.attitude.quaternion;
    final phoneQuat = latestPhone!.attitude.quaternion;

    // Compute relative orientation
    final relativeQuat = RelativeAttitude.computeRelative(airpodsQuat, phoneQuat);

    // Convert to Euler angles
    final euler = RelativeAttitude.toEulerAngles(relativeQuat);
    
    print('Relative Pitch: ${euler['pitch']}');
    print('Relative Roll: ${euler['roll']}');
    print('Relative Yaw: ${euler['yaw']}');
  }

  // Listen to AirPods motion
  FlutterAirpods.getAirPodsDeviceMotionUpdates().listen((data) {
    latestAirpods = data;
    computeRelative();
  });

  // Listen to iPhone motion
  FlutterAirpods.getPhoneDeviceMotionUpdates().listen((data) {
    latestPhone = data;
    computeRelative();
  });
}
