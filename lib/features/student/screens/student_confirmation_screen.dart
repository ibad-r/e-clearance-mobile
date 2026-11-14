import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../state/student_state.dart';

class StudentConfirmationScreen extends StatelessWidget {
  const StudentConfirmationScreen({super.key, required this.onGoToTab});

  /// Switches the Student bottom-navigation tab after closing this screen.
  final void Function(int) onGoToTab;

  void _leave(BuildContext context, int tab) {
    Navigator.pop(context);
    onGoToTab(tab);
  }

  @override
  Widget build(BuildContext context) {
    // Real values come from the server once the Student API is integrated.
    final result = context.watch<StudentState>().lastSubmission;
    final cs = Theme.of(context).colorScheme;
    final submitted = result != null;
    const missing = 'Not available yet';
    const green = Color(0xFF16A34A);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: submitted
                              ? green.withValues(alpha: 0.15)
                              : cs.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          submitted ? Icons.check : Icons.info_outline,
                          size: 34,
                          color: submitted ? green : AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        submitted
                            ? 'Request Submitted Successfully'
                            : 'Submission Not Connected Yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        submitted
                            ? 'Your clearance request has been received. '
                            'Track each department on the status screen.'
                            : 'Your details were reviewed, but submitting '
                            'to the server is not available yet. '
                            'No request has been sent.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12.5, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Column(
                          children: [
                            _InfoRow(
                              'Reference No.',
                              result?.referenceNumber ?? missing,
                              mono: submitted,
                            ),
                            _InfoRow(
                              'Submitted on',
                              result?.submittedOn ?? missing,
                            ),
                            _InfoRow(
                              'Status',
                              result?.status ?? 'Not submitted',
                              last: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _leave(context, 2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('View Clearance Status',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _leave(context, 0),
                    child: const Text(
                      'Back to Dashboard',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value,
      {this.last = false, this.mono = false});
  final String label;
  final String value;
  final bool last;
  final bool mono;

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}