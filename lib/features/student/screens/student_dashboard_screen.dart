import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../state/student_state.dart';

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
    final profile = state.profile;
    final ready = state.dashboardLoad == DashboardLoadState.ready;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: state.refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(profile: profile),
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
              if (state.history.isEmpty)
                const _EmptyHistory()
              else
                ...state.history.take(3).map((h) => _HistoryTile(item: h)),
              if (kDebugMode) _DebugPreviewPanel(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared card container (theme-aware, works in Light and Dark)
// ---------------------------------------------------------------------------
class _CardBox extends StatelessWidget {
  const _CardBox({required this.child, this.padding = const EdgeInsets.all(16)});
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
                    : 'SAP ${p.sapId} · ${p.program}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Current request area: loading / error / active / empty
// ---------------------------------------------------------------------------
class _RequestSection extends StatelessWidget {
  const _RequestSection({required this.state});
  final StudentState state;

  @override
  Widget build(BuildContext context) {
    switch (state.dashboardLoad) {
      case DashboardLoadState.loading:
        return const _LoadingCard();
      case DashboardLoadState.error:
        return _ErrorCard(
          message: state.dashboardError ??
              'Could not load your dashboard. Please try again.',
          onRetry: state.refreshDashboard,
        );
      case DashboardLoadState.ready:
        return state.hasActiveRequest
            ? _ActiveRequestCard(
          request: state.currentRequest,
          isPreview: state.isPreview,
        )
            : const _EmptyRequestCard();
    }
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

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _CardBox(
      padding: EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(),
          const SizedBox(height: 12),
          Row(
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
      ),
    );
  }
}

class _EmptyRequestCard extends StatelessWidget {
  const _EmptyRequestCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _CardBox(
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
  const _ActiveRequestCard({required this.request, required this.isPreview});
  final StudentRequestStatus? request;
  final bool isPreview;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = request;
    return _CardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(),
          if (isPreview) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'DEMO / PREVIEW - local sample, not live server data',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onTertiaryContainer,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r?.referenceNumber ?? 'Reference not available',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r == null
                          ? 'Request details not available yet'
                          : 'Submitted: ${r.submittedOn}',
                      style:
                      TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (r != null)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    r.overallStatus,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer),
                  ),
                ),
            ],
          ),
          if (r != null && r.departments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Department progress',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            // Each department is shown on its own. No percentage, no locking.
            for (final d in r.departments) _DepartmentRow(item: d),
          ],
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
    final (String label, IconData icon, Color color) = switch (item.status) {
      DepartmentStatus.cleared =>
      ('Cleared', Icons.check_circle, Colors.green.shade600),
      DepartmentStatus.pending =>
      ('Pending', Icons.schedule, cs.onSurfaceVariant),
      DepartmentStatus.notRequired =>
      ('Not required', Icons.remove_circle_outline, cs.onSurfaceVariant),
    };
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
          Icon(icon, size: 18, color: color),
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
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return _CardBox(
      child: Text(
        'No clearance history yet.',
        style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});
  final StudentHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.referenceNumber,
                    style:
                    TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(item.type,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 2),
                Text('${item.dateLabel} · ${item.statusLabel}',
                    style:
                    TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Debug-only panel for Phase 1 screenshots. Not shown in release builds.
// Remove it (or keep it hidden) when the real API is connected.
// ---------------------------------------------------------------------------
class _DebugPreviewPanel extends StatelessWidget {
  const _DebugPreviewPanel({required this.state});
  final StudentState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DEBUG: preview dashboard states (local only)',
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                  label: const Text('Active (DEMO)'),
                  onPressed: state.previewActive),
              ActionChip(
                  label: const Text('Empty'), onPressed: state.previewEmpty),
              ActionChip(
                  label: const Text('Loading'),
                  onPressed: state.previewLoading),
              ActionChip(
                  label: const Text('Error'), onPressed: state.previewError),
            ],
          ),
        ],
      ),
    );
  }
}