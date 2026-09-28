import 'package:supabase_flutter/supabase_flutter.dart';

/// Custom exception for Supabase errors
class SupabaseException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  SupabaseException({required this.message, this.code, this.originalError});

  /// Create from AuthException
  factory SupabaseException.fromAuthException(AuthException e) {
    return SupabaseException(
      message: _getAuthErrorMessage(e.message),
      code: e.statusCode,
      originalError: e,
    );
  }

  /// Create from PostgrestException
  factory SupabaseException.fromPostgrestException(PostgrestException e) {
    return SupabaseException(
      message: _getDatabaseErrorMessage(e.message, e.code),
      code: e.code,
      originalError: e,
    );
  }

  /// Create from StorageException
  factory SupabaseException.fromStorageException(StorageException e) {
    return SupabaseException(
      message: _getStorageErrorMessage(e.message),
      code: e.statusCode,
      originalError: e,
    );
  }

  /// Create from generic exception
  factory SupabaseException.fromException(dynamic e) {
    if (e is AuthException) {
      return SupabaseException.fromAuthException(e);
    } else if (e is PostgrestException) {
      return SupabaseException.fromPostgrestException(e);
    } else if (e is StorageException) {
      return SupabaseException.fromStorageException(e);
    } else {
      return SupabaseException(message: e.toString(), originalError: e);
    }
  }

  /// Get user-friendly auth error message
  static String _getAuthErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('invalid login credentials')) {
      return 'Invalid email or password';
    }
    if (lowerMessage.contains('email not confirmed')) {
      return 'Please confirm your email first';
    }
    if (lowerMessage.contains('user already registered')) {
      return 'This email is already registered';
    }
    if (lowerMessage.contains('password')) {
      return 'Password must be at least 6 characters';
    }
    if (lowerMessage.contains('email')) {
      return 'Please enter a valid email address';
    }
    if (lowerMessage.contains('rate limit')) {
      return 'Too many attempts. Please try again later';
    }
    if (lowerMessage.contains('network')) {
      return 'Network error. Please check your internet connection';
    }

    return message;
  }

  /// Get user-friendly database error message
  static String _getDatabaseErrorMessage(String message, String? code) {
    if (code == '23505') {
      return 'This item already exists';
    }
    if (code == '23503') {
      return 'Cannot delete this item as it is referenced by other data';
    }
    if (code == 'PGRST116') {
      return 'Item not found';
    }
    if (code == '42501') {
      return 'You do not have permission to perform this action';
    }

    return message;
  }

  /// Get user-friendly storage error message
  static String _getStorageErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('not found')) {
      return 'File not found';
    }
    if (lowerMessage.contains('too large')) {
      return 'File size too large';
    }
    if (lowerMessage.contains('invalid')) {
      return 'File type not supported';
    }

    return message;
  }

  @override
  String toString() => 'SupabaseException: $message (code: $code)';
}

/// Extension to handle Supabase errors easily
extension SupabaseErrorHandler<T> on Future<T> {
  /// Handle Supabase errors and convert to SupabaseException
  Future<T> handleSupabaseError() async {
    try {
      return await this;
    } on AuthException catch (e) {
      throw SupabaseException.fromAuthException(e);
    } on PostgrestException catch (e) {
      throw SupabaseException.fromPostgrestException(e);
    } on StorageException catch (e) {
      throw SupabaseException.fromStorageException(e);
    } catch (e) {
      throw SupabaseException.fromException(e);
    }
  }
}
