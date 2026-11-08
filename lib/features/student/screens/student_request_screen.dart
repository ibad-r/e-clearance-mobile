import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../state/student_state.dart';

class StudentRequestScreen extends StatefulWidget {
  const StudentRequestScreen({super.key, required this.onReview});

  final VoidCallback onReview;

  @override
  State<StudentRequestScreen> createState() => _StudentRequestScreenState();
}

class _StudentRequestScreenState extends State<StudentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final StudentRequestDraft _draft;
  late final TextEditingController _regCtrl;
  late final TextEditingController _fatherCtrl;
  late final TextEditingController _programCtrl;
  late final TextEditingController _semesterCtrl;
  bool _reasonMissing = false;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _draft = context.read<StudentState>().draft;
    _regCtrl = TextEditingController(text: _draft.registrationNumber);
    _fatherCtrl = TextEditingController(text: _draft.fatherName);
    _programCtrl = TextEditingController(text: _draft.program);
    _semesterCtrl = TextEditingController(text: _draft.semester);
  }

  @override
  void dispose() {
    _regCtrl.dispose();
    _fatherCtrl.dispose();
    _programCtrl.dispose();
    _semesterCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v, String message) {
    if (v == null || v.trim().isEmpty) return message;
    return null;
  }

  void _review() {
    FocusScope.of(context).unfocus();
    final fieldsOk = _formKey.currentState!.validate();
    final reasonOk = _draft.reason != null;
    setState(() {
      _reasonMissing = !reasonOk;
      _showBanner = !fieldsOk || !reasonOk;
    });
    if (!fieldsOk || !reasonOk) return;
    widget.onReview();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<StudentState>().profile;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: const Text(
              'Clearance Request',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _bar(true)),
                        const SizedBox(width: 6),
                        Expanded(child: _bar(false)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Step 1 of 2 · Based on the official Student '
                          'University Clearance Form.',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                    if (_showBanner) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border:
                          Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 18, color: AppTheme.danger),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please fix the highlighted fields to '
                                    'continue.',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.danger),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const _SectionTitle('STUDENT INFORMATION'),
                    const _Label('SAP ID'),
                    _LockedField(value: profile?.sapId),
                    const SizedBox(height: 14),
                    const _Label('Student Name'),
                    _LockedField(value: profile?.name),
                    const SizedBox(height: 14),
                    const _Label('Registration Number'),
                    TextFormField(
                      controller: _regCtrl,
                      textInputAction: TextInputAction.next,
                      onChanged: (v) => _draft.registrationNumber = v,
                      validator: (v) => _required(
                          v, 'Registration number is required.'),
                      decoration: const InputDecoration(
                          hintText: 'e.g. RIU-2022-CS-0000'),
                    ),
                    const SizedBox(height: 14),
                    const _Label("Father's Name"),
                    TextFormField(
                      controller: _fatherCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (v) => _draft.fatherName = v,
                      validator: (v) =>
                          _required(v, "Father's name is required."),
                      decoration: const InputDecoration(
                          hintText: 'As on your official records'),
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle('ACADEMIC DETAILS'),
                    const _Label('Program'),
                    TextFormField(
                      controller: _programCtrl,
                      textInputAction: TextInputAction.next,
                      onChanged: (v) => _draft.program = v,
                      validator: (v) =>
                          _required(v, 'Program is required.'),
                      decoration: const InputDecoration(
                          hintText: 'e.g. BS Computer Science'),
                    ),
                    const SizedBox(height: 14),
                    const _Label('Semester'),
                    TextFormField(
                      controller: _semesterCtrl,
                      textInputAction: TextInputAction.done,
                      onChanged: (v) => _draft.semester = v,
                      validator: (v) =>
                          _required(v, 'Semester is required.'),
                      decoration: const InputDecoration(hintText: 'e.g. 8th'),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Your current or final semester.',
                        style: TextStyle(
                            fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle('CLEARANCE REASON'),
                    _ReasonCard(
                      title: 'Degree Completed',
                      subtitle:
                      'I have completed all requirements of my degree.',
                      selected:
                      _draft.reason == ClearanceReason.degreeCompleted,
                      onTap: () => setState(() {
                        _draft.reason = ClearanceReason.degreeCompleted;
                        _reasonMissing = false;
                      }),
                    ),
                    const SizedBox(height: 10),
                    _ReasonCard(
                      title: 'Discontinuing Studies',
                      subtitle:
                      'I am leaving my program before completing it.',
                      selected: _draft.reason ==
                          ClearanceReason.discontinuingStudies,
                      onTap: () => setState(() {
                        _draft.reason = ClearanceReason.discontinuingStudies;
                        _reasonMissing = false;
                      }),
                    ),
                    if (_reasonMissing)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Select a clearance reason.',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.danger),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _review,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Review Request',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(bool active) => Container(
    height: 4,
    decoration: BoxDecoration(
      color: active ? AppTheme.primary : AppTheme.border,
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
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppTheme.textMuted,
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
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    ),
  );
}

class _LockedField extends StatelessWidget {
  const _LockedField({this.value});
  final String? value;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Text(
            hasValue ? value! : 'Not available yet',
            style: TextStyle(
              fontSize: 14,
              color: hasValue ? AppTheme.textDark : AppTheme.textMuted,
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
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.infoBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
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
              color: selected ? AppTheme.primary : AppTheme.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}