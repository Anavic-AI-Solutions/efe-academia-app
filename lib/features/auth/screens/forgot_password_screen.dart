import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../l10n/l10n.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.onBackToLogin});

  final VoidCallback? onBackToLogin;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).forgotPassword(_emailController.text.trim());
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          color: AppColors.lightBackground,
          child: Column(
            children: [
              // Gradient header with bottom radius 24
              GradientHeader(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.lockKey,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.authForgotPasswordTitle,
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              // Form area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _submitted ? _buildSuccessState() : _buildFormState(isLoading),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(bool isLoading) {
    final l10n = context.l10n;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(
            l10n.authResetSubtitle,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.authResetInstructions,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 28),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSubmit(),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.lightTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: l10n.authEmailLabel,
              prefixIcon: const Icon(
                PhosphorIconsRegular.envelope,
                size: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.authEmailRequired;
              }
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value.trim())) {
                return l10n.authEmailInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          PillButton(
            label: l10n.authSendResetLink,
            isLoading: isLoading,
            isGradient: true,
            onPressed: _handleSubmit,
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: widget.onBackToLogin ?? () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              l10n.authBackToSignIn,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    final l10n = context.l10n;

    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            PhosphorIconsRegular.checkCircle,
            size: 36,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.authCheckEmail,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.lightTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.authResetLinkSent(_emailController.text.trim()),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        PillButton(
          label: l10n.authBackToSignIn,
          onPressed: widget.onBackToLogin ?? () => Navigator.pop(context),
        ),
      ],
    );
  }
}
