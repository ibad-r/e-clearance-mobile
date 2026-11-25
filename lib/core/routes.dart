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
    // While a mock request is waiting for HR, show the pending screens.
    // Otherwise the existing real screens are used, unchanged.
    dashboard: (ctx) => ctx.read<AppState>().pendingHrRequest != null
        ? const PendingHrDashboardScreen()
        : const DashboardScreen(),
    newClearance: (_) => const NewClearanceScreen(),
    questionnaire: (_) => const QuestionnaireScreen(),
    review: (_) => const ReviewScreen(),
    success: (_) => const SuccessScreen(),
    progress: (ctx) => ctx.read<AppState>().pendingHrRequest != null
        ? const PendingHrProgressScreen()
        : const ProgressScreen(),
    studentLogin: (_) => const StudentLoginScreen(),
    studentHome: (_) => const StudentShell(),
    studentAccessDenied: (_) => const StudentAccessDeniedScreen(),
  };
}