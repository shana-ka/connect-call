import 'package:flutter/material.dart';

class CallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const CallButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(
        icon,
        color: const Color.fromARGB(255, 18, 108, 136),
      ),
    );
  }
}