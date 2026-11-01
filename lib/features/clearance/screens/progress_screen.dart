import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/step_status_badge.dart';
import '../../../models/clearance_request.dart';

const _red = Color(0xFFC62828);

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

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
    if (request == null) {
      return const Scaffold(
        body: Center(child: Text('No active clearance')),
      );
    }

    final steps = request.steps;
    final total = steps.length;
    final current = request.currentStep;
    final percent = (request.progress * 100).round();
    final stageNo = current == null ? total : steps.indexOf(current) + 1;
    final isOutstanding = current?.status == StepStatus.outstanding;

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                    StepStatusBadge(request.overallStatus),
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
                        'Overall progress · ${request.clearedCount} of $total cleared',
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
                    for (var i = 0; i < total; i++) ...[
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
                    Expanded(
                      child: _Info(
                        'Where am I?',
                        current == null
                            ? 'All stages cleared'
                            : 'Stage $stageNo of $total · ${current.department}',
                      ),
                    ),
                    Expanded(
                      child: _Info(
                        'Cleared',
                        request.clearedCount == 0
                            ? 'Nothing yet'
                            : '${request.clearedCount} of $total stages',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Info(
                        'Checking now',
                        current == null
                            ? 'Nothing pending'
                            : isOutstanding
                            ? 'Paused at ${current.department}'
                            : current.department,
                      ),
                    ),
                    Expanded(
                      child: _Info(
                        'Blocking you',
                        isOutstanding
                            ? (current!.amountLabel == null
                            ? 'Outstanding issue'
                            : 'Dues of ${current.amountLabel}')
                            : 'Nothing',
                        valueColor: isOutstanding ? _red : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Info(
                  'Next step',
                  isOutstanding
                      ? 'Resolve the issue'
                      : current == null
                      ? 'Final approval'
                      : 'Wait for automatic check',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('Clearance timeline',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const SizedBox(height: 12),
          for (var i = 0; i < total; i++)
            _TimelineTile(
              step: steps[i],
              isLast: i == total - 1,
              waitingFor: i == total - 1
                  ? 'Waiting for earlier stages'
                  : 'Waiting for ${current?.department ?? 'earlier stages'}',
            ),
          const SizedBox(height: 4),
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
                    'Later stages stay locked until the current stage passes '
                        'its automatic check.',
                    style: TextStyle(fontSize: 12, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Not available in this demo')),
              ),
              child: const Text('View Clearance History',
                  style: TextStyle(fontSize: 12.5)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
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
            style:
            const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
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
      subtitle = step.amountLabel == null
          ? 'Action required'
          : 'Action required · ${step.amountLabel} due';
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(step.department,
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: locked
                                      ? AppTheme.textMuted
                                      : AppTheme.textDark)),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppTheme.textMuted),
                      ],
                    ),
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
          step.amountLabel == null
              ? 'There is an outstanding issue. Please contact the '
              'department to resolve it.'
              : 'There is an outstanding balance of ${step.amountLabel}. '
              'Please contact the ${step.department} office to resolve '
              'it. Your clearance continues after the department '
              'confirms.',
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
