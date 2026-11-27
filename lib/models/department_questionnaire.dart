enum QuestionAnswer { yes, no, notSure }

extension QuestionAnswerLabels on QuestionAnswer {
  String get label => switch (this) {
    QuestionAnswer.yes => 'Yes',
    QuestionAnswer.no => 'No',
    QuestionAnswer.notSure => 'Not Sure',
  };

  /// Exact literal sent to and received from the API.
  String get apiValue => switch (this) {
    QuestionAnswer.yes => 'YES',
    QuestionAnswer.no => 'NO',
    QuestionAnswer.notSure => 'NOT_SURE',
  };

  // Display text only. These do not decide which departments apply.
  String get reviewLabel => switch (this) {
    QuestionAnswer.yes => 'Yes · Likely Applicable',
    QuestionAnswer.no => 'No · Reported Not Applicable',
    QuestionAnswer.notSure => 'Not Sure · Needs HR Verification',
  };
}

/// Returns null for any value that is not exactly YES, NO or NOT_SURE.
QuestionAnswer? questionAnswerFromApi(String? raw) => switch (raw) {
  'YES' => QuestionAnswer.yes,
  'NO' => QuestionAnswer.no,
  'NOT_SURE' => QuestionAnswer.notSure,
  _ => null,
};

/// The 14 answer keys of the questionnaire v1 API contract, in the same
/// order as the Figma questions (kDepartmentQuestions).
const kQuestionnaireApiKeys = [
  'hdsDepartment',
  'financeDepartment',
  'feesAndDuesDepartment',
  'computerServicesDepartment',
  'operationsDepartment',
  'cmsRepresentative',
  'oric',
  'storeSection',
  'wardenHostel',
  'labInchargeOffice',
  'informationServicesDepartment',
  'wardInchargeNursingDivision',
  'pharmacy',
  'headOfDepartment',
];

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

  /// Builds the API answers. [keysInFigmaOrder] gives the API key for each
  /// question index. Returns null unless every question has an answer,
  /// so an unanswered question is never defaulted.
  Map<String, QuestionAnswer>? toApiAnswers(List<String> keysInFigmaOrder) {
    if (keysInFigmaOrder.length != kQuestionnaireApiKeys.length) return null;
    final result = <String, QuestionAnswer>{};
    for (var i = 0; i < keysInFigmaOrder.length; i++) {
      final a = _answers[i];
      if (a == null) return null;
      result[keysInFigmaOrder[i]] = a;
    }
    if (result.length != kQuestionnaireApiKeys.length) return null;
    return result;
  }
}

/// A request waiting for HR. Built either from the local mock (isMock true)
/// or from a real backend case with status PENDING_HR_VERIFICATION.
class PendingHrRequest {
  const PendingHrRequest({
    required this.reference,
    required this.submittedAt,
    required this.lastWorkingDay,
    required this.likelyApplicable,
    required this.reportedNotApplicable,
    required this.needsVerification,
    this.isMock = false,
  });

  final String reference;
  final DateTime submittedAt;
  final DateTime lastWorkingDay;
  final int likelyApplicable;
  final int reportedNotApplicable;
  final int needsVerification;

  /// True only for the local prototype mock.
  final bool isMock;
}