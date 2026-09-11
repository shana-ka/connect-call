import 'package:flutter/material.dart';
import 'package:connect_call/models/user_model.dart';
import 'package:connect_call/widgets/call_button.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onAudioCall;
  final VoidCallback onVideoCall;

  const UserTile({
    super.key,
    required this.user,
    required this.onAudioCall,
    required this.onVideoCall,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOnline = user.status == 'Online';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              const Color.fromARGB(255, 18, 108, 136),
          backgroundImage: user.profileImage != null
              ? NetworkImage(user.profileImage!)
              : null,
          child: user.profileImage == null
              ? Text(
                  user.name.isNotEmpty
                      ? user.name[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline
                    ? Colors.green
                    : Colors.grey,
              ),
            ),
            const SizedBox(width: 5),
            Text(user.status),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CallButton(
              icon: Icons.call,
              tooltip: 'Audio Call',
              onPressed: onAudioCall,
            ),
            CallButton(
              icon: Icons.videocam,
              tooltip: 'Video Call',
              onPressed: onVideoCall,
            ),
          ],
        ),
      ),
    );
  }
}