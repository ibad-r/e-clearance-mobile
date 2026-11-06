import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/date_format.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_theme.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  /// Turns the backend status (for example IN_PROGRESS) into readable text.
  String _statusLabel(String status) {
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

  @override
  Widget build(BuildContext context) {
    final request = context.watch<AppState>().activeRequest;

    // The user cannot go back to the Review screen after submitting.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5F5EA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        size: 38, color: Color(0xFF16803C)),
                  ),
                  const SizedBox(height: 22),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 36),
                    child: Text(
                      'Request submitted successfully',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 36),
                    child: Text(
                      'Your clearance request has been recorded. You can '
                          'track its status at any time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Request Code',
                          child: Text(
                            request?.id ?? '—',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        const _Divider(),
                        _InfoRow(
                          label: 'Case ID',
                          child: Flexible(
                            child: Text(
                              request?.caseId ?? '—',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.5,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                        const _Divider(),
                        _InfoRow(
                          label: 'Status',
                          child: _StatusBadge(
                              _statusLabel(request?.status ?? '')),
                        ),
                        if (request?.submittedAt != null) ...[
                          const _Divider(),
                          _InfoRow(
                            label: 'Submitted',
                            child: Text(
                              formatDateTime(request!.submittedAt!),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.dashboard,
                          (route) => false,
                    ),
                    child: const Text(
                      'Go to Home',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.progress),
                  child: const Text(
                    'Track Clearance Progress',
                    style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F4F8));
}

class _InfoRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _InfoRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
          const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
        ),
        const SizedBox(width: 16),
        Flexible(child: child),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE6EEFC),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.autorenew, size: 12, color: AppTheme.primary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary),
        ),
      ],
    ),
  );
}