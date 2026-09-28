import 'package:flutter/material.dart';

class TValidator {
  static String? validateConfirmPassword(
    String? value,
    TextEditingController passwordController,
  ) {
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required.';
    }

    // Regular expression for email validation
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegExp.hasMatch(value)) {
      return 'Invalid email address.';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }

    // Check for minimum password length
    if (value.length < 6) {
      return 'Password must be at least 6 characters long.';
    }

    // Check for uppercase letters
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter.';
    }

    // Check for numbers
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number.';
    }

    // Check for special characters
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character.';
    }

    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required.';
    }

    // Remove any non-digit characters for validation
    final normalizedValue = value.replaceAll(RegExp(r'\D'), '');

    // Indian mobile number: 10 digits, starting with 6-9
    // Also accept +91 prefix or 0 prefix
    final tenDigitRegExp = RegExp(r'^[6-9]\d{9}$');

    // Check various valid Indian formats:
    // 1. 10 digits starting with 6-9 (e.g., 9876543210)
    // 2. 11 digits with leading 0 (e.g., 09876543210)
    // 3. +91 prefix (13 chars total with +91)
    final isValid = tenDigitRegExp.hasMatch(normalizedValue) ||
        (normalizedValue.length == 11 && normalizedValue.startsWith('0') &&
            tenDigitRegExp.hasMatch(normalizedValue.substring(1))) ||
        (value.startsWith('+91') && tenDigitRegExp.hasMatch(normalizedValue.substring(3)));

    if (!isValid) {
      return 'Enter a valid 10-digit Indian mobile number.';
    }

    return null;
  }

  // Add more custom validators as needed for your specific requirements.
}
