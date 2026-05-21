import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Messages d'erreur API sûrs pour l'affichage utilisateur.
class ApiErrorUtils {
  ApiErrorUtils._();

  static const String generic =
      'Une erreur est survenue. Veuillez réessayer.';

  static const String authFailed = 'Identifiants incorrects.';

  static String fromHttpResponse(
    int statusCode,
    String body, {
    String fallback = generic,
  }) {
    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final msg = decoded['error'] ?? decoded['message'];
          if (msg is String && _isSafeClientMessage(msg)) {
            return _normalizeSafeMessage(msg);
          }
        }
      } catch (_) {
        // Corps non JSON
      }
    }

    if (kDebugMode && body.isNotEmpty) {
      final preview = body.length > 200 ? '${body.substring(0, 200)}...' : body;
      debugPrint('API $statusCode: $preview');
    }
    return fallback;
  }

  static String sanitizeForDisplay(Object? error, {String fallback = generic}) {
    if (error == null) return fallback;
    var text = error.toString().trim();
    const prefixes = ['Exception: ', 'Error: ', 'FormatException: '];
    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
        break;
      }
    }
    if (!_isSafeClientMessage(text)) return fallback;
    return _normalizeSafeMessage(text);
  }

  /// Messages courts autorisés côté client (alignés sur le backend).
  static String _normalizeSafeMessage(String message) {
    const allowed = {
      'Identifiants incorrects.',
      'Identifiants incorrects',
      'Email ou mot de passe incorrect.',
      'Email ou mot de passe incorrect',
      'Une erreur est survenue. Veuillez réessayer.',
      'Impossible de traiter la demande.',
      'Impossible de finaliser l\'inscription.',
      'Impossible d\'activer le compte.',
      'Informations invalides.',
      'Accès refusé.',
      'Échec d\'inscription',
      'Échec d\'activation du compte',
    };
    if (allowed.contains(message)) return message;
    if (message.toLowerCase().contains('identifiant') ||
        message.toLowerCase().contains('mot de passe incorrect')) {
      return authFailed;
    }
    return generic;
  }

  static bool _isSafeClientMessage(String message) {
    if (message.length > 120) return false;
    final lower = message.toLowerCase();
    return !lower.contains('sql') &&
        !lower.contains('exception') &&
        !lower.contains('hibernate') &&
        !lower.contains('jdbc') &&
        !lower.contains('syntax') &&
        !lower.contains('org.') &&
        !lower.contains('com.') &&
        !lower.contains('stacktrace');
  }
}
