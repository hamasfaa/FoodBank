import 'package:foodbank/core/constants/app_strings.dart';

class Validators {
  Validators._();

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    if (value.trim().length < 3) return AppStrings.validFullName;
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return AppStrings.validEmail;
    return null;
  }

  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final phoneRegex = RegExp(r'^(\+62|08)\d{8,11}$');
    if (!phoneRegex.hasMatch(value.trim())) return AppStrings.validPhone;
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value.length < 8) return AppStrings.validPassword;
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) return AppStrings.validPassword;
    if (!RegExp(r'[0-9]').hasMatch(value)) return AppStrings.validPassword;
    return null;
  }

  static String? Function(String?) confirmPassword(String passwordValue) {
    return (String? value) {
      if (value == null || value.isEmpty) return AppStrings.fieldRequired;
      if (value != passwordValue) return AppStrings.validConfirmPassword;
      return null;
    };
  }
}
