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
    final request = state.currentRequest;
    final profile = state.profile;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Request Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Overall status',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted)),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        request == null
                            ? 'No data from the server yet.'
                            : 'No outstanding requirements have been '
                            'reported.',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBg,
                        borderRadius: BorderRadius.circular(12),
                        border:
                        Border.all(color: const Color(0xFFCBD8F5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.school_outlined,
                              size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.primary,
                                    height: 1.35),
                                children: [
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
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textDark,
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMuted)),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
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
            : const Border(bottom: BorderSide(color: AppTheme.border)),
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (ifRequired)
                      const Text(
                        'If Required',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  i == null
                      ? 'No data from the server yet'
                      : (i.updateText ?? 'No update yet'),
                  style: const TextStyle(
                      fontSize: 11.5, color: AppTheme.textMuted),
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