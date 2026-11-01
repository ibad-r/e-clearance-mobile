import 'package:flutter/material.dart';
import '../../models/clearance_request.dart';
import '../theme/app_theme.dart';

class StepStatusBadge extends StatelessWidget {
  final StepStatus status;
  const StepStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (label, icon, fg, bg) = switch (status) {
      StepStatus.cleared => (
      'Cleared',
      Icons.check_circle_outline,
      const Color(0xFF16803C),
      const Color(0xFFE5F5EA),
      ),
      StepStatus.processing => (
      'Processing',
      Icons.autorenew,
      AppTheme.primary,
      const Color(0xFFE6EEFC),
      ),
      StepStatus.outstanding => (
      'Outstanding',
      Icons.error_outline,
      const Color(0xFFC62828),
      const Color(0xFFFDE8E8),
      ),
      StepStatus.locked => (
      'Locked',
      Icons.lock_outline,
      const Color(0xFF64748B),
      const Color(0xFFE9EDF3),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}