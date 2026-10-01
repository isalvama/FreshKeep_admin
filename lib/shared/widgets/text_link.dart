import 'package:flutter/material.dart';

/// Text that reads and acts as a link: underlined, primary-colored,
/// focusable and activated by Enter like any button.
class TextLink extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  /// Merged under the link's own color and underline.
  final TextStyle? style;

  const TextLink({
    super.key,
    required this.text,
    required this.onPressed,
    this.style,
  });

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
        overflow: TextOverflow.ellipsis,
        style: (style ?? const TextStyle()).copyWith(
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
