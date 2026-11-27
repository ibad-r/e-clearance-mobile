import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/clearance/screens/dashboard_screen.dart';
import '../features/clearance/screens/new_clearance_screen.dart';
import '../features/clearance/screens/pending_hr_dashboard_screen.dart';
import '../features/clearance/screens/pending_hr_progress_screen.dart';
import '../features/clearance/screens/questionnaire_screen.dart';
import '../features/clearance/screens/review_screen.dart';
import '../features/clearance/screens/success_screen.dart';
import '../features/clearance/screens/progress_screen.dart';
import '../features/role_selection/role_selection_screen.dart';
import '../features/student/screens/student_access_denied_screen.dart';
import '../features/student/screens/student_login_screen.dart';
import '../features/student/screens/student_shell.dart';
import 'app_state.dart';

class AppRoutes {
  // Shared entry
  static const roleSelection = '/role-selection';

  // Employee
  static const login = '/';
  static const dashboard = '/dashboard';
  static const newClearance = '/clearance/new';
  static const questionnaire = '/clearance/questionnaire';
  static const review = '/clearance/review';
  static const success = '/clearance/success';
  static const activeDashboard = '/dashboard/active';
  static const progress = '/clearance/progress';

  // Student
  static const studentLogin = '/student/login';
  static const studentHome = '/student/home';
  static const studentAccessDenied = '/student/access-denied';

  static Map<String, WidgetBuilder> get table => {
    roleSelection: (_) => const RoleSelectionScreen(),
    login: (_) => const LoginScreen(),
    // While a request is waiting for HR (a real PENDING_HR_VERIFICATION case,
    // or the local mock), show the pending screens. Consumer re-checks on
    // every change, so the screen switches by itself once HR confirms.
    dashboard: (_) => Consumer<AppState>(
      builder: (_, state, _) => state.pendingHrRequest != null
          ? const PendingHrDashboardScreen()
          : const DashboardScreen(),
    ),
    newClearance: (_) => const NewClearanceScreen(),
    questionnaire: (_) => const QuestionnaireScreen(),
    review: (_) => const ReviewScreen(),
    success: (_) => const SuccessScreen(),
    progress: (_) => Consumer<AppState>(
      builder: (_, state, _) => state.pendingHrRequest != null
          ? const PendingHrProgressScreen()
          : const ProgressScreen(),
    ),
    studentLogin: (_) => const StudentLoginScreen(),
    studentHome: (_) => const StudentShell(),
    studentAccessDenied: (_) => const StudentAccessDeniedScreen(),
  };
}