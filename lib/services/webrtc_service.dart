import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': 'stun:stun.l.google.com:19302',
      },
    ],
  };

  // ============================================================
  // LOCAL MEDIA
  // ============================================================

  Future<MediaStream> getLocalStream({
    bool video = true,
  }) async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video
          ? {
              'facingMode': 'user',
              'width': {
                'ideal': 1280,
              },
              'height': {
                'ideal': 720,
              },
              'frameRate': {
                'ideal': 30,
              },
            }
          : false,
    });

    _localStream = stream;

    print(
      'LOCAL STREAM CREATED',
    );

    print(
      'LOCAL AUDIO TRACKS: '
      '${stream.getAudioTracks().length}',
    );

    print(
      'LOCAL VIDEO TRACKS: '
      '${stream.getVideoTracks().length}',
    );

    return stream;
  }

  // ============================================================
  // PEER CONNECTION
  // ============================================================

  Future<RTCPeerConnection> createConnection() async {
    _peerConnection = await createPeerConnection(
      _configuration,
    );

    print(
      'PEER CONNECTION CREATED',
    );

    return _peerConnection!;
  }

  // ============================================================
  // ADD LOCAL TRACKS
  // ============================================================

  Future<void> addLocalStream(
    MediaStream stream,
  ) async {
    if (_peerConnection == null) {
      throw Exception(
        'Peer connection has not been created',
      );
    }

    for (final track in stream.getTracks()) {
      print(
        'ADDING LOCAL TRACK: '
        '${track.kind}',
      );

      await _peerConnection!.addTrack(
        track,
        stream,
      );
    }

    _localStream = stream;

    print(
      'ALL LOCAL TRACKS ADDED',
    );
  }

  // ============================================================
  // OFFER
  // ============================================================

  Future<RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) {
      throw Exception(
        'Peer connection has not been created',
      );
    }

    final offer =
        await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });

    await _peerConnection!.setLocalDescription(
      offer,
    );

    print(
      'LOCAL OFFER SET',
    );

    return offer;
  }

  // ============================================================
  // ANSWER
  // ============================================================

  Future<RTCSessionDescription> createAnswer() async {
    if (_peerConnection == null) {
      throw Exception(
        'Peer connection has not been created',
      );
    }

    final answer =
        await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });

    await _peerConnection!.setLocalDescription(
      answer,
    );

    print(
      'LOCAL ANSWER SET',
    );

    return answer;
  }

  // ============================================================
  // REMOTE DESCRIPTION
  // ============================================================

  Future<void> setRemoteDescription(
    RTCSessionDescription description,
  ) async {
    if (_peerConnection == null) {
      throw Exception(
        'Peer connection has not been created',
      );
    }

    print(
      'SETTING REMOTE DESCRIPTION: '
      '${description.type}',
    );

    await _peerConnection!.setRemoteDescription(
      description,
    );

    print(
      'REMOTE DESCRIPTION SET',
    );
  }

  // ============================================================
  // ICE
  // ============================================================

  Future<void> addIceCandidate(
    RTCIceCandidate candidate,
  ) async {
    if (_peerConnection == null) {
      throw Exception(
        'Peer connection has not been created',
      );
    }

    await _peerConnection!.addCandidate(
      candidate,
    );
  }

  void setOnIceCandidate(
    Function(RTCIceCandidate candidate) callback,
  ) {
    _peerConnection?.onIceCandidate = callback;
  }

  // ============================================================
  // REMOTE TRACK
  // ============================================================

  void setOnTrack(
    Function(RTCTrackEvent event) callback,
  ) {
    if (_peerConnection == null) {
      return;
    }

    _peerConnection!.onTrack = (event) {
      print(
        '================================',
      );

      print(
        'ON TRACK FIRED',
      );

      print(
        'TRACK KIND: ${event.track.kind}',
      );

      print(
        'TRACK ID: ${event.track.id}',
      );

      print(
        'STREAM COUNT: ${event.streams.length}',
      );

      print(
        '================================',
      );

      callback(event);
    };
  }

  // ============================================================
  // OLD STREAM API
  // ============================================================

  void setOnAddStream(
    Function(MediaStream stream) callback,
  ) {
    if (_peerConnection == null) {
      return;
    }

    _peerConnection!.onAddStream = (stream) {
      print(
        'ON ADD STREAM FIRED',
      );

      print(
        'AUDIO: '
        '${stream.getAudioTracks().length}',
      );

      print(
        'VIDEO: '
        '${stream.getVideoTracks().length}',
      );

      callback(stream);
    };
  }

  // ============================================================
  // CONNECTION STATE
  // ============================================================

  void setOnConnectionStateChange(
    Function(RTCPeerConnectionState state) callback,
  ) {
    _peerConnection?.onConnectionState = (state) {
      print(
        'WEBRTC CONNECTION STATE: $state',
      );

      callback(state);
    };
  }

  // ============================================================
  // GETTERS
  // ============================================================

  RTCPeerConnection? get peerConnection =>
      _peerConnection;

  MediaStream? get localStream =>
      _localStream;

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    print(
      'WEBRTC SERVICE DISPOSE',
    );

    if (_localStream != null) {
      for (final track
          in _localStream!.getTracks()) {
        try {
          await track.stop();
        } catch (e) {
          print(
            'TRACK STOP ERROR: $e',
          );
        }
      }

      try {
        await _localStream!.dispose();
      } catch (e) {
        print(
          'STREAM DISPOSE ERROR: $e',
        );
      }
    }

    try {
      await _peerConnection?.close();
    } catch (e) {
      print(
        'PEER CONNECTION CLOSE ERROR: $e',
      );
    }

    _localStream = null;
    _peerConnection = null;

    print(
      'WEBRTC SERVICE DISPOSE COMPLETE',
    );
  }
}