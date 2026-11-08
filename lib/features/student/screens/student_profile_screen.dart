import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes.dart';
import '../../../core/theme/app_theme.dart';
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
    final p = state.profile;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: const Text(
              'Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p == null
                              ? 'Profile details not available yet'
                              : '${p.program} · Student',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
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
                        selected: state.appearance == AppearanceChoice.light,
                        onTap: () =>
                            state.setAppearance(AppearanceChoice.light),
                      ),
                      _AppearanceOption(
                        icon: Icons.dark_mode_outlined,
                        label: 'Dark',
                        selected: state.appearance == AppearanceChoice.dark,
                        onTap: () =>
                            state.setAppearance(AppearanceChoice.dark),
                      ),
                      _AppearanceOption(
                        icon: Icons.desktop_windows_outlined,
                        label: 'System Default',
                        selected:
                        state.appearance == AppearanceChoice.system,
                        onTap: () =>
                            state.setAppearance(AppearanceChoice.system),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Dark and System Default themes are not applied yet.',
                      style: TextStyle(
                          fontSize: 11.5, color: AppTheme.textMuted),
                    ),
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
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textDark,
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
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMuted)),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
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
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.infoBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppTheme.primary : AppTheme.textMuted,
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
    final color = danger ? AppTheme.danger : AppTheme.textDark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppTheme.border)),
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
              const Icon(Icons.chevron_right,
                  size: 20, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}