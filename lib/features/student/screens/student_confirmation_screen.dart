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
    final submitted = result != null;
    const missing = 'Not available yet';

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
                              ? const Color(0xFFE6F4EA)
                              : AppTheme.infoBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          submitted ? Icons.check : Icons.info_outline,
                          size: 34,
                          color: submitted
                              ? const Color(0xFF15803D)
                              : AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        submitted
                            ? 'Request Submitted Successfully'
                            : 'Submission Not Connected Yet',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
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
                        style: const TextStyle(
                            fontSize: 12.5, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.border)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
              const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}