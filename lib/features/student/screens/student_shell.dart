import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../data/student_repository.dart';
import '../state/student_state.dart';
import 'student_dashboard_screen.dart';
import 'student_details_screen.dart';
import 'student_history_screen.dart';
import 'student_profile_screen.dart';
import 'student_request_screen.dart';
import 'student_review_screen.dart';
import 'student_status_screen.dart';

/// Student area with bottom navigation.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell>
    with WidgetsBindingObserver {
  late final StudentState _state;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Reuses the shared ApiClient (and its token) from AppState.
    final app = context.read<AppState>();
    _state = StudentState(
      repository: StudentRepository(app.apiClient),
      email: app.studentUser?.email,
    );
    unawaited(_state.loadProfile());
    unawaited(_state.refreshDashboard());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.dispose();
    super.dispose();
  }

  /// Reload the saved results when the app returns to the foreground.
  /// A normal GET. It never triggers a check.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      unawaited(_state.refreshDashboard(quiet: true));
    }
  }

  /// Switches tab. Opening the Dashboard or Status tab reloads saved results.
  void _goTo(int i) {
    setState(() => _index = i);
    if (i == 0 || i == 2) {
      unawaited(_state.refreshDashboard(quiet: true));
    }
  }

  void _push(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<StudentState>.value(
          value: _state,
          child: screen,
        ),
      ),
    );
  }

  void _openReview() {
    _push(StudentReviewScreen(onGoToTab: _goTo));
  }

  void _openDetails() => _push(const StudentDetailsScreen());

  void _openHistory() => _push(const StudentHistoryScreen());

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentState>.value(
      value: _state,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            StudentDashboardScreen(
              onNewRequest: () => _goTo(1),
              onViewStatus: () => _goTo(2),
              onViewHistory: _openHistory,
            ),
            StudentRequestScreen(onReview: _openReview),
            StudentStatusScreen(onViewDetails: _openDetails),
            const StudentProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goTo,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.note_add_outlined),
              label: 'Request',
            ),
            NavigationDestination(icon: Icon(Icons.checklist), label: 'Status'),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}