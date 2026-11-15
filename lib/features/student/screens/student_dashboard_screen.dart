import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../state/student_state.dart';
import '../widgets/student_widgets.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({
    super.key,
    required this.onNewRequest,
    required this.onViewStatus,
    required this.onViewHistory,
  });

  final VoidCallback onNewRequest;
  final VoidCallback onViewStatus;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentState>();
    final cs = Theme.of(context).colorScheme;
    final ready = state.dashboardLoad == LoadState.ready;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: state.refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(profile: state.profile),
              const SizedBox(height: 20),
              _RequestSection(state: state),
              const SizedBox(height: 14),
              if (ready && !state.hasActiveRequest) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onNewRequest,
                    icon: const Icon(Icons.note_add_outlined, size: 18),
                    label: const Text('New Clearance Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (ready)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onViewStatus,
                    icon: const Icon(Icons.checklist, size: 18),
                    label: const Text('View Clearance Status'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: cs.surface,
                      foregroundColor: cs.onSurface,
                      side: BorderSide(color: cs.outlineVariant),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Clearance History',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: onViewHistory,
                    child: const Text(
                      'View all',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (ready) _HistoryPreview(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});
  final StudentProfile? profile;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = profile;
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.primary,
          child: Text(
            p == null ? '?' : _initials(p.name),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome,',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              Text(
                p?.name ?? 'Student',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              Text(
                p == null
                    ? 'Profile details not available yet'
                    : 'SAP ${p.sapId}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'CURRENT CLEARANCE REQUEST',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Loading / error / active / empty. A failed load is never shown as empty.
class _RequestSection extends StatelessWidget {
  const _RequestSection({required this.state});
  final StudentState state;

  @override
  Widget build(BuildContext context) {
    switch (state.dashboardLoad) {
      case LoadState.loading:
        return const CardBox(
          padding: EdgeInsets.symmetric(vertical: 36, horizontal: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      case LoadState.error:
        return CardBox(
          child: ErrorRetry(
            message: state.dashboardError ??
                'Could not load your dashboard. Please try again.',
            onRetry: () => state.refreshDashboard(),
          ),
        );
      case LoadState.ready:
        return state.hasActiveRequest
            ? _ActiveRequestCard(request: state.currentRequest)
            : const _EmptyRequestCard();
    }
  }
}

class _EmptyRequestCard extends StatelessWidget {
  const _EmptyRequestCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.hourglass_empty,
                    size: 20, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No active request',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text('You have not submitted a clearance request.',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveRequestCard extends StatelessWidget {
  const _ActiveRequestCard({required this.request});
  final StudentRequestStatus? request;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = request;
    if (r == null) return const _EmptyRequestCard();

    return CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.referenceNumber,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Submitted: ${r.submittedOn}',
                      style:
                      TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              PillBadge(label: r.overallStatus, color: cs.primary),
            ],
          ),
          const SizedBox(height: 16),
          Text('Department progress',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          // Exactly what the server returned. No percentage, no locking.
          if (r.departments.isEmpty)
            Text('Department statuses are not available yet.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant))
          else
            for (final d in r.departments) _DepartmentRow(item: d),
        ],
      ),
    );
  }
}

class _DepartmentRow extends StatelessWidget {
  const _DepartmentRow({required this.item});
  final DepartmentStatusItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = StatusStyle.of(item.status, cs);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(style.icon, size: 18, color: style.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface),
            ),
          ),
          Text(style.label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: style.color)),
        ],
      ),
    );
  }
}

class _HistoryPreview extends StatelessWidget {
  const _HistoryPreview({required this.state});
  final StudentState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final latest = state.latestClosed;
    if (state.closedRequestCount == 0 || latest == null) {
      return CardBox(
        child: Text(
          'No clearance history yet.',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CardBox(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(latest.referenceNumber,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(latest.type,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
              const SizedBox(height: 2),
              Text('${latest.dateLabel} · ${latest.statusLabel}',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        if (state.closedRequestCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              '${state.closedRequestCount} closed requests in total',
              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}