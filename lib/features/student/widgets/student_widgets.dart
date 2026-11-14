import 'package:flutter/material.dart';
import '../state/student_state.dart';

/// Label, colour and icon for each department status.
/// Unknown statuses get a neutral "Status unavailable" label.
class StatusStyle {
  const StatusStyle(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;

  static StatusStyle of(DepartmentStatus s, ColorScheme cs) => switch (s) {
    DepartmentStatus.cleared =>
    const StatusStyle('Cleared', Color(0xFF16A34A), Icons.check_circle),
    DepartmentStatus.pending =>
        StatusStyle('Pending', cs.onSurfaceVariant, Icons.schedule),
    DepartmentStatus.inReview =>
        StatusStyle('In review', cs.primary, Icons.hourglass_top),
    DepartmentStatus.actionRequired =>
        StatusStyle('Action required', cs.error, Icons.error),
    DepartmentStatus.notRequired => StatusStyle(
        'Not required', cs.onSurfaceVariant, Icons.remove_circle_outline),
    DepartmentStatus.unknown => StatusStyle(
        'Status unavailable', cs.onSurfaceVariant, Icons.help_outline),
  };
}

/// The agreed five-form roster. Examination is not a clearance stage.
class ClearanceArea {
  const ClearanceArea(this.name, {this.note});
  final String name;
  final String? note;
}

const kClearanceAreas = [
  ClearanceArea('Library'),
  ClearanceArea('Fee & Dues Department'),
  ClearanceArea('Student Service Department'),
  ClearanceArea(
    'Laboratory',
    note: 'Applies only if you have laboratory records or items. '
        'Shown as Not Required only after official verification.',
  ),
  ClearanceArea('Coordination Office'),
];

DepartmentStatusItem? findDepartment(
    List<DepartmentStatusItem>? items, String name) {
  if (items == null) return null;
  for (final d in items) {
    if (d.name.startsWith(name)) return d;
  }
  return null;
}

class PillBadge extends StatelessWidget {
  const PillBadge({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  /// null means the server has not reported this department.
  final DepartmentStatus? status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = status;
    if (s == null) {
      return PillBadge(label: 'Not available', color: cs.onSurfaceVariant);
    }
    final style = StatusStyle.of(s, cs);
    return PillBadge(label: style.label, color: style.color);
  }
}

class CardBox extends StatelessWidget {
  const CardBox(
      {super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.icon, required this.child});
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Error message with a Retry button. An error is never shown as "empty".
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: cs.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: TextStyle(fontSize: 13, color: cs.onSurface)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}