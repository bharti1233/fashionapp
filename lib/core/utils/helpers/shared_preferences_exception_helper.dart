class SharedPreferencesException implements Exception {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  SharedPreferencesException(this.message, {this.error, this.stackTrace});

  @override
  String toString() => message;
}

class SharedPreferencesExceptionHelper {
  static String handleException(dynamic error) {
    if (error is FormatException) {
      return "Stored data format error";
    } else if (error is TypeError) {
      return "Stored data type error";
    } else {
      return "An unexpected error occurred while accessing local data";
    }
  }
}
