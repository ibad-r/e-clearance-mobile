import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/date_format.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/step_status_badge.dart';
import '../../../models/clearance_request.dart';

const _red = Color(0xFFC62828);

class ActiveDashboardScreen extends StatelessWidget {
  const ActiveDashboardScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

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
    final emp = state.employee;
    final request = state.activeRequest;
    if (request == null) return const Scaffold(body: SizedBox.shrink());

    final current = request.currentStep;
    final total = request.steps.length;
    final percent = (request.progress * 100).round();
    final isOutstanding = current?.status == StepStatus.outstanding;
    final name = emp?.name ?? '';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                      Text(name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark)),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: emp?.id ?? '',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            TextSpan(text: ' · ${emp?.department ?? ''}'),
                          ],
                        ),
                        style: const TextStyle(
                            fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        request.id,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: AppTheme.textMuted),
                      ),
                      StepStatusBadge(request.overallStatus),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    current == null
                        ? 'All stages cleared'
                        : 'Current stage: ${current.department}',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${request.clearedCount} of $total stages cleared',
                        style: const TextStyle(
                            fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      // A small sliver is shown at 0%, like Figma.
                      value: request.progress == 0 ? 0.03 : request.progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEEF1F6),
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Last working day · ${formatLongDate(request.lastWorkingDay)}',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.progress),
                      child: const Text('View Progress',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            if (isOutstanding) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF5C6C6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.warning_amber_rounded,
                          size: 16, color: _red),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: current!.amountLabel == null
                                  ? '${current.department} has an outstanding issue. '
                                  : '${current.department} has an outstanding balance of ${current.amountLabel}. ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                            const TextSpan(
                              text: 'The workflow is paused and later stages '
                                  'are locked until this is resolved.',
                            ),
                          ],
                        ),
                        style: const TextStyle(
                            fontSize: 12.5, height: 1.45, color: _red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            const Text('Latest update',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isOutstanding
                          ? const Color(0xFFFDE8E8)
                          : const Color(0xFFE6EEFC),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOutstanding
                          ? Icons.warning_amber_rounded
                          : Icons.check,
                      size: 18,
                      color: isOutstanding ? _red : AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOutstanding
                              ? '${current!.department} outstanding issue recorded'
                              : 'Clearance request submitted',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          formatDateTime(request.submittedAt),
                          style: const TextStyle(
                              fontSize: 11.5, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}