import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected bottom-nav tab for the executive shell (0 = Home).
final executiveTabIndexProvider = StateProvider<int>((ref) => 0);

void switchExecutiveTab(WidgetRef ref, int index) {
  ref.read(executiveTabIndexProvider.notifier).state = index;
}
