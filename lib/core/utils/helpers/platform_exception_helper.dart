import 'package:flutter/services.dart';
import 'package:t_store/core/utils/helpers/logger_helper.dart';

class PlatformExceptionHelper {
  static String handlePlatformError(PlatformException exception) {
    LoggerHelper.error("Platform Exception: ${exception.message}", exception);

    switch (exception.code) {
      case 'PERMISSION_DENIED':
        return "Permission denied. Please allow the app to access.";
      case 'PERMISSION_DENIED_NEVER_ASK':
        return "Permission permanently denied. You can enable it in settings.";
      case 'LOCATION_SERVICES_DISABLED':
        return "Location services are disabled. Please enable location and try again.";
      case 'NETWORK_ERROR':
        return "Network error. Please check your internet connection.";
      case 'IO_ERROR':
        return "I/O error. Please try again later.";
      case 'UNAVAILABLE':
        return "Service unavailable. Please try again later.";
      case 'ACTIVITY_NOT_FOUND':
        return "Cannot open the requested app. Please ensure it is installed.";
      case 'INVALID_ARGUMENT':
        return "Invalid data provided. Please check and try again.";
      case 'TIMEOUT':
        return "Operation timed out. Please try again.";
      case 'SIGN_IN_FAILED':
        return "Sign in failed. Please check your credentials and try again.";
      case 'USER_CANCELLED':
        return "Operation cancelled by user.";
      case 'STORAGE_FULL':
        return "Storage is full. Please free up some space and try again.";
      case 'INTERNAL_ERROR':
        return "An internal error occurred. Please try again later.";
      case 'UNKNOWN_ERROR':
        return "Unknown error. Please try again later.";
      default:
        return "An unexpected error occurred: ${exception.code}. Please try again.";
    }
  }
}
