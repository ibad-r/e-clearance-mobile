import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/student_state.dart';

/// Shared profile feedback for the dashboard, request form and settings.
class StudentProfileNotice extends StatelessWidget {
  const StudentProfileNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentState>();
    if (state.hasVerifiedProfile) return const SizedBox.shrink();
    final loading = state.profileLoad == LoadState.loading;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (loading)
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Expanded(child: Text('Loading student profile…')),
              ],
            )
          else ...[
            Text(
              state.profileError ??
                  'Student profile is unavailable. Reload to try again.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton.icon(
              onPressed: state.loadProfile,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry profile'),
            ),
          ],
        ],
      ),
    );
  }
}
