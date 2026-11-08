import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/routes.dart';
import 'student_login_screen.dart';

/// Wraps the login screen. In debug builds only, it adds a shortcut to the
/// Student screens because real Student login is not connected yet.
/// Remove this wrapper when the Student auth API is integrated.
class StudentLoginEntry extends StatelessWidget {
  const StudentLoginEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: StudentLoginScreen()),
        if (kDebugMode)
          Positioned(
            top: 0,
            right: 8,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.studentHome),
                  child: const Text(
                    'Preview (debug)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}