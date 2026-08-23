enum PublicAuthFailureClass {
  cancelled,
  configuration,
  providerConfiguration,
  interrupted,
  uiUnavailable,
  userMismatch,
  missingIdentity,
  network,
  throttled,
  accountCollision,
  disabledAccount,
  invalidCredential,
  expiredCredential,
  providerUnavailable,
  nativeBridge,
  firebaseUnclassified,
  unknown,
}

class PublicAuthFailure {
  const PublicAuthFailure(this.failureClass, this.publicMessage);

  final PublicAuthFailureClass failureClass;
  final String publicMessage;

  String get code => switch (failureClass) {
    PublicAuthFailureClass.cancelled => 'auth-cancelled',
    PublicAuthFailureClass.configuration => 'auth-client-configuration',
    PublicAuthFailureClass.providerConfiguration =>
      'auth-provider-configuration',
    PublicAuthFailureClass.interrupted => 'auth-interrupted',
    PublicAuthFailureClass.uiUnavailable => 'auth-ui-unavailable',
    PublicAuthFailureClass.userMismatch => 'auth-user-mismatch',
    PublicAuthFailureClass.missingIdentity => 'auth-missing-identity',
    PublicAuthFailureClass.network => 'auth-network',
    PublicAuthFailureClass.throttled => 'auth-throttled',
    PublicAuthFailureClass.accountCollision => 'auth-account-collision',
    PublicAuthFailureClass.disabledAccount => 'auth-account-disabled',
    PublicAuthFailureClass.invalidCredential => 'auth-invalid-credential',
    PublicAuthFailureClass.expiredCredential => 'auth-expired-credential',
    PublicAuthFailureClass.providerUnavailable => 'auth-provider-unavailable',
    PublicAuthFailureClass.nativeBridge => 'auth-native-bridge',
    PublicAuthFailureClass.firebaseUnclassified => 'auth-firebase-unclassified',
    PublicAuthFailureClass.unknown => 'auth-unknown',
  };
}

PublicAuthFailure sanitizedGoogleIdentityFailure(String code) {
  return switch (code) {
    'canceled' || 'cancelled' => const PublicAuthFailure(
      PublicAuthFailureClass.cancelled,
      'Google sign-in was cancelled.',
    ),
    'clientConfigurationError' => const PublicAuthFailure(
      PublicAuthFailureClass.configuration,
      'Google sign-in is not configured for this app. Choose another method.',
    ),
    'providerConfigurationError' => const PublicAuthFailure(
      PublicAuthFailureClass.providerConfiguration,
      'Google sign-in is not available right now. Choose another method.',
    ),
    'interrupted' => const PublicAuthFailure(
      PublicAuthFailureClass.interrupted,
      'Google sign-in was interrupted. Please try again.',
    ),
    'uiUnavailable' => const PublicAuthFailure(
      PublicAuthFailureClass.uiUnavailable,
      'Google sign-in could not open on this device. Please try again.',
    ),
    'userMismatch' => const PublicAuthFailure(
      PublicAuthFailureClass.userMismatch,
      'Google could not confirm the selected account. Choose the account again.',
    ),
    'missing-id-token' => const PublicAuthFailure(
      PublicAuthFailureClass.missingIdentity,
      'Google sign-in did not return a valid identity. Please try again.',
    ),
    'networkError' => const PublicAuthFailure(
      PublicAuthFailureClass.network,
      'Google sign-in could not connect. Check your connection and try again.',
    ),
    _ => const PublicAuthFailure(
      PublicAuthFailureClass.nativeBridge,
      'Google sign-in could not be completed. Please try again.',
    ),
  };
}

PublicAuthFailure sanitizedFirebaseAuthFailure(
  String code, {
  String providerLabel = 'This sign-in method',
}) {
  return switch (code) {
    'canceled' ||
    'cancelled' ||
    'popup-closed-by-user' ||
    'web-context-cancelled' ||
    'user-cancelled' => PublicAuthFailure(
      PublicAuthFailureClass.cancelled,
      '$providerLabel sign-in was cancelled.',
    ),
    'account-exists-with-different-credential' ||
    'credential-already-in-use' => const PublicAuthFailure(
      PublicAuthFailureClass.accountCollision,
      'This account already uses another sign-in method. Choose that method to continue.',
    ),
    'network-request-failed' ||
    'web-network-request-failed' => PublicAuthFailure(
      PublicAuthFailureClass.network,
      '$providerLabel sign-in could not connect. Check your connection and try again.',
    ),
    'too-many-requests' => const PublicAuthFailure(
      PublicAuthFailureClass.throttled,
      'Too many attempts. Wait a moment before trying again.',
    ),
    'user-disabled' => const PublicAuthFailure(
      PublicAuthFailureClass.disabledAccount,
      'This account cannot sign in right now. Choose another method.',
    ),
    'operation-not-allowed' ||
    'provider-already-linked' ||
    'invalid-oauth-provider' => PublicAuthFailure(
      PublicAuthFailureClass.providerUnavailable,
      '$providerLabel sign-in is not available right now. Choose another method.',
    ),
    'invalid-credential' ||
    'invalid-idp-response' ||
    'invalid-custom-token' ||
    'custom-token-mismatch' ||
    'missing-or-invalid-nonce' => PublicAuthFailure(
      PublicAuthFailureClass.invalidCredential,
      '$providerLabel sign-in could not confirm the authorization. Please try again.',
    ),
    'expired-action-code' || 'session-expired' => const PublicAuthFailure(
      PublicAuthFailureClass.expiredCredential,
      'This sign-in attempt has expired. Start again.',
    ),
    _ => PublicAuthFailure(
      PublicAuthFailureClass.firebaseUnclassified,
      '$providerLabel sign-in could not be completed. Please try again.',
    ),
  };
}
