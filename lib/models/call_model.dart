import 'package:cloud_firestore/cloud_firestore.dart';

class CallModel {
  final String id;
  final String callerId;
  final String receiverId;
  final String callerName;
  final String receiverName;
  final String type;
  final String status;
  final DateTime? createdAt;

  CallModel({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callerName,
    required this.receiverName,
    required this.type,
    required this.status,
    this.createdAt,
  });

  factory CallModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return CallModel(
      id: document.id,
      callerId: data['callerId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      callerName: data['callerName'] ?? '',
      receiverName: data['receiverName'] ?? '',
      type: data['type'] ?? 'audio',
      status: data['status'] ?? 'completed',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'receiverId': receiverId,
      'callerName': callerName,
      'receiverName': receiverName,
      'type': type,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}