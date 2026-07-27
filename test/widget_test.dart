import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shine_gold/app.dart';
import 'package:shine_gold/data/datasources/remote/api_config_datasource.dart';
import 'package:shine_gold/data/models/app_remote_config.dart';
import 'package:shine_gold/shared/providers/app_remote_config_provider.dart';

/// Returns config without touching the network.
///
/// The real datasource is called from [ShineGoldApp]'s first post-frame
/// callback. In a test binding every HTTP request returns 400, but Dio has
/// already armed its timeout timer — which is still pending when the tree is
/// torn down, failing the test with "A Timer is still pending".
class _StubConfigDataSource implements ApiConfigDataSource {
  @override
  Future<AppRemoteConfig> fetch() async => AppRemoteConfig.defaults;
}

void main() {
  testWidgets('App loads welcome screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiConfigDataSourceProvider.overrideWithValue(
            _StubConfigDataSource(),
          ),
        ],
        child: const ShineGoldApp(),
      ),
    );
    await tester.pump();

    expect(find.text('ORGANIC AGRO INVENTION'), findsOneWidget);

    // Deliberately not pumped past the splash duration: letting the progress
    // animation finish fires WelcomeScreen._goNext, which polls every 40ms
    // until auth resolves — and auth never resolves under a test binding.
  });
}
