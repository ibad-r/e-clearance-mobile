import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../state/student_state.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  static const _missing = 'Not available yet';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  void _goToRoleSelection(BuildContext context) {
    // TODO(student-api): clear the Student session here once Student login
    // is integrated. There is no Student session yet.
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
          (route) => false,
    );
  }

  void _changePassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change Password is not available yet.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudentState>();
    final theme = context.watch<ThemeController>();
    final cs = Theme.of(context).colorScheme;
    final p = state.profile;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Text(
              'Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            p == null ? '?' : _initials(p.name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          p?.name ?? 'Student',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p == null
                              ? 'Profile details not available yet'
                              : '${p.program} · Student',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _Card(
                    children: [
                      _InfoRow('SAP ID', p?.sapId ?? _missing),
                      _InfoRow('Registration No.',
                          p?.registrationNumber ?? _missing),
                      _InfoRow('Email', p?.email ?? _missing),
                      _InfoRow('Program', p?.program ?? _missing, last: true),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Appearance'),
                  _Card(
                    padding: const EdgeInsets.all(6),
                    children: [
                      _AppearanceOption(
                        icon: Icons.light_mode_outlined,
                        label: 'Light',
                        selected: theme.mode == ThemeMode.light,
                        onTap: () => theme.setMode(ThemeMode.light),
                      ),
                      _AppearanceOption(
                        icon: Icons.dark_mode_outlined,
                        label: 'Dark',
                        selected: theme.mode == ThemeMode.dark,
                        onTap: () => theme.setMode(ThemeMode.dark),
                      ),
                      _AppearanceOption(
                        icon: Icons.desktop_windows_outlined,
                        label: 'System Default',
                        selected: theme.mode == ThemeMode.system,
                        onTap: () => theme.setMode(ThemeMode.system),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Account'),
                  _Card(
                    children: [
                      _ActionRow(
                        icon: Icons.vpn_key_outlined,
                        label: 'Change Password',
                        showChevron: true,
                        onTap: () => _changePassword(context),
                      ),
                      _ActionRow(
                        icon: Icons.swap_horiz,
                        label: 'Switch Access Type',
                        onTap: () => _goToRoleSelection(context),
                      ),
                      _ActionRow(
                        icon: Icons.logout,
                        label: 'Logout',
                        danger: true,
                        last: true,
                        onTap: () => _goToRoleSelection(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children, this.padding = EdgeInsets.zero});
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppTheme.primary : cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showChevron = false,
    this.danger = false,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showChevron;
  final bool danger;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = danger ? AppTheme.danger : cs.onSurface;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}