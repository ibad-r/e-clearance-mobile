import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/step_progress_bar.dart';
import '../../../data/mock_questionnaire.dart';
import '../../../models/department_questionnaire.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final _scroll = ScrollController();
  bool _showErrors = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _continue() {
    final q = context.read<AppState>().questionnaire;
    if (q.answeredCount < kDepartmentQuestions.length) {
      setState(() => _showErrors = true);
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      return;
    }
    Navigator.pushNamed(context, AppRoutes.review);
  }

  @override
  Widget build(BuildContext context) {
    final q = context.read<AppState>().questionnaire;
    final total = kDepartmentQuestions.length;
    final unanswered = total - q.answeredCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleSpacing: 8,
        iconTheme: const IconThemeData(color: AppTheme.textDark, size: 22),
        title: const Text(
          'Department Applicability',
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
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StepProgressBar(step: 2),
            const SizedBox(height: 14),
            const Text('Step 2 of 3',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark)),
            const SizedBox(height: 4),
            const Text(
              'Please answer the following questions about your university '
                  'responsibilities and facilities. Your answers will help HR '
                  'identify which departments may need to provide clearance.',
              style: TextStyle(
                  fontSize: 12.5, height: 1.4, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${q.answeredCount} of $total answered',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted)),
                const Text('Preliminary answers only',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted)),
              ],
            ),
            const SizedBox(height: 12),
            if (_showErrors && unanswered > 0) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF5C6C6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppTheme.danger),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please answer all $total questions to continue. '
                            '${unanswered == 1 ? '1 question is' : '$unanswered questions are'} '
                            'still unanswered.',
                        style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppTheme.danger),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            for (var i = 0; i < total; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuestionCard(
                  index: i,
                  total: total,
                  question: kDepartmentQuestions[i],
                  answer: q.answerAt(i),
                  showError: _showErrors && q.answerAt(i) == null,
                  onChanged: (a) => setState(() => q.setAnswer(i, a)),
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Questions are draft content for this prototype and are not '
                    'official HR policy. Your answers do not decide which '
                    'departments clear you.',
                style: TextStyle(
                    fontSize: 11.5, height: 1.4, color: AppTheme.textMuted),
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.textDark,
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _continue,
                      child: const Text('Continue',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.total,
    required this.question,
    required this.answer,
    required this.showError,
    required this.onChanged,
  });

  final int index;
  final int total;
  final DepartmentQuestion question;
  final QuestionAnswer? answer;
  final bool showError;
  final ValueChanged<QuestionAnswer> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: showError ? AppTheme.danger : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${index + 1} OF $total',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          Text(question.area,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const SizedBox(height: 4),
          Text(question.question,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.4, color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final a in QuestionAnswer.values) ...[
                if (a != QuestionAnswer.values.first) const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor:
                        answer == a ? AppTheme.infoBg : Colors.white,
                        foregroundColor:
                        answer == a ? AppTheme.primary : AppTheme.textDark,
                        side: BorderSide(
                          color:
                          answer == a ? AppTheme.primary : AppTheme.border,
                          width: answer == a ? 1.5 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => onChanged(a),
                      child: Text(a.label,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (showError) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppTheme.danger),
                SizedBox(width: 6),
                Text('Select an answer.',
                    style: TextStyle(fontSize: 12, color: AppTheme.danger)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}