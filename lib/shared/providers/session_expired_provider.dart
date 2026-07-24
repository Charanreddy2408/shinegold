import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True only after a hard auth failure (DioClient.onAuthFailure fired,
/// meaning a 401 survived a refresh attempt) — never set by a normal
/// user-initiated logout, so the interstitial only shows for real
/// session expiry.
class SessionExpiredNotifier extends StateNotifier<bool> {
  SessionExpiredNotifier() : super(false);

  void markExpired() => state = true;
  void clear() => state = false;
}

final sessionExpiredProvider =
    StateNotifierProvider<SessionExpiredNotifier, bool>((ref) {
  return SessionExpiredNotifier();
});
