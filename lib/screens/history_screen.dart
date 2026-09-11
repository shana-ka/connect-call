
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connect_call/services/calling_service.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  final CallingService _callingService = CallingService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Check whether user is logged in
    if (user == null) {
      return const Center(
        child: Text('User not logged in'),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _callingService.getCallHistory(user.uid),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Error
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading call history:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Get calls
        final calls = [...(snapshot.data?.docs ?? [])];

        // Sort by createdAt - newest first
        calls.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;

          if (aTime == null && bTime == null) {
            return 0;
          }

          if (aTime == null) {
            return 1;
          }

          if (bTime == null) {
            return -1;
          }

          return bTime.compareTo(aTime);
        });

        // No history
        if (calls.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 60,
                  color: Colors.grey,
                ),
                SizedBox(height: 15),
                Text(
                  'No call history',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        // Display call history
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: calls.length,
          itemBuilder: (context, index) {
            final data = calls[index].data();

            // Caller ID
            final callerId = data['callerId'] ?? '';

            // Check incoming/outgoing
            final isOutgoing = callerId == user.uid;

            // Call type
            final type = data['type'] ?? 'audio';

            // User name
            final name = isOutgoing
                ? (data['receiverName'] ?? 'User')
                : (data['callerName'] ?? 'User');

            // Call status
            final status = data['status'] ?? 'unknown';

            // Call time
            final timestamp = data['createdAt'] as Timestamp?;

            String dateTimeText = '';

            if (timestamp != null) {
              final dateTime = timestamp.toDate();

              final hour = dateTime.hour > 12
                  ? dateTime.hour - 12
                  : dateTime.hour == 0
                      ? 12
                      : dateTime.hour;

              final minute = dateTime.minute.toString().padLeft(2, '0');

              final period = dateTime.hour >= 12 ? 'PM' : 'AM';

              dateTimeText =
                  '${dateTime.day}/${dateTime.month}/${dateTime.year} '
                  '$hour:$minute $period';
            }

            // Icon
            final callIcon = type == 'video'
                ? Icons.videocam
                : Icons.call;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),

                // User avatar
                leading: CircleAvatar(
                  radius: 25,
                  child: Icon(callIcon),
                ),

                // Name
                title: Text(
                  name.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                // Incoming / outgoing + date
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(
                          isOutgoing
                              ? Icons.call_made
                              : Icons.call_received,
                          size: 16,
                          color: isOutgoing
                              ? Colors.blue
                              : Colors.green,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isOutgoing ? 'Outgoing' : 'Incoming',
                        ),
                      ],
                    ),

                    if (dateTimeText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateTimeText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),

                // Audio / Video + status
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      type == 'video' ? 'Video' : 'Audio',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: status == 'ended'
                            ? Colors.grey
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
