import 'package:flutter/material.dart';
import 'package:smart_habit_tracker/typography.dart';

/// A custom gradient button with a text label. Uses the passed [ButtonStyle] for text styling.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonStyle style;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    // Extract the textStyle from the provided ButtonStyle
    final WidgetStateProperty<TextStyle?>? textStyleProperty = style.textStyle;
    final TextStyle textStyle = textStyleProperty?.resolve({}) ??
        const TextStyle(fontSize: 16, color: Colors.white);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [T.purple_1, T.violet_0, T.blue_1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: textStyle.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
