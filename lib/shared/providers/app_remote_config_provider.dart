import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/dio_client.dart';
import '../../data/datasources/remote/api_config_datasource.dart';
import '../../data/models/app_remote_config.dart';

final appRemoteConfigProvider =
    NotifierProvider<AppRemoteConfigNotifier, AppRemoteConfig>(
  AppRemoteConfigNotifier.new,
);

class AppRemoteConfigNotifier extends Notifier<AppRemoteConfig> {
  @override
  AppRemoteConfig build() => AppRemoteConfig.defaults;

  Future<void> load() async {
    if (AppConfig.useMockData) {
      state = AppRemoteConfig.defaults;
      return;
    }
    try {
      final config = await ref.read(apiConfigDataSourceProvider).fetch();
      state = config;
    } catch (_) {
      state = AppRemoteConfig.defaults;
    }
  }
}

final apiConfigDataSourceProvider = Provider<ApiConfigDataSource>((ref) {
  return ApiConfigDataSource(ref.watch(dioClientProvider));
});
