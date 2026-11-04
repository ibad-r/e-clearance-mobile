import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/date_format.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/step_status_badge.dart';
import '../../../models/clearance_request.dart';

const _red = Color(0xFFC62828);

String _caseStatusLabel(String status) {
  switch (status) {
    case 'IN_PROGRESS':
      return 'In Progress';
    case 'PENDING_SUBMISSION':
      return 'Pending Submission';
    case 'ACTION_REQUIRED':
      return 'Action Required';
    case 'AWAITING_APPROVAL':
      return 'Awaiting Approval';
    case 'RETURNED_FOR_CORRECTION':
      return 'Returned for Correction';
    case 'COMPLETED':
      return 'Completed';
    case 'CANCELLED':
      return 'Cancelled';
    default:
      return status.isEmpty ? '—' : status.replaceAll('_', ' ');
  }
}

String _approvalStatusLabel(String status) {
  switch (status) {
    case 'WAITING':
      return 'Waiting';
    case 'PENDING':
      return 'Pending';
    case 'APPROVED':
      return 'Approved';
    case 'RETURNED':
      return 'Returned';
    case 'SKIPPED':
      return 'Skipped';
    default:
      return status.isEmpty ? '—' : status;
  }
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Always load the case from the backend when this screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final state = context.read<AppState>();
    setState(() {
      _loading = true;
      _error = null;
    });
    String? error;
    try {
      await state.refreshActiveCase();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not load your clearance status. Please try again.';
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  Color _segmentColor(ClearanceRequest r, DepartmentStep s) {
    if (s.status == StepStatus.cleared) return const Color(0xFF16803C);
    if (identical(s, r.currentStep)) {
      return s.status == StepStatus.outstanding ? _red : AppTheme.primary;
    }
    return const Color(0xFFE2E8F0);
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<AppState>().activeRequest;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Clearance Progress',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: _body(request),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _body(ClearanceRequest? request) {
    if (request == null) {
      if (_loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_error != null) {
        return _ErrorView(message: _error!, onRetry: _load);
      }
      return const Center(child: Text('No active clearance'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: _content(request),
    );
  }

  Widget _content(ClearanceRequest request) {
    final steps = request.steps;
    final stageCount = steps.length;

    // Use the progress counts sent by the backend. If they are missing,
    // fall back to counting the stages.
    final hasCounts = request.totalStages > 0;
    final total = hasCounts ? request.totalStages : stageCount;
    final cleared = hasCounts ? request.clearedStages : request.clearedCount;
    final percent = total == 0 ? 0 : ((cleared / total) * 100).round();

    final current = request.currentStep;
    final stageNo = current == null ? stageCount : steps.indexOf(current) + 1;
    final isOutstanding = current?.status == StepStatus.outstanding;

    String whereAmI;
    if (stageCount == 0) {
      whereAmI = 'No stages available yet';
    } else if (current == null) {
      whereAmI = 'All stages cleared';
    } else {
      whereAmI = 'Stage $stageNo of $stageCount · ${current.department}';
    }

    String checkingNow;
    if (current == null) {
      checkingNow = 'Nothing pending';
    } else if (current.status == StepStatus.processing) {
      checkingNow = current.department;
    } else if (isOutstanding) {
      checkingNow = 'Paused at ${current.department}';
    } else {
      checkingNow = 'Not started yet';
    }

    String nextStep;
    if (isOutstanding) {
      nextStep = 'Resolve the issue with the department';
    } else if (current == null) {
      nextStep = stageCount == 0 ? 'Waiting for stages' : 'Final approval';
    } else {
      nextStep = 'Waiting for ${current.department}';
    }

    final clearedText = cleared == 0
        ? 'Nothing yet'
        : '$cleared of $total stages'
        '${request.skippedStages > 0 ? ' (${request.skippedStages} skipped)' : ''}';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (_loading) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 10),
        ],
        if (_error != null) ...[
          _ErrorBanner(message: _error!, onRetry: _load),
          const SizedBox(height: 10),
        ],
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(request.id,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          color: AppTheme.textMuted)),
                  _CaseStatusChip(_caseStatusLabel(request.status)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$percent%',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark)),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Overall progress · $cleared of $total cleared',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < stageCount; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: _segmentColor(request, steps[i]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppTheme.border),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Info('Where am I?', whereAmI)),
                  Expanded(child: _Info('Cleared', clearedText)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Info('Checking now', checkingNow)),
                  Expanded(
                    child: _Info(
                      'Blocking you',
                      isOutstanding
                          ? (current!.note ?? 'Outstanding issue')
                          : 'Nothing',
                      valueColor: isOutstanding ? _red : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Info('Next step', nextStep),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Request details from the backend
        _InfoCard([
          _DetailRow('Last Working Day', formatLongDate(request.lastWorkingDay)),
          _DetailRow('Reason for Leaving', request.reason),
          if (request.remarks.trim().isNotEmpty)
            _DetailRow('Remarks', request.remarks),
          if (request.submittedAt != null)
            _DetailRow('Submitted', formatDateTime(request.submittedAt!)),
        ]),
        const SizedBox(height: 22),
        const Text('Clearance timeline',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark)),
        const SizedBox(height: 12),
        if (stageCount == 0)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('No stages have been created for this request yet.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
          ),
        for (var i = 0; i < stageCount; i++)
          _TimelineTile(
            step: steps[i],
            isLast: i == stageCount - 1,
            waitingFor: i == 0 || current == null || identical(current, steps[i])
                ? 'Waiting to start'
                : 'Waiting for ${current.department}',
          ),
        if (request.approvals.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text('Approvals',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const SizedBox(height: 12),
          _InfoCard([
            for (final a in request.approvals)
              _DetailRow(a.positionTitle, _approvalStatusLabel(a.status)),
          ]),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.infoBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD3DEF8)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 16, color: AppTheme.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Only the authorized departments and officials can clear '
                      'a stage. You cannot approve or clear anything from this '
                      'app.',
                  style: TextStyle(fontSize: 12, color: AppTheme.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 36, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(message,
              style: const TextStyle(color: _red, fontSize: 12.5)),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _CaseStatusChip extends StatelessWidget {
  final String label;
  const _CaseStatusChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE6EEFC),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> rows;
  const _InfoCard(this.rows);

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            const Divider(
                height: 1, thickness: 1, color: Color(0xFFF1F4F8)),
          rows[i],
        ],
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(fontSize: 12.5, color: AppTheme.textMuted)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark),
          ),
        ),
      ],
    ),
  );
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Info(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppTheme.textDark)),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final DepartmentStep step;
  final bool isLast;
  final String waitingFor;
  const _TimelineTile({
    required this.step,
    required this.isLast,
    required this.waitingFor,
  });

  (Color, Color, IconData) get _dot => switch (step.status) {
    StepStatus.cleared => (
    const Color(0xFFE5F5EA),
    const Color(0xFF16803C),
    Icons.check
    ),
    StepStatus.processing => (
    const Color(0xFFE6EEFC),
    AppTheme.primary,
    Icons.autorenew
    ),
    StepStatus.outstanding => (_red, Colors.white, Icons.priority_high),
    StepStatus.locked => (
    const Color(0xFFE9EDF3),
    const Color(0xFF64748B),
    Icons.lock_outline
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (dotBg, dotFg, dotIcon) = _dot;
    final locked = step.status == StepStatus.locked;
    final outstanding = step.status == StepStatus.outstanding;

    String subtitle;
    if (outstanding) {
      subtitle = step.note ?? 'Action required';
    } else if (locked) {
      subtitle = waitingFor;
    } else if (step.status == StepStatus.processing) {
      subtitle = 'Being reviewed';
    } else {
      subtitle = step.note ?? 'Cleared';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration:
                BoxDecoration(color: dotBg, shape: BoxShape.circle),
                child: Icon(dotIcon, size: 16, color: dotFg),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppTheme.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: locked ? const Color(0xFFF1F5F9) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: outstanding
                        ? const Color(0xFFF1B5B5)
                        : AppTheme.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.department,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: locked
                                ? AppTheme.textMuted
                                : AppTheme.textDark)),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StepStatusBadge(step.status),
                    ),
                    const SizedBox(height: 8),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppTheme.textMuted)),
                    if (outstanding) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _red,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showIssue(context),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward, size: 14),
                        label: const Text('View Issue',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Information only. The employee can never approve a department.
  void _showIssue(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${step.department} issue'),
        content: Text(
          step.note ??
              'There is an outstanding issue. Please contact the '
                  '${step.department} office to resolve it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}