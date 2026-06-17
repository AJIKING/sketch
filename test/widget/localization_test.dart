import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch/src/app.dart';
import 'package:sketch/src/application/dependencies.dart';
import 'package:sketch/src/application/gallery_controller.dart';
import 'package:sketch/src/ui/canvas/canvas_screen.dart';
import 'package:sketch/src/ui/gallery/gallery_screen.dart';

import '../fixtures/fake_clock.dart';
import '../fixtures/in_memory_gallery_store.dart';
import '../fixtures/in_memory_settings_store.dart';
import '../fixtures/l10n_app.dart';
import '../fixtures/recording_image_exporter.dart';

void main() {
  GalleryScreen gallery() => GalleryScreen(
    controller: GalleryController(
      store: InMemoryGalleryStore(),
      clock: FakeClock(),
    ),
    onNewCanvas: () {},
    onOpenSketch: (_) {},
  );

  Dependencies deps() => Dependencies(
    clock: FakeClock(),
    galleryStore: InMemoryGalleryStore(),
    imageExporter: RecordingImageExporter(),
    settingsStore: InMemorySettingsStore(),
  );

  CanvasScreen canvas(Dependencies d) => CanvasScreen(
    dependencies: d,
    gallery: GalleryController(store: d.galleryStore, clock: d.clock),
  );

  group('ギャラリーの「新規キャンバス」が各言語で出る', () {
    testWidgets('日本語', (tester) async {
      await tester.pumpWidget(
        localizedApp(gallery(), locale: const Locale('ja')),
      );
      await tester.pump();
      expect(find.text('新規キャンバス'), findsOneWidget);
    });

    testWidgets('英語', (tester) async {
      await tester.pumpWidget(
        localizedApp(gallery(), locale: const Locale('en')),
      );
      await tester.pump();
      expect(find.text('New canvas'), findsOneWidget);
    });

    testWidgets('簡体字', (tester) async {
      await tester.pumpWidget(
        localizedApp(gallery(), locale: const Locale('zh')),
      );
      await tester.pump();
      expect(find.text('新建画布'), findsOneWidget);
    });
  });

  group('キャンバスのツール名・ブラシ名が各言語で出る', () {
    testWidgets('英語: ツールチップとブラシ名', (tester) async {
      await tester.pumpWidget(
        localizedApp(canvas(deps()), locale: const Locale('en')),
      );
      await tester.pump();
      expect(find.byTooltip('Brush'), findsOneWidget);

      await tester.tap(find.byTooltip('Brush'));
      await tester.pumpAndSettle();
      expect(find.text('Ink'), findsOneWidget); // brush name from l10n
      expect(find.text('Stabilization'), findsOneWidget);
    });

    testWidgets('簡体字: ツールチップとブラシ名', (tester) async {
      await tester.pumpWidget(
        localizedApp(canvas(deps()), locale: const Locale('zh')),
      );
      await tester.pump();
      expect(find.byTooltip('画笔'), findsOneWidget);

      await tester.tap(find.byTooltip('画笔'));
      await tester.pumpAndSettle();
      expect(find.text('墨水'), findsOneWidget);
    });
  });

  testWidgets('言語切替UIで日本語→英語に切り替わり永続化される', (tester) async {
    final settings = InMemorySettingsStore();
    final d = Dependencies(
      clock: FakeClock(),
      galleryStore: InMemoryGalleryStore(),
      imageExporter: RecordingImageExporter(),
      settingsStore: settings,
    );
    await tester.pumpWidget(RakugaApp(dependencies: d));
    await tester.pumpAndSettle();

    // 既定(テスト環境=英語フォールバック)から日本語へ切り替える。
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日本語'));
    await tester.pumpAndSettle();
    expect(find.text('新規キャンバス'), findsOneWidget);
    expect(await settings.loadLocale(), 'ja');

    // さらに英語へ。
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('New canvas'), findsOneWidget);
    expect(await settings.loadLocale(), 'en');
  });
}
