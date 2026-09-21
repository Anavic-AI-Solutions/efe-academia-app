import '../../l10n/app_localizations.dart';

class AppValidators {
  AppValidators._();

  static String? email(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.validationRequired;
    if (!value.contains('@') || !value.contains('.')) {
      return l10n.validationInvalidEmail;
    }
    return null;
  }

  static String? required(
    String? value,
    AppLocalizations l10n, [
    String? field,
  ]) {
    if (value == null || value.trim().isEmpty) {
      return field == null
          ? l10n.validationRequired
          : l10n.validationFieldRequired(field);
    }
    return null;
  }

  static String? password(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.validationRequired;
    if (value.length < 8) return l10n.validationPasswordLength;
    return null;
  }

  static String? confirmPassword(
    String? value,
    String password,
    AppLocalizations l10n,
  ) {
    if (value == null || value.isEmpty) return l10n.validationRequired;
    if (value != password) return l10n.validationPasswordsDoNotMatch;
    return null;
  }
}
