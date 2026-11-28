import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_state.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/step_status_badge.dart';
import '../../../models/clearance_request.dart';

class DepartmentIssueScreen extends StatefulWidget {
  const DepartmentIssueScreen({
    super.key,
    required this.caseId,
    required this.step,
  });

  final String caseId;
  final DepartmentStep step;

  @override
  State<DepartmentIssueScreen> createState() => _DepartmentIssueScreenState();
}

class _DepartmentIssueScreenState extends State<DepartmentIssueScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _refresh() async {
    final state = context.read<AppState>();
    if (_loading || state.activeRequest?.caseId != widget.caseId) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    String? error;
    try {
      await state.refreshActiveCase();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<AppState>().activeRequest;
    final step = request?.caseId == widget.caseId
        ? request!.steps
              .where((step) => step.stepOrder == widget.step.stepOrder)
              .firstOrNull
        : null;
    final issue = step == null ? null : request?.openIssueFor(step);

    return Scaffold(
      appBar: AppBar(title: const Text('Department Details')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(
              widget.step.department,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Text(_error!),
            if (step == null)
              const Text('This stage is unavailable.')
            else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: StepStatusBadge(step.status),
              ),
              if (step.status == StepStatus.outstanding) ...[
                const SizedBox(height: 24),
                Text('Issue', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  issue?.reason ??
                      step.note ??
                      'This stage needs your attention.',
                ),
                const SizedBox(height: 16),
                Text(
                  'How to resolve it',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('Contact ${step.department} for resolution instructions.'),
              ],
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loading || step == null ? null : _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
}
