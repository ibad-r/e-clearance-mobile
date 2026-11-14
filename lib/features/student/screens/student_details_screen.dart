import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/student_state.dart';
import '../widgets/student_widgets.dart';

class StudentDetailsScreen extends StatefulWidget {
  const StudentDetailsScreen({super.key});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  static const _missing = 'Not available';

  @override
  void initState() {
    super.initState();
    // After the first frame, so listeners are not notified during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StudentState>().loadDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentState>();
    final cs = Theme.of(context).colorScheme;

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
                child: _body(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, StudentState state) {
    final cs = Theme.of(context).colorScheme;

    if (state.currentRequest == null) {
      return CardBox(
        child: Text(
          'There is no active request to show.',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }
    if (state.detailLoad == LoadState.loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.detailLoad == LoadState.error) {
      return CardBox(
        child: ErrorRetry(
          message: state.detailError ??
              'Could not load the request details. Please try again.',
          onRetry: () => state.loadDetail(),
        ),
      );
    }
    final d = state.detail;
    if (d == null) {
      return CardBox(
        child: Text(
          'Request details are not available yet.',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }

    // Departments that reported "action required", straight from the server.
    final actionNames = [
      for (final dep in d.departments)
        if (dep.status == DepartmentStatus.actionRequired) dep.name,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CardBox(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overall status',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              PillBadge(label: d.overallStatus, color: cs.primary),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Request information'),
        CardBox(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              InfoRow('Reference No.', d.referenceNumber),
              InfoRow('Submission Date', d.submittedOn),
              InfoRow('Student Name', d.studentName ?? _missing),
              InfoRow('SAP ID', d.sapId ?? _missing),
              InfoRow('Registration No.', d.registrationNumber ?? _missing),
              InfoRow("Father's Name", d.fatherName ?? _missing),
              InfoRow('Program', d.program ?? _missing),
              InfoRow('Semester', d.semester ?? _missing),
              InfoRow('Clearance Reason', d.reasonLabel, last: true),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Department-wise status'),
        CardBox(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < kClearanceAreas.length; i++)
                _DepartmentRow(
                  area: kClearanceAreas[i],
                  item: findDepartment(d.departments, kClearanceAreas[i].name),
                  last: i == kClearanceAreas.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Outstanding requirements'),
        CardBox(
          padding: const EdgeInsets.all(14),
          child: Text(
            actionNames.isEmpty
                ? 'No department has reported an action required.'
                : 'Action required: ${actionNames.join(', ')}.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        InfoBanner(
          icon: Icons.school_outlined,
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                  fontSize: 12.5, color: cs.onPrimaryContainer, height: 1.35),
              children: const [
                TextSpan(
                  text: 'Next step after clearance: ',
                  style: TextStyle(fontWeight: FontWeight.w700),
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
    );
  }
}

class _DepartmentRow extends StatelessWidget {
  const _DepartmentRow({
    required this.area,
    required this.item,
    this.last = false,
  });

  final ClearanceArea area;
  final DepartmentStatusItem? item;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final i = item;
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
                      area.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    if (area.name == 'Laboratory')
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
          StatusBadge(status: i?.status),
        ],
      ),
    );
  }
}