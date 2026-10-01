import 'package:flutter/material.dart';

/// Text that reads and acts as a link: underlined, primary-colored,
/// focusable and activated by Enter like any button.
class TextLink extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const TextLink({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerLeft,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(decoration: TextDecoration.underline),
      ),
    );
  }
}
