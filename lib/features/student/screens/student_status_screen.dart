import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/student_state.dart';
import '../widgets/student_widgets.dart';

class StudentStatusScreen extends StatelessWidget {
  const StudentStatusScreen({super.key, required this.onViewDetails});

  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentState>();
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Text(
              'Clearance Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: state.refreshDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _content(context, state),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context, StudentState state) {
    final cs = Theme.of(context).colorScheme;

    if (state.dashboardLoad == LoadState.loading) {
      return const [
        SizedBox(height: 80),
        Center(child: CircularProgressIndicator()),
      ];
    }
    if (state.dashboardLoad == LoadState.error) {
      return [
        CardBox(
          child: ErrorRetry(
            message:
            state.dashboardError ??
                'Could not load your clearance status. Please try again.',
            onRetry: () => state.refreshDashboard(),
          ),
        ),
      ];
    }

    // The active request, or else the latest closed one (for example a request
    // that the server completed automatically at submit).
    final request = state.displayRequest;
    final progress = state.hasActiveRequest ? state.progress : null;

    return [
      _RequestSummary(
        request: request,
        progress: progress,
        hasClosedRequests: state.closedRequestCount > 0,
      ),
      const SizedBox(height: 14),
      InfoBanner(
        icon: Icons.info_outline,
        child: Text(
          'Each department is shown independently. '
              'No processing order is assumed.',
          style: TextStyle(fontSize: 12.5, color: cs.onPrimaryContainer),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Departments',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
      const SizedBox(height: 10),
      for (final area in kClearanceAreas)
        _DepartmentCard(
          area: area,
          item: findDepartment(
            request?.departments,
            area.name,
            code: area.code,
          ),
          onTap: onViewDetails,
        ),
      const SizedBox(height: 6),
      InfoBanner(
        icon: Icons.school_outlined,
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onPrimaryContainer,
              height: 1.35,
            ),
            children: const [
              TextSpan(
                text: 'Next step after clearance: ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text:
                'once you are cleared by all required '
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
            backgroundColor: cs.surface,
            foregroundColor: cs.onSurface,
            side: BorderSide(color: cs.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'View Request Details',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ];
  }
}

class _RequestSummary extends StatelessWidget {
  const _RequestSummary({
    required this.request,
    required this.progress,
    required this.hasClosedRequests,
  });

  final StudentRequestStatus? request;
  final StudentProgress? progress;
  final bool hasClosedRequests;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = request;
    if (r == null) {
      return CardBox(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No active request',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasClosedRequests
                  ? 'Your latest request is closed. '
                  'See your history on the dashboard.'
                  : 'Department statuses appear here after a clearance '
                  'request has been submitted.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final badgeColor = r.overallStatus == 'Completed'
        ? const Color(0xFF16A34A)
        : cs.primary;

    return CardBox(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  r.referenceNumber,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              PillBadge(label: r.overallStatus, color: badgeColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Submitted ${r.submittedOn}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            ProgressSummary(progress: progress!),
          ],
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

  final ClearanceArea area;
  final DepartmentStatusItem? item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final i = item;
    final reason = i?.reason;

    final String caption;
    if (i == null) {
      caption = 'No data from the server yet';
    } else if (i.status == DepartmentStatus.undetermined) {
      caption = 'Whether this department applies has not been decided yet.';
    } else {
      caption = i.updateText ?? 'No update yet';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 8),
            StatusBadge(status: i?.status),
            const SizedBox(height: 8),
            Text(
              caption,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            if (reason != null) ...[
              const SizedBox(height: 4),
              // Plain text only. The reason comes from the backend.
              Text(
                reason,
                style: TextStyle(fontSize: 12, color: cs.onSurface),
              ),
            ],
            if (area.note != null) ...[
              const SizedBox(height: 4),
              Text(
                area.note!,
                style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}