import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../state/student_state.dart';

class StudentDetailsScreen extends StatelessWidget {
  const StudentDetailsScreen({super.key});

  static const _missing = 'Not available yet';

  static const _areas = [
    'Library',
    'Fee & Dues Department',
    'Student Service Department',
    'Laboratory',
    'Coordination Office',
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
    final state = context.watch<StudentState>();
    final cs = Theme.of(context).colorScheme;
    final request = state.currentRequest;
    final profile = state.profile;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 22),
                    tooltip: 'Back',
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Request Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Overall status',
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          request == null
                              ? const _Badge(
                              label: 'Not available',
                              kind: _BadgeKind.unknown)
                              : _Badge(
                              label: request.overallStatus,
                              kind: _BadgeKind.pending),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Request information'),
                    // TODO(student-api): fill father's name, semester and
                    // clearance reason from the server's request record.
                    _Card(
                      children: [
                        _InfoRow('Reference No.',
                            request?.referenceNumber ?? _missing),
                        _InfoRow('Submission Date',
                            request?.submittedOn ?? _missing),
                        _InfoRow('Student Name', profile?.name ?? _missing),
                        _InfoRow('SAP ID', profile?.sapId ?? _missing),
                        _InfoRow('Registration No.',
                            profile?.registrationNumber ?? _missing),
                        const _InfoRow("Father's Name", _missing),
                        _InfoRow('Program', profile?.program ?? _missing),
                        const _InfoRow('Semester', _missing),
                        const _InfoRow('Clearance Reason', _missing,
                            last: true),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Department-wise status'),
                    _Card(
                      children: [
                        for (var i = 0; i < _areas.length; i++)
                          _DepartmentRow(
                            name: _areas[i],
                            ifRequired: _areas[i] == 'Laboratory',
                            item: _find(request, _areas[i]),
                            last: i == _areas.length - 1,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Outstanding requirements'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Text(
                        request == null
                            ? 'No data from the server yet.'
                            : 'No outstanding requirements have been '
                            'reported.',
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
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
                          Icon(Icons.school_outlined,
                              size: 16, color: cs.onPrimaryContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: cs.onPrimaryContainer,
                                    height: 1.35),
                                children: const [
                                  TextSpan(
                                    text: 'Next step after clearance: ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                    text: 'once you are cleared by all '
                                        'required areas, take your cleared '
                                        'certificate to the Examination '
                                        'Department. It verifies the '
                                        'certificate and issues your final '
                                        'transcript. This is not a '
                                        'clearance stage.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
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

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.last = false});
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

class _DepartmentRow extends StatelessWidget {
  const _DepartmentRow({
    required this.name,
    required this.item,
    this.ifRequired = false,
    this.last = false,
  });

  final String name;
  final DepartmentStatusItem? item;
  final bool ifRequired;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    if (ifRequired)
                      const Text(
                        'If Required',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97706),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  i == null
                      ? 'No data from the server yet'
                      : (i.updateText ?? 'No update yet'),
                  style:
                  TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          badge,
        ],
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
    final cs = Theme.of(context).colorScheme;
    final Color fg = switch (kind) {
      _BadgeKind.pending => const Color(0xFFD97706),
      _BadgeKind.cleared => const Color(0xFF16A34A),
      _BadgeKind.unknown => cs.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.15),
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