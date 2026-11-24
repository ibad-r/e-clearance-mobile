import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StepProgressBar extends StatelessWidget {
  const StepProgressBar({super.key, required this.step, this.total = 3});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < total; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: i < step ? AppTheme.primary : AppTheme.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    ],
  );
}