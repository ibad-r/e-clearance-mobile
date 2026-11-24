import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/pending_hr_chip.dart';

/// Clearance Progress while the (mock) request is waiting for HR.
/// No department stages, no sequential progress, no simulated HR actions.
/// The existing ProgressScreen is kept for the later HR-confirmed workflow.
class PendingHrProgressScreen extends StatelessWidget {
  const PendingHrProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<AppState>().pendingHrRequest;
    if (request == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Clearance Progress',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        request.reference,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const PendingHrChip(),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3E0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hourglass_top_rounded,
                          size: 22, color: Color(0xFFB45309)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HR Verification Pending',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark)),
                          SizedBox(height: 4),
                          Text(
                            'HR is reviewing which departments apply to you. '
                                'Department clearance has not started, and no '
                                'department is required yet.',
                            style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('Request status',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(
              children: [
                _StatusLine(
                  icon: Icons.check,
                  color: Color(0xFF16803C),
                  text: 'Request submitted',
                ),
                _StatusLine(
                  icon: Icons.timer_outlined,
                  color: AppTheme.primary,
                  text: 'HR verification of department applicability · '
                      'in progress',
                ),
                _StatusLine(
                  icon: Icons.lock_outline,
                  color: AppTheme.textMuted,
                  text: 'Department clearance · starts after HR confirms',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('Your preliminary answers',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _CountRow('Likely Applicable', request.likelyApplicable),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFF1F4F8)),
                _CountRow(
                    'Reported Not Applicable', request.reportedNotApplicable),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFF1F4F8)),
                _CountRow('Needs HR Verification', request.needsVerification),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Preliminary employee responses, not final department decisions.',
            style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine(
      {required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: AppTheme.textDark)),
        ),
      ],
    ),
  );
}

class _CountRow extends StatelessWidget {
  const _CountRow(this.label, this.count);
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5, color: AppTheme.textMuted)),
        Text('$count',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark)),
      ],
    ),
  );
}