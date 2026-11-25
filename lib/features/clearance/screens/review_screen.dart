import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/date_format.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../../../data/mock_questionnaire.dart';
import '../../../models/department_questionnaire.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _confirmed = false;
  bool _submitting = false;

  Future<void> _submit() async {
    // Blocks a second tap while the first request is still running.
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final state = context.read<AppState>();
      if (kMockQuestionnaireSubmit) {
        // This sprint: local mock only, no network call.
        await state.submitForHrReview();
      } else {
        // Later sprint: real API submit (existing code path).
        await state.submit();
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.success,
        ModalRoute.withName(AppRoutes.dashboard),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showError('Could not submit your request. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final emp = state.employee;
    final draft = state.draft;
    final answers = state.questionnaire;
    final lastDay = draft.lastWorkingDay;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleSpacing: 8,
        iconTheme: const IconThemeData(color: AppTheme.textDark, size: 22),
        title: const Text(
          'Review & Submit',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StepProgressBar(step: 3),
            const SizedBox(height: 12),
            const Text(
              'Step 3 of 3 · Please confirm your details.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            const _Section('PRE-FILLED FROM YOUR EMPLOYEE RECORD'),
            _InfoCard([
              _DetailRow('Employee Number', emp?.id ?? ''),
              _DetailRow('Name', emp?.name ?? ''),
              _DetailRow('Designation', emp?.designation ?? ''),
              _DetailRow('Department', emp?.department ?? ''),
            ]),
            const SizedBox(height: 20),
            const _Section('PROVIDED BY YOU'),
            _InfoCard([
              _DetailRow('Last Working Day',
                  lastDay == null ? 'Not provided' : formatLongDate(lastDay)),
              _DetailRow(
                  'Reason for Leaving', _valueOr(draft.reason, 'Not provided')),
              if (draft.phone.isNotEmpty)
                _DetailRow('Contact Number', draft.phone),
              if (draft.forwardingAddress.isNotEmpty)
                _DetailRow('Forwarding Address', draft.forwardingAddress),
              _DetailRow('Remarks', _valueOr(draft.remarks, 'None')),
            ]),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: _Section('DEPARTMENT APPLICABILITY ANSWERS'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  // Goes back to the questionnaire; answers are kept.
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: const Text('Edit answers',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary)),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < kDepartmentQuestions.length; i++) ...[
                    if (i > 0)
                      const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF1F4F8)),
                    _AnswerRow(
                      area: kDepartmentQuestions[i].area,
                      answer: answers.answerAt(i),
                    ),
                  ],
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Preliminary employee responses, not final department '
                    'decisions.',
                style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _submitting
                  ? null
                  : () => setState(() => _confirmed = !_confirmed),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _confirmed,
                        activeColor: AppTheme.primary,
                        side: const BorderSide(
                            color: Color(0xFF94A3B8), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                        onChanged: _submitting
                            ? null
                            : (v) => setState(() => _confirmed = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'I confirm that the information and department-related '
                            'answers provided above are accurate to the best of my '
                            'knowledge.',
                        style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppTheme.textDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor: const Color(0xFFA3B6EE),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _confirmed && !_submitting ? _submit : null,
                    child: _submitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Submit Clearance',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
                TextButton(
                  // Back to the details form (Step 1).
                  onPressed: _submitting
                      ? null
                      : () => Navigator.popUntil(
                      context, ModalRoute.withName(AppRoutes.newClearance)),
                  child: const Text(
                    'Edit request details',
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
    );
  }
}

// Shows a fallback when a value is empty.
String _valueOr(Object? value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppTheme.textMuted,
      ),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final List<_DetailRow> rows;
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
        Text(
          label,
          style:
          const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
        ),
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

class _AnswerRow extends StatelessWidget {
  final String area;
  final QuestionAnswer? answer;
  const _AnswerRow({required this.area, required this.answer});

  // Display styling only. Does not decide which departments apply.
  (Color, Color) get _colors => switch (answer) {
    QuestionAnswer.yes => (AppTheme.infoBg, AppTheme.primary),
    QuestionAnswer.notSure =>
    (const Color(0xFFFFF3E0), const Color(0xFFB45309)),
    _ => (const Color(0xFFF1F4F8), AppTheme.textMuted),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(area,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textDark)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              answer?.reviewLabel ?? 'Not answered',
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w600, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}