import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';

class AgeGateScreen extends ConsumerStatefulWidget {
  const AgeGateScreen({super.key});

  @override
  ConsumerState<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends ConsumerState<AgeGateScreen> {
  DateTime? _selectedDob;
  bool _submitted = false;

  int? get _age {
    if (_selectedDob == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedDob!.year;
    if (now.month < _selectedDob!.month ||
        (now.month == _selectedDob!.month && now.day < _selectedDob!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 13)),
      firstDate: DateTime(now.year - 18),
      lastDate: DateTime(now.year - 6),
      helpText: 'Select your birthday',
      fieldLabelText: 'Date of Birth',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
  }

  void _continue() {
    setState(() => _submitted = true);
    if (_selectedDob == null) return;

    final age = _age!;
    if (age < 6) {
      // Too young
      _showTooYoungDialog();
      return;
    }

    // Store DOB in a provider for signup flow
    if (age < 13) {
      context.go(AppRoutes.parentalConsent);
    } else {
      context.go(AppRoutes.signup);
    }
  }

  void _showTooYoungDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Age Requirement'),
        content: const Text(
          'LaxShot is designed for players ages 6 and up. '
          'Please check with a parent or guardian.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dob = _selectedDob;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.xxl),

              // Logo / Branding
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  ),
                  child: const Center(
                    child: Text(
                      'L',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.lg),

              Text(
                'Welcome to LaxShot',
                style: theme.textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.sm),

              Text(
                'Before we get started, let us know your birthday so we can set up your account correctly.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // DOB Picker card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of Birth',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSizes.md),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.md,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _submitted && dob == null
                                  ? AppColors.error
                                  : AppColors.outline,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cake_outlined,
                                  color: AppColors.primary),
                              const SizedBox(width: AppSizes.md),
                              Text(
                                dob != null
                                    ? DateFormat.yMMMMd().format(dob)
                                    : 'Tap to select birthday',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: dob != null
                                      ? null
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                      if (_submitted && dob == null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSizes.xs),
                          child: Text(
                            'Please select your birthday',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: AppColors.error),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.lg),

              ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue'),
              ),

              const SizedBox(height: AppSizes.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Sign In'),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}
