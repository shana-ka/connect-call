
import 'package:cloud_firestore/cloud_firestore.dart';

class CallingService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// Create a new call document.
  ///
  /// The returned ID is used by WebRTC signaling.
  Future<String> createCall({
    required String callerId,
    required String receiverId,
    required String callerName,
    required String receiverName,
    required String type,
  }) async {
    final callRef = await _firestore.collection('calls').add({
      'callerId': callerId,
      'receiverId': receiverId,
      'callerName': callerName,
      'receiverName': receiverName,
      'type': type,

      // The call is initially waiting for the receiver.
      'status': 'ringing',

      'offer': null,
      'answer': null,

      'createdAt': FieldValue.serverTimestamp(),
    });

    return callRef.id;
  }

  /// Update the WebRTC offer.
  Future<void> setOffer({
    required String callId,
    required Map<String, dynamic> offer,
  }) async {
    await _firestore.collection('calls').doc(callId).update({
      'offer': offer,
    });
  }

  /// Update the WebRTC answer.
  Future<void> setAnswer({
    required String callId,
    required Map<String, dynamic> answer,
  }) async {
    await _firestore.collection('calls').doc(callId).update({
      'answer': answer,
      'status': 'connected',
    });
  }

  /// Add an ICE candidate.
  Future<void> addIceCandidate({
    required String callId,
    required String collectionName,
    required Map<String, dynamic> candidate,
  }) async {
    await _firestore
        .collection('calls')
        .doc(callId)
        .collection(collectionName)
        .add(candidate);
  }

  /// Listen to changes in a call document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToCall(
    String callId,
  ) {
    return _firestore
        .collection('calls')
        .doc(callId)
        .snapshots();
  }

  /// Listen to ICE candidates.
  Stream<QuerySnapshot<Map<String, dynamic>>> listenToCandidates({
    required String callId,
    required String collectionName,
  }) {
    return _firestore
        .collection('calls')
        .doc(callId)
        .collection(collectionName)
        .snapshots();
  }

  /// Update call status.
  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': status,
    });
  }

  /// End/delete a call.
  Future<void> endCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get call history.
  /// Get call history.
Stream<QuerySnapshot<Map<String, dynamic>>> getCallHistory(
  String uid,
) {
  return _firestore
      .collection('calls')
      .where(
        Filter.or(
          Filter('callerId', isEqualTo: uid),
          Filter('receiverId', isEqualTo: uid),
        ),
      )
      .snapshots();
}
}

