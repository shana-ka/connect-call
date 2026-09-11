import 'package:flutter/material.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null
            ? Icon(icon)
            : const SizedBox.shrink(),
        label: Text(text),
      ),
    );
  }
}