import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A UI-only preview never creates a token or persists an authenticated session.
const kAuthPreview = bool.fromEnvironment('MICUT_AUTH_PREVIEW');
final authPreviewProvider = Provider<bool>((ref) => kAuthPreview);
final onboardingNicknameProvider = StateProvider<String>((ref) => '');

/// Implement against the agreed backend contract; no guessed OAuth endpoints.
abstract interface class AuthGateway {
  /// True when the signed-in account needs onboarding, false for an existing user.
  Future<bool> signInWithGoogle();
  Future<void> completeOnboarding(
      {required String nickname,
      required bool termsAccepted,
      required bool privacyAccepted});
}

final authGatewayProvider = Provider<AuthGateway?>((ref) => null);

abstract final class AuthLegalLinks {
  static const terms = String.fromEnvironment('MICUT_TERMS_URL');
  static const privacy = String.fromEnvironment('MICUT_PRIVACY_URL');
  static Uri? validUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? uri
        : null;
  }
}
