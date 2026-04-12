import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../presentation/widgets/laxshot_logo.dart';
import '../providers/auth_provider.dart';

class ParentalConsentScreen extends ConsumerStatefulWidget {
  const ParentalConsentScreen({super.key});

  @override
  ConsumerState<ParentalConsentScreen> createState() =>
      _ParentalConsentScreenState();
}

class _ParentalConsentScreenState
    extends ConsumerState<ParentalConsentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parentEmailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _parentEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendConsent() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authNotifierProvider.notifier)
        .requestParentalConsent(_parentEmailCtrl.text.trim());

    if (!mounted) return;

    final err = ref.read(authNotifierProvider).error;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send consent request. Try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final currentUser = ref.watch(currentUserModelProvider).valueOrNull;
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: _sent ? _buildSentView(theme, currentUser?.parentEmail) : _buildFormView(theme, isLoading),
        ),
      ),
    );
  }

  Widget _buildFormView(ThemeData theme, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSizes.xl),

          const Center(child: LaxShotLogo(size: 80)),

          const SizedBox(height: AppSizes.lg),

          Text(
            'Parent Approval Required',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.md),

          Text(
            'Because you\'re under 13, we need a parent or guardian to approve your LaxShot account. '
            'We\'ll send them a quick approval email.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // COPPA info card
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'Your privacy is protected',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'LaxShot follows COPPA guidelines to keep players under 13 safe. '
                  'Your parent will review what data we collect before your account is activated.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          TextFormField(
            controller: _parentEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendConsent(),
            decoration: const InputDecoration(
              labelText: "Parent / Guardian's Email",
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'parent@example.com',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Enter a parent or guardian email';
              }
              if (!v.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),

          const SizedBox(height: AppSizes.lg),

          SizedBox(
            height: AppSizes.buttonHeight,
            child: ElevatedButton(
              onPressed: isLoading ? null : _sendConsent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send Approval Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: AppSizes.md),

          TextButton(
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
            child: const Text('Sign Out'),
          ),

          const SizedBox(height: AppSizes.md),
        ],
      ),
    );
  }

  Widget _buildSentView(ThemeData theme, String? parentEmail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Center(
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 80,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: AppSizes.lg),

        Text(
          'Approval email sent!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSizes.md),

        Text(
          parentEmail != null
              ? 'We sent an approval request to $parentEmail.\n\nOnce they approve, you\'ll be able to use LaxShot.'
              : 'Ask your parent or guardian to check their email and click the approval link.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSizes.xl),

        OutlinedButton(
          onPressed: () => setState(() => _sent = false),
          child: const Text('Use a different email'),
        ),

        const SizedBox(height: AppSizes.md),

        TextButton(
          onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
          child: const Text('Sign Out'),
        ),
      ],
    );
  }
}
