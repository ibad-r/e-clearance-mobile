enum QuestionAnswer { yes, no, notSure }

extension QuestionAnswerLabels on QuestionAnswer {
  String get label => switch (this) {
    QuestionAnswer.yes => 'Yes',
    QuestionAnswer.no => 'No',
    QuestionAnswer.notSure => 'Not Sure',
  };

  // Display text only. These do not decide which departments apply.
  String get reviewLabel => switch (this) {
    QuestionAnswer.yes => 'Yes · Likely Applicable',
    QuestionAnswer.no => 'No · Reported Not Applicable',
    QuestionAnswer.notSure => 'Not Sure · Needs HR Verification',
  };
}

class DepartmentQuestion {
  const DepartmentQuestion(this.area, this.question);
  final String area;
  final String question;
}

/// Answers are stored by question index (0 to 13), in Figma order.
class QuestionnaireDraft {
  final Map<int, QuestionAnswer> _answers = {};

  QuestionAnswer? answerAt(int index) => _answers[index];
  void setAnswer(int index, QuestionAnswer a) => _answers[index] = a;
  int get answeredCount => _answers.length;
  int countOf(QuestionAnswer a) => _answers.values.where((v) => v == a).length;
  void clear() => _answers.clear();
}

/// Local mock request used only until the backend contract is ready.
class PendingHrRequest {
  const PendingHrRequest({
    required this.reference,
    required this.submittedAt,
    required this.lastWorkingDay,
    required this.likelyApplicable,
    required this.reportedNotApplicable,
    required this.needsVerification,
  });

  final String reference;
  final DateTime submittedAt;
  final DateTime lastWorkingDay;
  final int likelyApplicable;
  final int reportedNotApplicable;
  final int needsVerification;
}