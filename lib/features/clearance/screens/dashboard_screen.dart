import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import 'active_dashboard_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _initials(String name) {
    final parts =
    name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // After submitting, the dashboard switches to the active view.
    if (state.hasActiveRequest) {
      return const ActiveDashboardScreen();
    }

    final emp = state.employee;
    final name = emp?.name ?? '';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Good morning,',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                      Text(name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark)),
                      Text('${emp?.id ?? ''} · ${emp?.department ?? ''}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _whiteCard(
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.hourglass_empty,
                        size: 18, color: AppTheme.textMuted),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No active clearance',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppTheme.textDark)),
                        Text('You have not started a clearance request.',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LEAVING THE UNIVERSITY?',
                      style: TextStyle(
                          color: Color(0xFFD3DEF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  const Text('Start your clearance in under 2 minutes',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.2,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                      'Your details are pre-filled. Departments are checked '
                          'automatically for you.',
                      style: TextStyle(
                          color: Color(0xFFE3EAFB), fontSize: 12, height: 1.4)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pushNamed(
                          context, AppRoutes.newClearance),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Start Clearance',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('How it works',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppTheme.textDark)),
            const SizedBox(height: 10),
            _whiteCard(
              child: const Column(
                children: [
                  _Step(1, 'Submit one online request'),
                  _Step(2,
                      'Departments are checked automatically, one at a time'),
                  _Step(3, 'Resolve any outstanding issue'),
                  _Step(4, 'Final approval, then your digital certificate'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  static Widget _whiteCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F0F172A), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String text;
  const _Step(this.n, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: AppTheme.infoBg,
            child: Text('$n',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, color: AppTheme.textDark)),
          ),
        ],
      ),
    );
  }
}