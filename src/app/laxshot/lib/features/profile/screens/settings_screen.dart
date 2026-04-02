import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _gameAlerts = true;
  bool _weeklyReport = true;
  bool _autoDeleteVideos = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserModelProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          _SectionHeader(title: 'Notifications'),
          _ToggleTile(
            icon: Icons.notifications_active,
            label: 'Game Alerts',
            subtitle: 'Reminders to practice',
            value: _gameAlerts,
            onChanged: (v) => setState(() => _gameAlerts = v),
          ),
          _ToggleTile(
            icon: Icons.bar_chart,
            label: 'Weekly Report',
            subtitle: 'Progress summary every Sunday',
            value: _weeklyReport,
            onChanged: (v) => setState(() => _weeklyReport = v),
          ),

          const SizedBox(height: AppSizes.md),
          _SectionHeader(title: 'Privacy & Data'),
          _ToggleTile(
            icon: Icons.delete_sweep,
            label: 'Auto-Delete Videos',
            subtitle: 'Remove videos after analysis (saves storage)',
            value: _autoDeleteVideos,
            onChanged: (v) => setState(() => _autoDeleteVideos = v),
          ),
          _ActionTile(
            icon: Icons.download,
            label: 'Download My Data',
            subtitle: 'Export all your stats and sessions',
            onTap: () {/* TODO: call Cloud Function */},
          ),

          if (user?.isMinor == true) ...[
            const SizedBox(height: AppSizes.md),
            _SectionHeader(title: 'Parental Controls'),
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              margin: const EdgeInsets.only(bottom: AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.family_restroom, color: AppColors.primary),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      user?.parentApproved == true
                          ? 'Parent has approved this account.'
                          : 'Waiting for parental approval. Check your parent\'s email.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSizes.md),
          _SectionHeader(title: 'Account'),
          _ActionTile(
            icon: Icons.logout,
            label: 'Sign Out',
            iconColor: Colors.orange,
            onTap: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
          _ActionTile(
            icon: Icons.delete_forever,
            label: 'Delete Account',
            subtitle: 'Permanently remove all your data',
            iconColor: Colors.red,
            labelColor: Colors.red,
            onTap: () => _confirmDeleteAccount(context),
          ),

          const SizedBox(height: AppSizes.md),
          _SectionHeader(title: 'About'),
          _ActionTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            onTap: () {/* open URL */},
          ),
          _ActionTile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            onTap: () {/* open URL */},
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.md),
            child: Center(
              child: Text('LaxShot v1.0.0', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account, all stats, and all videos. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authServiceProvider).deleteAccount();
                if (mounted) context.go(AppRoutes.login);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.iconColor,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: labelColor)),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
