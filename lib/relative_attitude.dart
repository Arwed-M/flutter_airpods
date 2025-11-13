import 'dart:math';
import 'package:flutter_airpods/models/quaternion.dart';

/// Utilities for computing relative attitude between two devices
class RelativeAttitude {
  /// Compute the quaternion that represents AirPods attitude relative to iPhone
  /// 
  /// Usage:
  /// ```dart
  /// final airpodsQuat = airpodsData.attitude.quaternion;
  /// final phoneQuat = phoneData.attitude.quaternion;
  /// final relative = RelativeAttitude.computeRelative(airpodsQuat, phoneQuat);
  /// ```
  static Quaternion computeRelative(Quaternion airpods, Quaternion phone) {
    // Compute: airpods * inverse(phone)
    final phoneInverse = conjugate(phone);
    return multiply(airpods, phoneInverse);
  }

  /// Conjugate of a quaternion (inverse for unit quaternions)
  static Quaternion conjugate(Quaternion q) {
    return Quaternion(-q.x, -q.y, -q.z, q.w);
  }

  /// Multiply two quaternions
  static Quaternion multiply(Quaternion a, Quaternion b) {
    return Quaternion(
      a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
      a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
      a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
      a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
    );
  }

  /// Convert quaternion to Euler angles (pitch, roll, yaw in radians)
  static Map<String, double> toEulerAngles(Quaternion q) {
    // Roll (x-axis rotation)
    final sinr_cosp = 2 * (q.w * q.x + q.y * q.z);
    final cosr_cosp = 1 - 2 * (q.x * q.x + q.y * q.y);
    final roll = atan2(sinr_cosp, cosr_cosp);

    // Pitch (y-axis rotation)
    final sinp = 2 * (q.w * q.y - q.z * q.x);
    final pitch = sinp.abs() >= 1
        ? (pi / 2) * sinp.sign // Use 90 degrees if out of range
        : asin(sinp);

    // Yaw (z-axis rotation)
    final siny_cosp = 2 * (q.w * q.z + q.x * q.y);
    final cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z);
    final yaw = atan2(siny_cosp, cosy_cosp);

    return {'pitch': pitch, 'roll': roll, 'yaw': yaw};
  }
}
