import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCTestScreen extends StatefulWidget {
  const WebRTCTestScreen({super.key});

  @override
  State<WebRTCTestScreen> createState() => _WebRTCTestScreenState();
}

class _WebRTCTestScreenState extends State<WebRTCTestScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  MediaStream? _localStream;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
  try {
    debugPrint('STEP 1: Initializing renderer...');

    await _localRenderer.initialize();

    debugPrint('STEP 2: Requesting camera and microphone...');

    final devices = await navigator.mediaDevices.enumerateDevices();

    for (final device in devices) {
      debugPrint(
        'DEVICE: kind=${device.kind}, '
        'label=${device.label}, '
        'id=${device.deviceId}',
      );
    }

    debugPrint('STEP 3: Calling getUserMedia...');

    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });

    debugPrint('STEP 4: getUserMedia SUCCESS');
    debugPrint(
      'Audio tracks: ${stream.getAudioTracks().length}',
    );
    debugPrint(
      'Video tracks: ${stream.getVideoTracks().length}',
    );

    _localStream = stream;
    _localRenderer.srcObject = stream;

    if (mounted) {
      setState(() {
        _loading = false;
        _error = null;
      });
    }
  } catch (e, stackTrace) {
    debugPrint('WEBRTC ERROR: $e');
    debugPrint('$stackTrace');

    if (mounted) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }
}

  @override
  void dispose() {
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });

    _localStream?.dispose();
    _localRenderer.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebRTC Camera Test'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'WebRTC Error',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 25),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });

                            _startCamera();
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit:
                      RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
    );
  }
}