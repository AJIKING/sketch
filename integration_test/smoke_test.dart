import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sketch/src/app.dart';

/// Integration smoke(`docs/test-plan.md`「Integration smoke」)。
///
/// 起動 → ギャラリー → 新規キャンバス → キャンバス表示までの最小 journey。
/// 実行: `flutter test integration_test -d <device-id>`。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('起動して新規キャンバスを開ける', (tester) async {
    await tester.pumpWidget(const RakugaApp());
    await tester.pumpAndSettle();

    expect(find.text('Rakuga'), findsOneWidget);
    expect(find.text('新規キャンバス'), findsOneWidget);

    await tester.tap(find.text('新規キャンバス'));
    await tester.pumpAndSettle();

    // キャンバスのツールドックが出ている。
    expect(find.byTooltip('ブラシ'), findsOneWidget);
    expect(find.byTooltip('レイヤー'), findsOneWidget);
  });
}
