import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../state/student_state.dart';

class StudentStatusScreen extends StatelessWidget {
  const StudentStatusScreen({super.key, required this.onViewDetails});

  final VoidCallback onViewDetails;

  static const _areas = [
    _Area('Library'),
    _Area('Fee & Dues Department'),
    _Area('Student Service Department'),
    _Area(
      'Laboratory',
      note: 'Applies only if you have laboratory records or items. '
          'Shown as Not Required only after official verification.',
    ),
    _Area('Coordination Office'),
  ];

  DepartmentStatusItem? _find(StudentRequestStatus? r, String name) {
    if (r == null) return null;
    for (final d in r.departments) {
      if (d.name == name) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<StudentState>().currentRequest;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: const Text(
              'Clearance Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RequestSummary(request: request),
                  const SizedBox(height: 14),
                  const _InfoBox(
                    icon: Icons.info_outline,
                    child: Text(
                      'Each department is shown independently. '
                          'No processing order is assumed.',
                      style: TextStyle(
                          fontSize: 12.5, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Departments',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final area in _areas)
                    _DepartmentCard(
                      area: area,
                      item: _find(request, area.name),
                      onTap: onViewDetails,
                    ),
                  const SizedBox(height: 6),
                  _InfoBox(
                    icon: Icons.school_outlined,
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.primary,
                            height: 1.35),
                        children: [
                          TextSpan(
                            text: 'Next step after clearance: ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: 'once you are cleared by all required '
                                'areas, take your cleared certificate to the '
                                'Examination Department. It verifies the '
                                'certificate and issues your final '
                                'transcript. This is not a clearance stage.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: onViewDetails,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.textDark,
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('View Request Details',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Area {
  const _Area(this.name, {this.note});
  final String name;
  final String? note;
}

class _RequestSummary extends StatelessWidget {
  const _RequestSummary({required this.request});
  final StudentRequestStatus? request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: r == null
          ? const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No active request',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          SizedBox(height: 4),
          Text(
            'Department statuses appear here after a clearance '
                'request has been submitted and the server reports them.',
            style:
            TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                r.referenceNumber,
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppTheme.textMuted),
              ),
              _Badge(label: r.overallStatus, kind: _BadgeKind.pending),
            ],
          ),
          const SizedBox(height: 6),
          Text('Submitted ${r.submittedOn}',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.child});
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.infoBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD8F5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({
    required this.area,
    required this.item,
    required this.onTap,
  });

  final _Area area;
  final DepartmentStatusItem? item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final i = item;
    final badge = i == null
        ? const _Badge(label: 'Not available', kind: _BadgeKind.unknown)
        : switch (i.status) {
      DepartmentStatus.pending =>
      const _Badge(label: 'Pending', kind: _BadgeKind.pending),
      DepartmentStatus.cleared =>
      const _Badge(label: 'Cleared', kind: _BadgeKind.cleared),
      DepartmentStatus.notRequired =>
      const _Badge(label: 'Not Required', kind: _BadgeKind.unknown),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    area.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 20, color: AppTheme.textMuted),
              ],
            ),
            const SizedBox(height: 8),
            badge,
            const SizedBox(height: 8),
            Text(
              i == null
                  ? 'No data from the server yet'
                  : (i.updateText ?? 'No update yet'),
              style:
              const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            if (area.note != null) ...[
              const SizedBox(height: 4),
              Text(
                area.note!,
                style: const TextStyle(
                    fontSize: 11.5, color: AppTheme.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _BadgeKind { pending, cleared, unknown }

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.kind});
  final String label;
  final _BadgeKind kind;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (kind) {
      case _BadgeKind.pending:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
      case _BadgeKind.cleared:
        bg = const Color(0xFFE6F4EA);
        fg = const Color(0xFF15803D);
      case _BadgeKind.unknown:
        bg = const Color(0xFFEEF1F5);
        fg = AppTheme.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}