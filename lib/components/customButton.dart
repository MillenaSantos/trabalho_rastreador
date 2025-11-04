import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String text;
  final Color color;
  final bool disabled;
  final Color? textColor; // <- opcional

  MyButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.color,
    this.disabled = false,
    this.textColor, // <- opcional
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: MaterialButton(
          disabledColor: Colors.blueGrey[300],
          color: color,
          height: 48,
          onPressed: disabled ? null : onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  color:
                      textColor ?? Colors.white, // <- usa branco se não passar
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
