import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped when farms, visits, or dashboard data changes elsewhere in the app.
class AppRefreshNotifier extends StateNotifier<int> {
  AppRefreshNotifier() : super(0);

  void bump() => state++;
}

final appRefreshProvider =
    StateNotifierProvider<AppRefreshNotifier, int>((ref) {
  return AppRefreshNotifier();
});

void bumpAppRefresh(WidgetRef ref) {
  ref.read(appRefreshProvider.notifier).bump();
}
