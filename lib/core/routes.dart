import 'package:flutter/material.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/clearance/screens/dashboard_screen.dart';
import '../features/clearance/screens/new_clearance_screen.dart';
import '../features/clearance/screens/review_screen.dart';

class AppRoutes {
  static const login = '/';
  static const dashboard = '/dashboard';
  static const newClearance = '/clearance/new';
  static const review = '/clearance/review';
  static const success = '/clearance/success';
  static const activeDashboard = '/dashboard/active';
  static const progress = '/clearance/progress';

  static Map<String, WidgetBuilder> get table => {
    login: (_) => const LoginScreen(),
    dashboard: (_) => const DashboardScreen(),
    newClearance: (_) => const NewClearanceScreen(),
    review: (_) => const ReviewScreen(),
    // Temporary page. We replace it when we build m05.
    success: (_) => const Scaffold(
      body: Center(child: Text('m05 coming next')),
    ),
  };
}