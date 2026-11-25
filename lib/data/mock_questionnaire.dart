import '../models/department_questionnaire.dart';

/// true  = Review & Submit uses the local mock (this sprint).
/// false = Review & Submit uses the real API submit (later sprint).
const bool kMockQuestionnaireSubmit = true;

/// Mock reference for the prototype only.
const String kMockRequestReference = 'ECLR-2026-0042';

// Wording and order copied from the Figma prototype (draft content).
const List<DepartmentQuestion> kDepartmentQuestions = [
  DepartmentQuestion('HDS Department',
      'Do you have any pending responsibility, record, or assigned item with HDS?'),
  DepartmentQuestion('Finance Department',
      'Do you have any pending financial dues, advances, reimbursements, or financial responsibilities?'),
  DepartmentQuestion('Fees and Dues Department',
      'Do you have any outstanding university dues or fee-related obligations?'),
  DepartmentQuestion('Computer Services Department',
      'Have you been issued university IT equipment, a laptop, computer, or other technology assets?'),
  DepartmentQuestion('Operations Department',
      'Have you been assigned any university facility, access, or operational responsibility?'),
  DepartmentQuestion('CMS Representative',
      'Do you have any official CMS account, records, or pending CMS-related responsibilities?'),
  DepartmentQuestion('ORIC',
      'Are you involved in any university research project, grant, or ORIC-related responsibility?'),
  DepartmentQuestion('Store Section',
      'Have you received any university assets, equipment, or items from the Store Section?'),
  DepartmentQuestion('Warden / Hostel',
      'Have you been assigned university hostel or accommodation facilities?'),
  DepartmentQuestion('Lab In-charge / Office',
      'Do you have any laboratory equipment, office assets, or lab-related responsibilities assigned to you?'),
  DepartmentQuestion('Information Services Department',
      'Do you have any library-issued books, resources, or other Information Services responsibilities?'),
  DepartmentQuestion('Ward In-charge / Nursing Division',
      'Do you have any assigned ward, nursing, or related university facility responsibilities?'),
  DepartmentQuestion('Pharmacy',
      'Have you received any university pharmacy items or do you have any pharmacy-related pending responsibility?'),
  DepartmentQuestion('Head of Department (HOD)',
      'Do you have any pending departmental responsibilities, records, or handover obligations?'),
];