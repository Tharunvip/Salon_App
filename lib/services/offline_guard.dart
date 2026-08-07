import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

/// A user-facing app error with a friendly message.
class AppError implements Exception {
  const AppError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Maps a raw Firebase/network error to a friendly message the user can
/// understand. Used everywhere errors surface to the UI.
String friendlyError(Object error) {
  if (error is AppError) return error.message;
  if (error is FirebaseAuthException) return _authMessage(error);
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unavailable':
      case 'network-request-failed':
        return 'You seem to be offline. Check your connection and try again.';
      case 'permission-denied':
        return 'You do not have permission to do this.';
      case 'not-found':
        return 'The item no longer exists.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
  if (error is TimeoutException) {
    return 'The request took too long. Check your connection and try again.';
  }
  if (error is SocketException) {
    return 'You seem to be offline. Check your connection and try again.';
  }
  return 'Something went wrong. Please try again.';
}

/// Runs [run] with a timeout and rethrows every failure as an [AppError]
/// carrying a friendly message. Wrap network operations with this so offline
/// users get a clear message instead of a raw Firebase error string.
Future<T> guarded<T>(
  Future<T> Function() run, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  try {
    return await run().timeout(timeout);
  } on AppError {
    rethrow;
  } catch (e) {
    throw AppError(friendlyError(e));
  }
}

String _authMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Incorrect email or password.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'You seem to be offline. Check your connection and try again.';
    case 'email-already-in-use':
      return 'This email is already registered.';
    case 'weak-password':
      return 'Password is too weak.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    default:
      return 'Authentication failed. Please try again.';
  }
}
