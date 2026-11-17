import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/large_title_bar.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../auth/domain/user_model.dart';
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
  static const int _maxAvatarBytes = 2 * 1024 * 1024;
  static const Set<String> _allowedAvatarExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
  };
  static const ValueKey<String> _previewKey = ValueKey(
    'profile-avatar-preview',
  );

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  AvatarUploadFile? _preview;
  bool _uploading = false;
  String? _photoError;

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

    _showSnackBar(message, isError: !ok);
  }

  Future<AvatarUploadFile?> _defaultPickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;
    return AvatarUploadFile(bytes: bytes, name: file.name);
  }

  Future<void> _handlePickAvatar() async {
    if (_uploading) return;

    final l10n = context.l10n;
    final picked = await (widget.pickAvatar ?? _defaultPickAvatar)();
    if (!mounted || picked == null) return;

    if (!_isValidAvatar(picked)) {
      setState(() => _photoError = l10n.profileEditPhotoInvalid);
      _showSnackBar(l10n.profileEditPhotoInvalid, isError: true);
      return;
    }

    setState(() {
      _preview = picked;
      _photoError = null;
      _uploading = true;
    });

    final url = await ref
        .read(profileEditProvider.notifier)
        .uploadAvatar(bytes: picked.bytes, filename: picked.name);
    if (!mounted) return;

    setState(() {
      // On success the auth state already carries the new URL; on failure we
      // fall back to the previously visible avatar.
      _preview = null;
      _uploading = false;
      _photoError = url == null ? l10n.profileEditPhotoError : null;
    });

    _showSnackBar(
      url == null ? l10n.profileEditPhotoError : l10n.profileEditPhotoUploaded,
      isError: url == null,
    );
  }

  bool _isValidAvatar(AvatarUploadFile file) {
    final dot = file.name.lastIndexOf('.');
    final extension =
        dot == -1 ? '' : file.name.substring(dot + 1).toLowerCase();
    return _allowedAvatarExtensions.contains(extension) &&
        file.bytes.length <= _maxAvatarBytes;
  }

  void _showSnackBar(String message, {required bool isError}) {
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

  Widget _buildPhotoEditor({
    required bool isDark,
    required AppLocalizations l10n,
    required UserModel? user,
  }) {
    final avatar = _preview != null
        ? Container(
            width: 102,
            height: 102,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.memory(
                  _preview!.bytes,
                  key: _previewKey,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          )
        : AppAvatar(
            imageUrl: user?.avatarUrl,
            name: user?.name ?? '',
            size: 96,
            showGradientRing: true,
          );

    return Column(
      children: [
        SectionHeader(title: l10n.profileEditPhotoSection),
        const SizedBox(height: 12),
        Center(
          child: Semantics(
            label: l10n.profileEditChangePhoto,
            button: true,
            container: true,
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey('profile-avatar-editor'),
              onTap: _uploading ? null : _handlePickAvatar,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  avatar,
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.camera,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_uploading)
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.profileEditPhotoHint,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.mutedFor(isDark),
          ),
        ),
        if (_photoError != null) ...[
          const SizedBox(height: 4),
          Text(
            _photoError!,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
      ],
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
                _buildPhotoEditor(isDark: isDark, l10n: l10n, user: user),
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
