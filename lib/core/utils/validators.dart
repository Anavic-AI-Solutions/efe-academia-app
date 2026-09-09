class AppValidators {
  AppValidators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (!value.contains('@') || !value.contains('.')) return 'Invalid email';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Required';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
