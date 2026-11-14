import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../state/student_state.dart';
import 'student_confirmation_screen.dart';

class StudentReviewScreen extends StatefulWidget {
  const StudentReviewScreen({super.key, required this.onGoToTab});

  /// Switches the Student bottom-navigation tab after leaving this flow.
  final void Function(int) onGoToTab;

  @override
  State<StudentReviewScreen> createState() => _StudentReviewScreenState();
}

class _StudentReviewScreenState extends State<StudentReviewScreen> {
  bool _submitting = false;

  void _confirmAndSubmit(BuildContext context) {
    if (_submitting) return; // ignore repeated taps
    setState(() => _submitting = true);

    // TODO(student-api): send the request to the server here once Ibad shares
    // the agreed contract. Nothing is sent yet, and no result is faked.
    // Phase 2: await POST /student/requests, and set _submitting = false on error.
    final state = context.read<StudentState>();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<StudentState>.value(
          value: state,
          child: StudentConfirmationScreen(onGoToTab: widget.onGoToTab),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentState>();
    final cs = Theme.of(context).colorScheme;
    final draft = state.draft;
    final profile = state.profile;
    const missing = 'Not available yet';

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
                    tooltip: 'Back to request form',
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Review Request',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _bar()),
                        const SizedBox(width: 6),
                        Expanded(child: _bar()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Step 2 of 2 · Please confirm your details.',
                      style:
                      TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle('STUDENT DETAILS'),
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          _Row('Student Name', profile?.name ?? missing),
                          _Row('SAP ID', profile?.sapId ?? missing),
                          _Row('Registration Number',
                              draft.registrationNumber),
                          _Row("Father's Name", draft.fatherName),
                          _Row('Program', draft.program),
                          _Row('Semester', draft.semester, last: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('CLEARANCE REASON'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            draft.reason?.label ?? '—',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: cs.onPrimaryContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "After you submit, each department's status "
                                  'will appear on the Clearance Status screen. '
                                  'Processing rules are confirmed separately.',
                              style: TextStyle(
                                  fontSize: 12, color: cs.onPrimaryContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      onPressed:
                      _submitting ? null : () => _confirmAndSubmit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Confirm and Submit',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  TextButton(
                    onPressed:
                    _submitting ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Edit Information',
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

  Widget _bar() => Container(
    height: 4,
    decoration: BoxDecoration(
      color: AppTheme.primary,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.last = false});
  final String label;
  final String value;
  final bool last;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}