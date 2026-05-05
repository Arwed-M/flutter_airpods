import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';
export 'package:flutter_airpods/models/sensor_location.dart';
export 'package:flutter_airpods/relative_attitude.dart';

/// CMAttitudeReferenceFrame constants matching Apple's CoreMotion values.
/// Use these to specify which reference frame to use for attitude calculations.
class CMAttitudeReferenceFrame {
  /// Describes a reference frame in which the Z axis is vertical and the X axis points in an arbitrary direction in the horizontal plane.
  static const int xArbitraryZVertical = 1 << 0; // 1

  /// Describes the same reference frame as xArbitraryZVertical except that the magnetometer, when available and calibrated, is used to improve long-term yaw accuracy.
  static const int xArbitraryCorrectedZVertical = 1 << 1; // 2

  /// Describes a reference frame in which the Z axis is vertical and the X axis points toward magnetic north.
  static const int xMagneticNorthZVertical = 1 << 2; // 4

  /// Describes a reference frame in which the Z axis is vertical and the X axis points toward true north.
  static const int xTrueNorthZVertical = 1 << 3; // 8

  /// Helper method to check if a specific frame is available in the bitmask
  static bool isFrameAvailable(int availableFrames, int frame) {
    return (availableFrames & frame) != 0;
  }

  /// Get a list of available frame names from a bitmask
  static List<String> getAvailableFrameNames(int availableFrames) {
    final List<String> names = [];
    if (isFrameAvailable(availableFrames, xArbitraryZVertical)) {
      names.add('xArbitraryZVertical');
    }
    if (isFrameAvailable(availableFrames, xArbitraryCorrectedZVertical)) {
      names.add('xArbitraryCorrectedZVertical');
    }
    if (isFrameAvailable(availableFrames, xMagneticNorthZVertical)) {
      names.add('xMagneticNorthZVertical');
    }
    if (isFrameAvailable(availableFrames, xTrueNorthZVertical)) {
      names.add('xTrueNorthZVertical');
    }
    return names;
  }
}

/// Authorization status for `CMHeadphoneMotionManager`, mirroring
/// `CMAuthorizationStatus` from CoreMotion.
enum HeadphoneMotionAuthorizationStatus {
  /// The user has not yet been asked for permission.
  notDetermined,

  /// The app is not authorized and the user cannot change this (parental controls, MDM).
  restricted,

  /// The user explicitly denied access.
  denied,

  /// The user granted access.
  authorized,
}

/// API for accessing information about the currently connected airpods.
class FlutterAirpods {
  static const EventChannel _motionChannel =
      EventChannel("flutter_airpods.motion");
  static const EventChannel _phoneMotionChannel =
      EventChannel("flutter_airpods.phone_motion");
  static const MethodChannel _methodChannel =
      MethodChannel("flutter_airpods.method");

  /// Returns the current `CMHeadphoneMotionManager` authorization status.
  ///
  /// On non-iOS/macOS platforms this always returns [HeadphoneMotionAuthorizationStatus.authorized]
  /// because the feature is not gated by a permission there.
  static Future<HeadphoneMotionAuthorizationStatus> get headphoneMotionAuthorizationStatus async {
    try {
      final String? raw = await _methodChannel.invokeMethod<String>('headphoneMotionAuthorizationStatus');
      if (raw == 'authorized') return HeadphoneMotionAuthorizationStatus.authorized;
      if (raw == 'restricted') return HeadphoneMotionAuthorizationStatus.restricted;
      if (raw == 'denied')     return HeadphoneMotionAuthorizationStatus.denied;
      return HeadphoneMotionAuthorizationStatus.notDetermined;
    } on MissingPluginException {
      // Plugin not registered (non-iOS platform or unit tests).
      return HeadphoneMotionAuthorizationStatus.authorized;
    }
  }

  /// Gets the available attitude reference frames supported by the device.
  /// Returns a bitmask of available CMAttitudeReferenceFrame values.
  /// 
  /// Use [CMAttitudeReferenceFrame] constants to check which frames are available:
  /// ```dart
  /// final frames = await FlutterAirpods.availableAttitudeReferenceFrames;
  /// if (CMAttitudeReferenceFrame.isFrameAvailable(frames, CMAttitudeReferenceFrame.xMagneticNorthZVertical)) {
  ///   // Magnetic north frame is available
  /// }
  /// ```
  static Future<int> get availableAttitudeReferenceFrames async {
    final dynamic result =
        await _methodChannel.invokeMethod('availableAttitudeReferenceFrames');
    return result as int;
  }

  /// Returns a list of available attitude reference frame names.
  /// 
  /// This is a convenience method that converts the bitmask from
  /// [availableAttitudeReferenceFrames] into a human-readable list.
  /// 
  /// Example:
  /// ```dart
  /// final frameNames = await FlutterAirpods.availableAttitudeReferenceFrameNames;
  /// print('Available frames: $frameNames');
  /// // Output: Available frames: [xArbitraryZVertical, xArbitraryCorrectedZVertical, xMagneticNorthZVertical, xTrueNorthZVertical]
  /// ```
  static Future<List<String>> get availableAttitudeReferenceFrameNames async {
    final int bitmask = await availableAttitudeReferenceFrames;
    return CMAttitudeReferenceFrame.getAvailableFrameNames(bitmask);
  }

  /// The getAirPodsDeviceMotionUpdates method allows to receive updates on the motion data of the currently connected airpods.
  /// 
  /// Optionally specify a [referenceFrame] to use a specific attitude reference frame.
  /// Use [availableAttitudeReferenceFrames] to check which frames are supported before using them.
  /// 
  /// Example:
  /// ```dart
  /// // Get motion updates with default reference frame
  /// FlutterAirpods.getAirPodsDeviceMotionUpdates().listen((data) {
  ///   print('Pitch: ${data.attitude.pitch}');
  /// });
  /// 
  /// // Get motion updates with a specific reference frame
  /// FlutterAirpods.getAirPodsDeviceMotionUpdates(
  ///   referenceFrame: CMAttitudeReferenceFrame.xMagneticNorthZVertical
  /// ).listen((data) {
  ///   print('Pitch: ${data.attitude.pitch}');
  /// });
  /// ```
  static Stream<DeviceMotionData> getAirPodsDeviceMotionUpdates({
    int? referenceFrame,
  }) {
    /// The data gets sent over the event channel.
    /// Every incoming event gets read as a JSON and then
    /// is mapped as [DeviceMotionData].
    final arguments = referenceFrame != null
        ? <String, dynamic>{'referenceFrame': referenceFrame}
        : null;

    return _motionChannel.receiveBroadcastStream(arguments).map((event) {
      Map<String, dynamic> json = jsonDecode(event);

      /// Creates a [DeviceMotionData] from a JSON.
      DeviceMotionData deviceMotionData = DeviceMotionData.fromJson(json);

      /// Returns transformed [DeviceMotionData]
      return deviceMotionData;
    });
  }

  /// Get iPhone/iPad device motion updates.
  /// Use this to compute relative attitude between AirPods and iPhone.
  static Stream<DeviceMotionData> getPhoneDeviceMotionUpdates() {
    return _phoneMotionChannel.receiveBroadcastStream().map((event) {
      Map<String, dynamic> json = jsonDecode(event);
      return DeviceMotionData.fromJson(json);
    });
  }
}
