import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/l10n.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/avatar_upload_file.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.pickAvatar});

  final Future<AvatarUploadFile?> Function()? pickAvatar;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final ok = await ref.read(profileEditProvider.notifier).saveProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
        );
    if (!mounted) return;

    final hasEmailError =
        ref.read(profileEditProvider).fieldErrors.containsKey('email');
    final message = ok
        ? l10n.profileEditSaved
        : (hasEmailError
            ? l10n.profileEditEmailInUse
            : l10n.profileEditSaveError);
    final isError = !ok;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final user = ref.watch(authProvider).user;
    final savingProfile = ref.watch(
      profileEditProvider.select((state) => state.savingProfile),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(isDark),
      body: Column(
        children: [
          LargeTitleBar(
            title: l10n.profileEditProfileTitle,
            showBackButton: true,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                // Placeholder header. Task 11 replaces this with the avatar
                // editor (tappable, uses `widget.pickAvatar`).
                Center(
                  child: AppAvatar(
                    imageUrl: user?.avatarUrl,
                    name: user?.name ?? '',
                    size: 96,
                    showGradientRing: true,
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeader(title: l10n.profileEditDataSection),
                const SizedBox(height: 8),
                AppCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.inkFor(isDark),
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.profileEditNameLabel,
                          ),
                          validator: (value) =>
                              AppValidators.required(value, l10n),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleSave(),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.inkFor(isDark),
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.profileEditEmailLabel,
                          ),
                          validator: (value) =>
                              AppValidators.email(value, l10n),
                        ),
                        const SizedBox(height: 20),
                        PillButton(
                          label: l10n.profileEditSave,
                          isLoading: savingProfile,
                          onPressed: _handleSave,
                        ),
                      ],
                    ),
                  ),
                ),
                // Task 12 adds the password form here.
              ],
            ),
          ),
        ],
      ),
    );
  }
}
