import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../state/student_state.dart';
import '../widgets/student_profile_notice.dart';

class StudentRequestScreen extends StatefulWidget {
  const StudentRequestScreen({super.key, required this.onReview});

  final VoidCallback onReview;

  @override
  State<StudentRequestScreen> createState() => _StudentRequestScreenState();
}

class _StudentRequestScreenState extends State<StudentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final StudentRequestDraft _draft;
  bool _reasonMissing = false;
  bool _showBanner = false;
  StudentSubmission? _seenSubmission;

  @override
  void initState() {
    super.initState();
    _draft = context.read<StudentState>().draft;
  }

  /// Resets the request reason after a request was submitted successfully.
  void _resetForm() {
    _draft.clear();
    _formKey.currentState?.reset();
    setState(() {
      _reasonMissing = false;
      _showBanner = false;
    });
  }

  void _review() {
    FocusScope.of(context).unfocus();
    final fieldsOk = context.read<StudentState>().hasVerifiedProfile;
    final reasonOk = _draft.reason != null;
    setState(() {
      _reasonMissing = !reasonOk;
      _showBanner = !fieldsOk || !reasonOk;
    });
    if (!fieldsOk || !reasonOk) return;
    widget.onReview();
  }

  void _pickReason(ClearanceReason r) {
    setState(() {
      _draft.reason = r;
      _reasonMissing = false; // error disappears as soon as a reason is chosen
      if (_showBanner) _showBanner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentState>();
    final profile = state.profile;
    final cs = Theme.of(context).colorScheme;

    // A new submission result resets the request reason.
    if (!identical(state.lastSubmission, _seenSubmission)) {
      _seenSubmission = state.lastSubmission;
      if (_seenSubmission != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resetForm();
        });
      }
    }

    final hasActive = state.hasActiveRequest;

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
              'Clearance Request',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          Expanded(
            child: hasActive
                ? const _ActiveRequestNotice()
                : SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _bar(context, true)),
                              const SizedBox(width: 6),
                              Expanded(child: _bar(context, false)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Step 1 of 2 · Based on the official Student '
                            'University Clearance Form.',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          if (_showBanner) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cs.error),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 18,
                                    color: cs.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Please fix the highlighted fields to '
                                      'continue.',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: cs.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          const StudentProfileNotice(),
                          const _SectionTitle('STUDENT INFORMATION'),
                          const _Label('SAP ID'),
                          _LockedField(value: profile?.sapId),
                          const SizedBox(height: 14),
                          const _Label('Student Name'),
                          _LockedField(value: profile?.name),
                          const SizedBox(height: 14),
                          const _Label('Registration Number'),
                          _LockedField(value: profile?.registrationNumber),
                          const SizedBox(height: 14),
                          const _Label("Father's Name"),
                          _LockedField(value: profile?.fatherName),
                          const SizedBox(height: 22),
                          const _SectionTitle('ACADEMIC DETAILS'),
                          const _Label('Program'),
                          _LockedField(value: profile?.program),
                          const SizedBox(height: 14),
                          const _Label('Semester'),
                          _LockedField(value: profile?.semester),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Student details come from your verified university profile.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const _SectionTitle('CLEARANCE REASON'),
                          _ReasonCard(
                            title: 'Degree Completed',
                            subtitle:
                                'I have completed all requirements of my degree.',
                            selected:
                                _draft.reason ==
                                ClearanceReason.degreeCompleted,
                            onTap: () =>
                                _pickReason(ClearanceReason.degreeCompleted),
                          ),
                          const SizedBox(height: 10),
                          _ReasonCard(
                            title: 'Discontinuing Studies',
                            subtitle:
                                'I am leaving my program before completing it.',
                            selected:
                                _draft.reason ==
                                ClearanceReason.discontinuingStudies,
                            onTap: () => _pickReason(
                              ClearanceReason.discontinuingStudies,
                            ),
                          ),
                          if (_reasonMissing)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Select a clearance reason.',
                                style: TextStyle(fontSize: 12, color: cs.error),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          if (!hasActive)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.hasVerifiedProfile ? _review : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Review Request',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, bool active) => Container(
    height: 4,
    decoration: BoxDecoration(
      color: active
          ? AppTheme.primary
          : Theme.of(context).colorScheme.outlineVariant,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

/// Shown instead of the form when an active request already exists.
class _ActiveRequestNotice extends StatelessWidget {
  const _ActiveRequestNotice();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 44,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text(
              'You already have an active request',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Only one clearance request can be active at a time. '
              'Follow its progress on the Dashboard or Status tab.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

class _LockedField extends StatelessWidget {
  const _LockedField({this.value});
  final String? value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasValue = value != null && value!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasValue ? value! : 'Not available yet',
              style: TextStyle(
                fontSize: 14,
                color: hasValue ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppTheme.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
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
