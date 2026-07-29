import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shine_gold/data/models/enums.dart';
import 'package:shine_gold/shared/widgets/info_metric_tile.dart';
import 'package:shine_gold/shared/widgets/shine_buttons.dart';
import 'package:shine_gold/shared/widgets/status_chip.dart';
import 'package:shine_gold/shared/widgets/ux_components.dart';
import 'package:shine_gold/l10n/app_localizations.dart';

/// Renders shared widgets under the conditions that used to overflow them:
/// a 320dp-wide phone with the system font enlarged.
///
/// A RenderFlex overflow is reported through FlutterError, which the test
/// binding records — so `tester.takeException()` returning null is a real
/// assertion that the layout fits, not just that the widget built.
Future<void> _pumpNarrow(
  WidgetTester tester,
  Widget child, {
  double width = 320,
  double textScale = 1.3,
}) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        // Shared widgets read AppLocalizations now, so the harness has to
        // provide the delegates the real app does.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('narrow screen, enlarged text', () {
    testWidgets('ConditionSelector fits with the longest label', (tester) async {
      await _pumpNarrow(
        tester,
        ConditionSelector(
          selected: FarmHealthStatus.needsAttention,
          onSelected: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Needs Attention'), findsOneWidget);
    });

    testWidgets('metric tiles fit a long address and executive list',
        (tester) async {
      await _pumpNarrow(
        tester,
        Row(
          children: const [
            Expanded(
              child: InfoMetricTile(
                icon: Icons.location_on_rounded,
                label: 'Location',
                value: 'Balaji Hills Colony, Boduppal, Medipally mandal, '
                    'Medchal-Malkajgiri, Telangana, 500092, India',
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: InfoMetricTile(
                icon: Icons.person_rounded,
                label: 'Executives',
                value: 'Narasimhamurthy, Charan Reddy, Mani Mamidala',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('primary button clips a long label instead of overflowing',
        (tester) async {
      await _pumpNarrow(
        tester,
        ShinePrimaryButton(
          label: 'Confirm boundary and continue to farmer details',
          icon: Icons.check_rounded,
          onPressed: () {},
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('secondary button clips a long label', (tester) async {
      await _pumpNarrow(
        tester,
        ShineSecondaryButton(
          label: 'Cancel and discard everything entered so far',
          onPressed: () {},
        ),
      );
      expect(tester.takeException(), isNull);
    });

    // Mirrors the real composition in farm_card.dart: the health badge and
    // the status chip share one row with a Spacer between them.
    testWidgets('farm card status row fits the longest health label',
        (tester) async {
      await _pumpNarrow(
        tester,
        SizedBox(
          // Approximates the width left inside a farm card after its
          // outer padding and the 44px leading icon.
          width: 200,
          child: Row(
            children: const [
              Flexible(
                child: HealthBadge(status: FarmHealthStatus.needsAttention),
              ),
              SizedBox(width: 8),
              Spacer(),
              Flexible(child: StatusChip(status: FarmVisitStatus.harvested)),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sync chip fits a narrow row', (tester) async {
      await _pumpNarrow(
        tester,
        SizedBox(
          width: 140,
          child: Row(
            children: const [
              Flexible(child: SyncStatusChip(status: SyncStatus.pendingSync)),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('holds up on a 280dp screen at 1.3x too', (tester) async {
      await _pumpNarrow(
        tester,
        ConditionSelector(
          selected: FarmHealthStatus.critical,
          onSelected: (_) {},
        ),
        width: 280,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
