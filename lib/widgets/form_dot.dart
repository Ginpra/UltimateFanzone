import 'package:flutter/material.dart';

/// Bulatan hasil laga: W menang (hijau), D seri (abu-abu), L kalah (merah).
class FormDot extends StatelessWidget {
  const FormDot({super.key, required this.result});

  final String result;

  @override
  Widget build(BuildContext context) {
    final color = result == 'W'
        ? Colors.green
        : (result == 'L' ? Colors.red : Colors.grey);
    return CircleAvatar(
      radius: 13,
      backgroundColor: color,
      child: Text(
        result,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
