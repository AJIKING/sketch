import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/app.dart';
import 'package:sketch/src/application/dependencies.dart';

import '../fixtures/fake_clock.dart';
import '../fixtures/in_memory_gallery_store.dart';
import '../fixtures/recording_image_exporter.dart';

void main() {
  testWidgets('起動するとギャラリーのブランドと新規ボタンが出る', (tester) async {
    final deps = Dependencies(
      clock: FakeClock(),
      galleryStore: InMemoryGalleryStore(),
      imageExporter: RecordingImageExporter(),
    );
    await tester.pumpWidget(HatchApp(dependencies: deps));
    await tester.pump();

    expect(find.text('Hatch'), findsOneWidget);
    expect(find.text('Pocket Atelier'), findsOneWidget);
    expect(find.text('新規キャンバス'), findsOneWidget);
  });
}
