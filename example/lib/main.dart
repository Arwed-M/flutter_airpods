import 'package:flutter/material.dart';

import 'package:flutter_airpods/flutter_airpods.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int? _availableFrames;
  int? _selectedFrame;
  bool _useReferenceFrame = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableFrames();
  }

  Future<void> _loadAvailableFrames() async {
    try {
      final frames = await FlutterAirpods.availableAttitudeReferenceFrames;
      setState(() {
        _availableFrames = frames;
        // Default to xMagneticNorthZVertical if available, otherwise first available
        if (CMAttitudeReferenceFrame.isFrameAvailable(
            frames, CMAttitudeReferenceFrame.xMagneticNorthZVertical)) {
          _selectedFrame = CMAttitudeReferenceFrame.xMagneticNorthZVertical;
        } else if (CMAttitudeReferenceFrame.isFrameAvailable(
            frames, CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical)) {
          _selectedFrame = CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical;
        } else if (CMAttitudeReferenceFrame.isFrameAvailable(
            frames, CMAttitudeReferenceFrame.xArbitraryZVertical)) {
          _selectedFrame = CMAttitudeReferenceFrame.xArbitraryZVertical;
        }
      });
    } catch (e) {
      debugPrint('Error loading available frames: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Airpods example app'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available reference frames section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Reference Frames',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_availableFrames != null) ...[
                        Text(
                            'Raw bitmask: $_availableFrames (0x${_availableFrames!.toRadixString(16)})'),
                        const SizedBox(height: 8),
                        ...CMAttitudeReferenceFrame.getAvailableFrameNames(
                                _availableFrames!)
                            .map((name) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text('✓ $name'),
                                )),
                      ] else
                        const CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reference frame selector
              if (_availableFrames != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Use Custom Reference Frame',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Switch(
                              value: _useReferenceFrame,
                              onChanged: (value) {
                                setState(() {
                                  _useReferenceFrame = value;
                                });
                              },
                            ),
                          ],
                        ),
                        if (_useReferenceFrame) ...[
                          const SizedBox(height: 8),
                          if (CMAttitudeReferenceFrame.isFrameAvailable(
                              _availableFrames!,
                              CMAttitudeReferenceFrame.xArbitraryZVertical))
                            RadioListTile<int>(
                              title:
                                  const Text('xArbitraryZVertical (Default)'),
                              subtitle: const Text(
                                  'Z vertical, X arbitrary in horizontal plane'),
                              value:
                                  CMAttitudeReferenceFrame.xArbitraryZVertical,
                              groupValue: _selectedFrame,
                              onChanged: (value) {
                                setState(() => _selectedFrame = value);
                              },
                            ),
                          if (CMAttitudeReferenceFrame.isFrameAvailable(
                              _availableFrames!,
                              CMAttitudeReferenceFrame
                                  .xArbitraryCorrectedZVertical))
                            RadioListTile<int>(
                              title: const Text(
                                  'xArbitraryCorrectedZVertical (Recommended)'),
                              subtitle: const Text(
                                  'Z vertical, magnetometer-corrected yaw'),
                              value: CMAttitudeReferenceFrame
                                  .xArbitraryCorrectedZVertical,
                              groupValue: _selectedFrame,
                              onChanged: (value) {
                                setState(() => _selectedFrame = value);
                              },
                            ),
                          if (CMAttitudeReferenceFrame.isFrameAvailable(
                              _availableFrames!,
                              CMAttitudeReferenceFrame.xMagneticNorthZVertical))
                            RadioListTile<int>(
                              title: const Text('xMagneticNorthZVertical'),
                              subtitle:
                                  const Text('Z vertical, X toward mag north'),
                              value: CMAttitudeReferenceFrame
                                  .xMagneticNorthZVertical,
                              groupValue: _selectedFrame,
                              onChanged: (value) {
                                setState(() => _selectedFrame = value);
                              },
                            ),
                          if (CMAttitudeReferenceFrame.isFrameAvailable(
                              _availableFrames!,
                              CMAttitudeReferenceFrame.xTrueNorthZVertical))
                            RadioListTile<int>(
                              title: const Text('xTrueNorthZVertical'),
                              subtitle:
                                  const Text('Z vertical, X toward true north'),
                              value:
                                  CMAttitudeReferenceFrame.xTrueNorthZVertical,
                              groupValue: _selectedFrame,
                              onChanged: (value) {
                                setState(() => _selectedFrame = value);
                              },
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Motion data display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AirPods Motion Data',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      /// Streambuilder that continuingly reads data from [CMHeadphoneMotionManager]
                      StreamBuilder<DeviceMotionData>(
                        key: ValueKey(_useReferenceFrame
                            ? _selectedFrame
                            : 'default'),
                        stream: FlutterAirpods.getAirPodsDeviceMotionUpdates(
                          referenceFrame:
                              _useReferenceFrame ? _selectedFrame : null,
                        ),
                        builder: (BuildContext context,
                            AsyncSnapshot<DeviceMotionData> snapshot) {
                          /// If AirPods are connected and in ear hasData will be true.
                          /// When AirPods are connected, but removed from ear, it will
                          /// stop receiving data.
                          if (snapshot.hasData) {
                            final data = snapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "Sensor Location: ${data.sensorLocation.description}",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(
                                    "Pitch: ${data.attitude.pitch.toStringAsFixed(3)}"),
                                Text(
                                    "Roll: ${data.attitude.roll.toStringAsFixed(3)}"),
                                Text(
                                    "Yaw: ${data.attitude.yaw.toStringAsFixed(3)}"),
                                const SizedBox(height: 8),
                                const Text("Quaternion:",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                    "  x: ${data.attitude.quaternion.x.toStringAsFixed(3)}"),
                                Text(
                                    "  y: ${data.attitude.quaternion.y.toStringAsFixed(3)}"),
                                Text(
                                    "  z: ${data.attitude.quaternion.z.toStringAsFixed(3)}"),
                                Text(
                                    "  w: ${data.attitude.quaternion.w.toStringAsFixed(3)}"),
                                const SizedBox(height: 8),
                                ExpansionTile(
                                  title: const Text("Show Complete Data"),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text("${data.toJson()}"),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          } else if (snapshot.hasError) {
                            return Text("Error: ${snapshot.error}");
                          } else {
                            /// AirPods are not connected yet
                            return const Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text("Waiting for incoming data..."),
                                SizedBox(height: 4),
                                Text(
                                  "Connect AirPods and put them in your ears",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
