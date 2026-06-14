import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/app.dart';

void main() {
  testWidgets('起動するとギャラリーのブランドと新規ボタンが出る', (tester) async {
    await tester.pumpWidget(const HatchApp());

    expect(find.text('Hatch'), findsOneWidget);
    expect(find.text('Pocket Atelier'), findsOneWidget);
    expect(find.text('新規キャンバス'), findsOneWidget);
  });
}
