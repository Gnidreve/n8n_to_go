import 'dart:async';
import 'dart:io';

class ApiHttpException implements Exception {
  const ApiHttpException(this.statusCode);
  final int statusCode;
}

({String message, bool isNetworkError}) friendlyError(Object e) {
  if (e is SocketException || e is OSError) {
    return (message: 'No internet connection.', isNetworkError: true);
  }
  if (e is TimeoutException) {
    return (message: 'Connection timed out. Check your network.', isNetworkError: true);
  }
  if (e is ApiHttpException) {
    final message = switch (e.statusCode) {
      401 || 403 => 'Invalid API key.',
      404 => 'API endpoint not found. Check your base URL.',
      >= 500 => 'Server error. Try again later.',
      _ => 'Request failed (${e.statusCode}).',
    };
    return (message: message, isNetworkError: false);
  }
  return (message: 'Something went wrong. Try again.', isNetworkError: false);
}
