import 'package:flutter/material.dart';

class PendingHrChip extends StatelessWidget {
  const PendingHrChip({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3E0),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFBD9A5)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle_outlined, size: 11, color: Color(0xFFB45309)),
        SizedBox(width: 5),
        Text(
          'Pending HR Verification',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB45309)),
        ),
      ],
    ),
  );
}