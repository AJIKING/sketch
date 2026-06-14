import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sketch/src/app.dart';

/// Integration smoke(`docs/test-plan.md`「Integration smoke」)。
///
/// 端末上で起動 → ギャラリー表示までを確認する最小 journey。
/// 実装が進んだら「新規キャンバス → 描画 → 保存 → ギャラリー反映」まで広げる。
/// 実行: `flutter test integration_test -d <device-id>`。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('起動してギャラリーが表示される', (tester) async {
    await tester.pumpWidget(const HatchApp());
    await tester.pumpAndSettle();

    expect(find.text('Hatch'), findsOneWidget);
    expect(find.text('新規キャンバス'), findsOneWidget);
  });
}
