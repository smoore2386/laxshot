import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).valueOrNull;
    final displayName = user?.displayName ?? 'Athlete';
    final email = user?.email ?? '';
    final isGoalie = user?.position == PlayerPosition.goalie;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.settings),
            child: const Text('Settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            // Avatar + name
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),

            const SizedBox(height: AppSizes.xl),

            // Mode toggle (Player / Goalie)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, 0),
                    child: Text('Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(AppSizes.md, 4, AppSizes.md, AppSizes.sm),
                    child: Text('Choose your primary role', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _ModeOption(
                          emoji: '🏒',
                          label: 'Player',
                          subtitle: 'Shot analysis',
                          selected: !isGoalie,
                          onTap: () {
                            if (user != null) {
                              ref.read(userRepositoryProvider).updateUser(
                                user.uid,
                                {'position': PlayerPosition.attacker.name},
                              );
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: _ModeOption(
                          emoji: '🥅',
                          label: 'Goalie',
                          subtitle: 'Save analysis',
                          selected: isGoalie,
                          onTap: () {
                            if (user != null) {
                              ref.read(userRepositoryProvider).updateUser(
                                user.uid,
                                {'position': PlayerPosition.goalie.name},
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // Info cards
            _InfoCard(
              label: 'Position',
              value: user?.position != null
                  ? '${user!.position.name[0].toUpperCase()}${user.position.name.substring(1)}'
                  : 'Not set',
              icon: Icons.person,
            ),
            if (user?.isMinor == true)
              _InfoCard(
                label: 'Account Type',
                value: user?.parentApproved == true ? '✅ Parental approval granted' : '⏳ Awaiting parental approval',
                icon: Icons.family_restroom,
              ),

            const SizedBox(height: AppSizes.xl),

            // Sign out
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                side: const BorderSide(color: Colors.red),
              ),
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textPrimary)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
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
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
