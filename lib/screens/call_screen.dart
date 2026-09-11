import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:connect_call/models/user_model.dart';
import 'package:connect_call/services/calling_service.dart';
import 'package:connect_call/services/webrtc_service.dart';

class CallScreen extends StatefulWidget {
  final UserModel user;
  final String callType;

  // Null = outgoing call
  // Not null = incoming call
  final String? incomingCallId;

  const CallScreen({
    super.key,
    required this.user,
    required this.callType,
    this.incomingCallId,
  });

  bool get isIncoming => incomingCallId != null;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallingService _callingService = CallingService();
  final WebRTCService _webRTCService = WebRTCService();

  bool _isEndingCall = false;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  Timer? _timer;

  StreamSubscription? _callSubscription;
  StreamSubscription? _remoteCandidatesSubscription;

  bool _isCalling = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isCameraOn = true;
  bool _isFrontCamera = true;

  bool _remoteDescriptionSet = false;

  int _callDuration = 0;

  String _connectionStatus = 'Calling...';

  String? _callId;

  final List<RTCIceCandidate> _pendingRemoteCandidates = [];

  static const Color primaryColor = Color.fromARGB(255, 18, 108, 136);

  bool get isVideo => widget.callType == 'video';

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initializeCall() async {
    try {
      debugPrint('CALL SCREEN INITIALIZING');

      await _localRenderer.initialize();
      debugPrint('LOCAL RENDERER INITIALIZED');

      await _remoteRenderer.initialize();
      debugPrint('REMOTE RENDERER INITIALIZED');

      if (widget.isIncoming) {
        await _startIncomingCall();
      } else {
        await _startOutgoingCall();
      }
    } catch (e, stackTrace) {
      debugPrint('CALL INITIALIZATION ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isCalling = false;
        _connectionStatus = 'Call failed';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Call failed: $e'),
        ),
      );
    }
  }

  // ============================================================
  // OUTGOING CALL
  // ============================================================

  Future<void> _startOutgoingCall() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      debugPrint('NO CURRENT USER');
      return;
    }

    if (mounted) {
      setState(() {
        _isCalling = true;
        _connectionStatus = 'Calling...';
      });
    }

    try {
      // --------------------------------------------------------
      // 1. CREATE FIRESTORE CALL
      // --------------------------------------------------------

      final callId = await _callingService.createCall(
        callerId: currentUser.uid,
        receiverId: widget.user.uid,
        callerName: currentUser.displayName ?? 'User',
        receiverName: widget.user.name,
        type: widget.callType,
      );

      _callId = callId;

      debugPrint('OUTGOING CALL CREATED: $_callId');

      // --------------------------------------------------------
      // 2. GET LOCAL CAMERA + MICROPHONE
      // --------------------------------------------------------

      final localStream = await _webRTCService.getLocalStream(
        video: isVideo,
      );

      debugPrint(
        'LOCAL AUDIO TRACKS: '
        '${localStream.getAudioTracks().length}',
      );

      debugPrint(
        'LOCAL VIDEO TRACKS: '
        '${localStream.getVideoTracks().length}',
      );

      _localRenderer.srcObject = localStream;

      debugPrint('LOCAL STREAM ASSIGNED TO RENDERER');

      if (mounted) {
        setState(() {});
      }

      // --------------------------------------------------------
      // 3. CREATE PEER CONNECTION
      // --------------------------------------------------------

      await _webRTCService.createConnection();

      // --------------------------------------------------------
      // 4. ADD LOCAL TRACKS
      // --------------------------------------------------------

      await _webRTCService.addLocalStream(localStream);

      // --------------------------------------------------------
      // 5. RECEIVE REMOTE TRACKS
      // --------------------------------------------------------

      _setRemoteTrackListener();

      // --------------------------------------------------------
      // 6. SEND OUR ICE CANDIDATES
      // --------------------------------------------------------

      _webRTCService.setOnIceCandidate(
        (RTCIceCandidate candidate) {
          if (_callId == null) return;

          final candidateData = {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          };

          _callingService.addIceCandidate(
            callId: _callId!,
            collectionName: 'callerCandidates',
            candidate: candidateData,
          );
        },
      );

      // --------------------------------------------------------
      // 7. LISTEN FOR RECEIVER ICE
      // --------------------------------------------------------

      _listenForRemoteCandidates(
        collectionName: 'receiverCandidates',
      );

      // --------------------------------------------------------
      // 8. CREATE OFFER
      // --------------------------------------------------------

      final offer = await _webRTCService.createOffer();

      debugPrint('OFFER CREATED');

      // --------------------------------------------------------
      // 9. SAVE OFFER
      // --------------------------------------------------------

      await _callingService.setOffer(
        callId: _callId!,
        offer: {
          'type': offer.type,
          'sdp': offer.sdp,
        },
      );

      debugPrint('OFFER SAVED TO FIRESTORE');

      // --------------------------------------------------------
      // 10. WAIT FOR ANSWER
      // --------------------------------------------------------

      _listenForAnswer();

      if (mounted) {
        setState(() {
          _connectionStatus = 'Ringing...';
        });
      }
    } catch (e, stackTrace) {
      debugPrint('OUTGOING CALL ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isCalling = false;
        _connectionStatus = 'Call failed';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Call failed: $e'),
        ),
      );
    }
  }

  // ============================================================
  // INCOMING CALL
  // ============================================================

  Future<void> _startIncomingCall() async {
    if (widget.incomingCallId == null) {
      return;
    }

    _callId = widget.incomingCallId;

    debugPrint('INCOMING CALL ID: $_callId');

    if (mounted) {
      setState(() {
        _isCalling = true;
        _connectionStatus = 'Connecting...';
      });
    }

    try {
      // --------------------------------------------------------
      // 1. CURRENT USER
      // --------------------------------------------------------

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('Current user is not logged in');
      }

      // --------------------------------------------------------
      // 2. GET LOCAL CAMERA + MICROPHONE
      // --------------------------------------------------------

      final localStream = await _webRTCService.getLocalStream(
        video: isVideo,
      );

      debugPrint(
        'INCOMING LOCAL AUDIO TRACKS: '
        '${localStream.getAudioTracks().length}',
      );

      debugPrint(
        'INCOMING LOCAL VIDEO TRACKS: '
        '${localStream.getVideoTracks().length}',
      );

      _localRenderer.srcObject = localStream;

      debugPrint('INCOMING LOCAL STREAM ASSIGNED');

      if (mounted) {
        setState(() {});
      }

      // --------------------------------------------------------
      // 3. CREATE PEER CONNECTION
      // --------------------------------------------------------

      await _webRTCService.createConnection();

      // --------------------------------------------------------
      // 4. ADD LOCAL TRACKS
      // --------------------------------------------------------

      await _webRTCService.addLocalStream(localStream);

      // --------------------------------------------------------
      // 5. RECEIVE REMOTE TRACK
      // --------------------------------------------------------

      _setRemoteTrackListener();

      // --------------------------------------------------------
      // 6. SEND RECEIVER ICE
      // --------------------------------------------------------

      _webRTCService.setOnIceCandidate(
        (RTCIceCandidate candidate) {
          if (_callId == null) return;

          final candidateData = {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          };

          _callingService.addIceCandidate(
            callId: _callId!,
            collectionName: 'receiverCandidates',
            candidate: candidateData,
          );
        },
      );

      // --------------------------------------------------------
      // 7. LISTEN FOR CALLER ICE
      // --------------------------------------------------------

      _listenForRemoteCandidates(
        collectionName: 'callerCandidates',
      );

      // --------------------------------------------------------
      // 8. LISTEN FOR OFFER
      // --------------------------------------------------------

      _listenForIncomingOffer();
    } catch (e, stackTrace) {
      debugPrint('INCOMING CALL ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isCalling = false;
        _connectionStatus = 'Call failed';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to answer call: $e'),
        ),
      );
    }
  }

  // ============================================================
  // INCOMING OFFER
  // ============================================================

  void _listenForIncomingOffer() {
    if (_callId == null) return;

    _callSubscription =
        _callingService.listenToCall(_callId!).listen(
      (snapshot) async {
        if (!snapshot.exists) {
          return;
        }

        final data = snapshot.data();

        if (data == null) {
          return;
        }

        final offer = data['offer'];

        if (offer != null && !_remoteDescriptionSet) {
          try {
            debugPrint('INCOMING OFFER RECEIVED');

            final remoteDescription = RTCSessionDescription(
              offer['sdp'],
              offer['type'],
            );

            await _webRTCService.setRemoteDescription(
              remoteDescription,
            );

            _remoteDescriptionSet = true;

            debugPrint('REMOTE OFFER SET');

            await _flushPendingRemoteCandidates();

            final answer = await _webRTCService.createAnswer();

            debugPrint('ANSWER CREATED');

            await _callingService.setAnswer(
              callId: _callId!,
              answer: {
                'type': answer.type,
                'sdp': answer.sdp,
              },
            );

            debugPrint('ANSWER SAVED TO FIRESTORE');

            if (mounted) {
              setState(() {
                _connectionStatus = 'Connecting...';
              });
            }
          } catch (e, stackTrace) {
            debugPrint('INCOMING OFFER ERROR: $e');
            debugPrint('$stackTrace');
          }
        }

        final status = data['status'];

        if (status == 'ended' || status == 'rejected') {
          await _handleRemoteCallEnded();
        }
      },
    );
  }

  // ============================================================
  // REMOTE TRACK LISTENER
  // ============================================================

  void _setRemoteTrackListener() {
    debugPrint('SETTING REMOTE TRACK LISTENER');

    // ----------------------------------------------------------
    // MODERN onTrack API
    // ----------------------------------------------------------

    _webRTCService.setOnTrack(
      (RTCTrackEvent event) {
        debugPrint('================================');
        debugPrint('REMOTE TRACK RECEIVED');
        debugPrint('TRACK KIND: ${event.track.kind}');
        debugPrint('TRACK ID: ${event.track.id}');
        debugPrint('TRACK ENABLED: ${event.track.enabled}');
        debugPrint('TRACK MUTED: ${event.track.muted}');
        debugPrint('STREAM COUNT: ${event.streams.length}');
        debugPrint('================================');

        // Ignore audio here.
        if (event.track.kind != 'video') {
          debugPrint('REMOTE AUDIO TRACK RECEIVED');
          return;
        }

        // We need a MediaStream to display the video.
        if (event.streams.isEmpty) {
          debugPrint('REMOTE VIDEO TRACK HAS NO STREAM');
          return;
        }

        final remoteStream = event.streams.first;

        debugPrint('REMOTE STREAM RECEIVED');

        final audioTracks = remoteStream.getAudioTracks();
        final videoTracks = remoteStream.getVideoTracks();

        debugPrint(
          'REMOTE AUDIO TRACKS: ${audioTracks.length}',
        );

        debugPrint(
          'REMOTE VIDEO TRACKS: ${videoTracks.length}',
        );

        if (videoTracks.isEmpty) {
          debugPrint('NO REMOTE VIDEO TRACK FOUND');
          return;
        }

        final remoteVideoTrack = videoTracks.first;

        debugPrint(
          'REMOTE VIDEO TRACK ID: ${remoteVideoTrack.id}',
        );

        debugPrint(
          'REMOTE VIDEO ENABLED BEFORE: '
          '${remoteVideoTrack.enabled}',
        );

        // Make sure remote video is enabled.
        remoteVideoTrack.enabled = true;

        debugPrint(
          'REMOTE VIDEO ENABLED AFTER: '
          '${remoteVideoTrack.enabled}',
        );

        // Assign remote stream to renderer.
        _remoteRenderer.srcObject = remoteStream;

        debugPrint(
          'REMOTE VIDEO ASSIGNED TO RENDERER',
        );

        if (mounted) {
          setState(() {
            _connectionStatus = 'Connected';
            _isCalling = false;
          });
        }

        _startTimer();
      },
    );

    // ----------------------------------------------------------
    // FALLBACK onAddStream API
    // ----------------------------------------------------------

    _webRTCService.setOnAddStream(
      (MediaStream stream) {
        debugPrint('================================');
        debugPrint('REMOTE STREAM RECEIVED VIA onAddStream');

        final audioTracks = stream.getAudioTracks();
        final videoTracks = stream.getVideoTracks();

        debugPrint(
          'AUDIO: ${audioTracks.length}',
        );

        debugPrint(
          'VIDEO: ${videoTracks.length}',
        );

        debugPrint('================================');

        if (videoTracks.isNotEmpty) {
          videoTracks.first.enabled = true;

          debugPrint(
            'ON ADD STREAM VIDEO ENABLED: '
            '${videoTracks.first.enabled}',
          );
        }

        _remoteRenderer.srcObject = stream;

        debugPrint(
          'REMOTE STREAM ASSIGNED TO RENDERER',
        );

        if (mounted) {
          setState(() {
            _connectionStatus = 'Connected';
            _isCalling = false;
          });
        }

        _startTimer();
      },
    );

    // ----------------------------------------------------------
    // CONNECTION STATE
    // ----------------------------------------------------------

    _webRTCService.setOnConnectionStateChange(
      (RTCPeerConnectionState state) {
        debugPrint(
          'WEBRTC CONNECTION STATE: $state',
        );

        if (!mounted) return;

        if (state ==
            RTCPeerConnectionState
                .RTCPeerConnectionStateConnected) {
          debugPrint('WEBRTC IS CONNECTED');

          setState(() {
            _connectionStatus = 'Connected';
            _isCalling = false;
          });

          _startTimer();
        }

        if (state ==
                RTCPeerConnectionState
                    .RTCPeerConnectionStateFailed ||
            state ==
                RTCPeerConnectionState
                    .RTCPeerConnectionStateDisconnected) {
          debugPrint('WEBRTC CONNECTION FAILED/DISCONNECTED');

          setState(() {
            _connectionStatus = 'Connection failed';
          });
        }
      },
    );
  }

  // ============================================================
  // LISTEN FOR ANSWER
  // ============================================================

  void _listenForAnswer() {
    if (_callId == null) return;

    _callSubscription =
        _callingService.listenToCall(_callId!).listen(
      (snapshot) async {
        if (!snapshot.exists) {
          return;
        }

        final data = snapshot.data();

        if (data == null) {
          return;
        }

        final answer = data['answer'];

        if (answer != null && !_remoteDescriptionSet) {
          try {
            debugPrint('ANSWER RECEIVED FROM FIRESTORE');

            final remoteDescription = RTCSessionDescription(
              answer['sdp'],
              answer['type'],
            );

            await _webRTCService.setRemoteDescription(
              remoteDescription,
            );

            _remoteDescriptionSet = true;

            debugPrint('REMOTE ANSWER SET');

            await _flushPendingRemoteCandidates();

            if (mounted) {
              setState(() {
                _connectionStatus = 'Connected';
                _isCalling = false;
              });

              _startTimer();
            }
          } catch (e, stackTrace) {
            debugPrint('SET ANSWER ERROR: $e');
            debugPrint('$stackTrace');
          }
        }

        final status = data['status'];

        if (status == 'ended' || status == 'rejected') {
          await _handleRemoteCallEnded();
        }
      },
    );
  }

  // ============================================================
  // REMOTE ICE CANDIDATES
  // ============================================================

  void _listenForRemoteCandidates({
    required String collectionName,
  }) {
    if (_callId == null) return;

    _remoteCandidatesSubscription =
        _callingService
            .listenToCandidates(
      callId: _callId!,
      collectionName: collectionName,
    )
            .listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) {
            continue;
          }

          final data = change.doc.data();

          if (data == null) {
            continue;
          }

          try {
            final candidate = RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            );

            if (_remoteDescriptionSet) {
              await _webRTCService.addIceCandidate(candidate);

              debugPrint(
                'REMOTE ICE CANDIDATE ADDED',
              );
            } else {
              _pendingRemoteCandidates.add(candidate);

              debugPrint(
                'ICE CANDIDATE QUEUED',
              );
            }
          } catch (e) {
            debugPrint(
              'ICE CANDIDATE ERROR: $e',
            );
          }
        }
      },
    );
  }

  // ============================================================
  // FLUSH QUEUED ICE
  // ============================================================

  Future<void> _flushPendingRemoteCandidates() async {
    if (!_remoteDescriptionSet) {
      return;
    }

    if (_pendingRemoteCandidates.isEmpty) {
      return;
    }

    debugPrint(
      'ADDING ${_pendingRemoteCandidates.length} '
      'QUEUED ICE CANDIDATES',
    );

    for (final candidate in _pendingRemoteCandidates) {
      try {
        await _webRTCService.addIceCandidate(candidate);

        debugPrint(
          'QUEUED ICE CANDIDATE ADDED',
        );
      } catch (e) {
        debugPrint(
          'QUEUED ICE ERROR: $e',
        );
      }
    }

    _pendingRemoteCandidates.clear();
  }

  // ============================================================
  // TIMER
  // ============================================================

  void _startTimer() {
    if (_timer != null) {
      return;
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) return;

        setState(() {
          _callDuration++;
        });
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // MUTE
  // ============================================================

  void _toggleMute() {
    final stream = _webRTCService.localStream;

    if (stream == null) {
      return;
    }

    for (final track in stream.getAudioTracks()) {
      track.enabled = !_isMuted;
    }

    setState(() {
      _isMuted = !_isMuted;
    });
  }

  // ============================================================
  // CAMERA
  // ============================================================

  void _toggleCamera() {
    final stream = _webRTCService.localStream;

    if (stream == null) {
      return;
    }

    for (final track in stream.getVideoTracks()) {
      track.enabled = !_isCameraOn;
    }

    setState(() {
      _isCameraOn = !_isCameraOn;
    });
  }

  // ============================================================
  // SWITCH CAMERA
  // ============================================================

  Future<void> _switchCamera() async {
    final stream = _webRTCService.localStream;

    if (stream == null) {
      return;
    }

    final videoTracks = stream.getVideoTracks();

    if (videoTracks.isEmpty) {
      return;
    }

    try {
      await Helper.switchCamera(
        videoTracks.first,
      );

      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });
    } catch (e) {
      debugPrint(
        'SWITCH CAMERA ERROR: $e',
      );
    }
  }

  // ============================================================
  // SPEAKER
  // ============================================================

  Future<void> _toggleSpeaker() async {
    try {
      await Helper.setSpeakerphoneOn(
        !_isSpeakerOn,
      );

      setState(() {
        _isSpeakerOn = !_isSpeakerOn;
      });
    } catch (e) {
      debugPrint(
        'SPEAKER ERROR: $e',
      );
    }
  }

  // ============================================================
  // END CALL
  // ============================================================

  Future<void> _endCall() async {
    if (_isEndingCall) return;

    _isEndingCall = true;

    try {
      _timer?.cancel();
      _timer = null;

      if (_callId != null) {
        try {
          await _callingService.endCall(_callId!);
        } catch (e) {
          debugPrint(
            'END CALL FIRESTORE ERROR: $e',
          );
        }
      }

      await _cleanup();

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      debugPrint(
        'END CALL ERROR: $e',
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // ============================================================
  // REMOTE CALL ENDED
  // ============================================================

  Future<void> _handleRemoteCallEnded() async {
    if (_isEndingCall) return;

    _isEndingCall = true;

    debugPrint(
      'REMOTE USER ENDED THE CALL',
    );

    _timer?.cancel();
    _timer = null;

    await _cleanup();

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  Future<void> _cleanup() async {
    debugPrint(
      '========== CALL CLEANUP START ==========',
    );

    _timer?.cancel();
    _timer = null;

    try {
      await _callSubscription?.cancel();
    } catch (e) {
      debugPrint(
        'CALL SUBSCRIPTION CANCEL ERROR: $e',
      );
    }

    try {
      await _remoteCandidatesSubscription?.cancel();
    } catch (e) {
      debugPrint(
        'CANDIDATE SUBSCRIPTION CANCEL ERROR: $e',
      );
    }

    _callSubscription = null;
    _remoteCandidatesSubscription = null;

    _pendingRemoteCandidates.clear();

    // Clear renderer streams first.
    try {
      _localRenderer.srcObject = null;
    } catch (e) {
      debugPrint(
        'LOCAL RENDERER CLEAR ERROR: $e',
      );
    }

    try {
      _remoteRenderer.srcObject = null;
    } catch (e) {
      debugPrint(
        'REMOTE RENDERER CLEAR ERROR: $e',
      );
    }

    // Dispose WebRTC.
    try {
      await _webRTCService.dispose();
    } catch (e) {
      debugPrint(
        'WEBRTC DISPOSE ERROR: $e',
      );
    }

    debugPrint(
      '========== CALL CLEANUP COMPLETE ==========',
    );
  }

  @override
  void dispose() {
    debugPrint('CALL SCREEN DISPOSE');

    _timer?.cancel();
    _timer = null;

    _callSubscription?.cancel();
    _remoteCandidatesSubscription?.cancel();

    _callSubscription = null;
    _remoteCandidatesSubscription = null;

    _localRenderer.srcObject = null;
    _remoteRenderer.srcObject = null;

    _webRTCService.dispose();

    _localRenderer.dispose();
    _remoteRenderer.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isVideo) {
      return _buildVideoCallScreen();
    }

    return _buildAudioCallScreen();
  }

  // ============================================================
  // AUDIO CALL SCREEN
  // ============================================================

  Widget _buildAudioCallScreen() {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _endCall,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Audio Call',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.user.name.isNotEmpty
                          ? widget.user.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _connectionStatus,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_isCalling &&
                      _connectionStatus == 'Connected')
                    Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (_isCalling) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
            if (!_isCalling)
              Padding(
                padding: const EdgeInsets.only(
                  left: 25,
                  right: 25,
                  bottom: 40,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCallControl(
                      icon: _isMuted
                          ? Icons.mic_off
                          : Icons.mic,
                      label: _isMuted ? 'Unmute' : 'Mute',
                      onPressed: _toggleMute,
                    ),
                    _buildEndCallButton(),
                    _buildCallControl(
                      icon: _isSpeakerOn
                          ? Icons.volume_up
                          : Icons.volume_down,
                      label: _isSpeakerOn
                          ? 'Speaker'
                          : 'Earpiece',
                      onPressed: _toggleSpeaker,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VIDEO CALL SCREEN
  // ============================================================

  Widget _buildVideoCallScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // --------------------------------------------------
            // REMOTE VIDEO
            // --------------------------------------------------

            Positioned.fill(
              child: _remoteRenderer.srcObject != null
                  ? RTCVideoView(
                      _remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit
                              .RTCVideoViewObjectFitCover,
                    )
                  : Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white,
                              child: Text(
                                widget.user.name.isNotEmpty
                                    ? widget.user.name[0]
                                        .toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              widget.user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _connectionStatus,
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // --------------------------------------------------
            // TOP INFORMATION
            // --------------------------------------------------

            Positioned(
              top: 15,
              left: 15,
              right: 15,
              child: Row(
                children: [
                  IconButton(
                    onPressed: _endCall,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isCalling)
                        Text(
                          _formatDuration(_callDuration),
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // LOCAL VIDEO
            // --------------------------------------------------

            Positioned(
              top: 75,
              right: 15,
              child: Container(
                width: 110,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
                child: _isCameraOn &&
                        _localRenderer.srcObject != null
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(12),
                        child: RTCVideoView(
                          _localRenderer,
                          mirror: _isFrontCamera,
                          objectFit:
                              RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
                        ),
                      )
                    : const Icon(
                        Icons.videocam_off,
                        color: Colors.white,
                        size: 35,
                      ),
              ),
            ),

            // --------------------------------------------------
            // CONTROLS
            // --------------------------------------------------

            Positioned(
              left: 0,
              right: 0,
              bottom: 25,
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                children: [
                  _buildVideoControl(
                    icon: _isMuted
                        ? Icons.mic_off
                        : Icons.mic,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    onPressed: _toggleMute,
                  ),
                  _buildVideoControl(
                    icon: _isCameraOn
                        ? Icons.videocam
                        : Icons.videocam_off,
                    label: _isCameraOn
                        ? 'Camera'
                        : 'Camera Off',
                    onPressed: _toggleCamera,
                  ),
                  _buildVideoControl(
                    icon: Icons.cameraswitch,
                    label: 'Switch',
                    onPressed: _switchCamera,
                  ),
                  _buildEndCallButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AUDIO CONTROL
  // ============================================================

  Widget _buildCallControl({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white24,
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // VIDEO CONTROL
  // ============================================================

  Widget _buildVideoControl({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: Colors.white24,
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // END CALL BUTTON
  // ============================================================

  Widget _buildEndCallButton() {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.red,
          child: IconButton(
            onPressed: _endCall,
            icon: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'End',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}