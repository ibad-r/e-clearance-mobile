import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/student_state.dart';
import 'student_dashboard_screen.dart';

/// Student area with bottom navigation. Only the Dashboard tab is built so
/// far; the other tabs are placeholders until their screens are added.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentState>(
      create: (_) => StudentState(),
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            StudentDashboardScreen(
              onNewRequest: () => setState(() => _index = 1),
              onViewStatus: () => setState(() => _index = 2),
            ),
            const _ComingNext('New Clearance Request'),
            const _ComingNext('Clearance Status'),
            const _ComingNext('Student Profile'),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined), label: 'Dashboard'),
            NavigationDestination(
                icon: Icon(Icons.note_add_outlined), label: 'Request'),
            NavigationDestination(
                icon: Icon(Icons.checklist), label: 'Status'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _ComingNext extends StatelessWidget {
  const _ComingNext(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Center(child: Text('$title (coming next)')));
  }
}