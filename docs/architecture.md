# Hatch — Flutter アーキテクチャとフォルダ構成

`docs/product-spec.md` の仕様と `docs/test-plan.md` の差し替え境界を実現するためのアプリ構造を定義する。判断基準はハーネス方針(`docs/harness-engineering.md`)と同じ: **決定的にテストできること、必要になるまで複雑にしないこと。**

## 全体像

4 層のレイヤードアーキテクチャ。依存は必ず上から下への一方向。

```text
ui           画面・ウィジェット・テーマ・ラスタライズ(Flutter / dart:ui)
  ↓
application  画面をまたぐ状態と操作(ChangeNotifier)
  ↓
domain       モデル・色変換・ブラシ/ストローク計算・履歴(pure Dart)
  ↓ (インターフェースのみ)
data         domain のインターフェース実装(永続化・画像エクスポート)
```

- **domain は pure Dart**。`dart:ui` / `package:flutter` を import しない。色変換(HSV↔RGB↔HEX)、ブラシプリセット、ストローク → スタンプ列の計算、速度→筆幅、レイヤー/履歴の状態遷移など、決定的に検証できるロジックをここに置く。
- **ピクセルのラスタライズ(`Canvas`・`dart:ui.Image`)は ui 層に置く**。domain が計算した「スタンプ計画(位置・半径・α・色)」を受け取って描く `CustomPainter` / レイヤー合成がここに当たる。domain は計画までを担当し、画素には触れない。
- **data は domain が定義したインターフェースを実装する**(依存性逆転)。domain は data を知らない。
- **ui は application を通じて状態を読む**。ui から domain のモデルを参照するのは可(表示のため)、data を直接触るのは不可。

## 主要な設計判断

| 判断 | 採用 | 理由 |
| --- | --- | --- |
| 状態管理 | `ChangeNotifier` + `ListenableBuilder`(Flutter 標準のみ) | 2 画面・通信なしの規模に外部フレームワークは過剰。依存ゼロでテストも素直。状態が破綻し始めたら Riverpod 移行を再検討 |
| DI | composition root でのコンストラクタ注入(DI コンテナなし) | 差し替え境界が少数。`main_*.dart` で全部組み立てれば十分 |
| ナビゲーション | ギャラリー ⇄ キャンバスの 2 ビュー切替(`Navigator` または AnimatedSwitcher) | 単線遷移。deep link 要件が出たら go_router を検討 |
| 乱数 | `Random(seed)` を注入 | ブラシの scatter / jitter を決定化。プロトタイプの `Math.random()` 直叩きは踏襲しない |
| 時間 | `Clock` を注入 | ストローク速度→筆幅、保存時刻を決定化。`performance.now()` 直叩きは踏襲しない |
| レイヤー画素 | `dart:ui.Image` / `Picture`(ui 層) | ラスタライズは Flutter の描画 API に委ねる。domain には持ち込まない |
| undo/redo | レイヤー単位のスナップショット(履歴ロジックは domain、画素保持は ui/application) | 履歴の遷移規則は pure Dart で検証し、重い画素は実体に委譲 |

## 差し替え境界とエントリーポイント

domain / core にインターフェース、data に本番実装、テストに fake を置く。

| 境界 | インターフェースの場所 | 本番実装 | テスト実装 |
| --- | --- | --- | --- |
| `Clock` | `core/` | システム時刻 | 固定・手動進行 fake |
| `Random` | (Dart 標準をそのまま注入) | 非決定 seed | 固定 seed |
| `GalleryStore` | `domain/gallery/` | path_provider 等でアプリ内保存 | インメモリ fake |
| `ImageExporter` | `domain/gallery/` | 端末保存 / 共有プラグイン | 記録のみの fake |

composition root は 3 つ。組み立てロジックは共通化し、差分(clock / seed / store)だけを変える。

- `lib/main.dart` — 本番構成。
- `lib/main_dev.dart` — 開発用(デバッグ向け設定があれば)。
- `lib/main_test.dart` — integration test 用。fake clock・固定 seed・インメモリ store で起動。

## フォルダ構成

```text
lib/
├── main.dart                 # 本番 composition root
├── main_dev.dart             # 開発用 composition root
├── main_test.dart            # integration test 用 composition root
└── src/
    ├── app.dart              # MaterialApp・テーマ適用・初期ビュー
    ├── core/
    │   └── clock.dart        # Clock インターフェースと SystemClock
    ├── domain/
    │   ├── color/
    │   │   └── ink_color.dart        # HSV/RGB/HEX 変換と現在色モデル
    │   ├── brush/
    │   │   ├── brush_preset.dart      # ink/pencil/marker/air のパラメータ
    │   │   └── stroke_planner.dart    # 2点+速度+brush+Random → スタンプ列
    │   ├── canvas/
    │   │   ├── layer.dart             # レイヤーのメタ(名前/visible/opacity)
    │   │   └── history.dart           # undo/redo スタックの遷移規則
    │   └── gallery/
    │       ├── sketch.dart            # スケッチのメタ(id/title/日時/サムネ参照)
    │       ├── gallery_store.dart     # 永続化インターフェース
    │       └── image_exporter.dart    # エクスポートインターフェース
    ├── data/
    │   ├── file_gallery_store.dart    # GalleryStore の永続化実装
    │   └── platform_image_exporter.dart # ImageExporter の実装
    ├── application/
    │   ├── dependencies.dart          # 差し替え境界の束(composition root が生成)
    │   ├── canvas_controller.dart     # ツール/ブラシ/サイズ/不透明度/色/レイヤー/履歴(ChangeNotifier)
    │   └── gallery_controller.dart    # スケッチ一覧の読み書き + 永続化(ChangeNotifier)
    └── ui/
        ├── theme/
        │   └── atelier_theme.dart     # デザイントークン(色・角丸・影・イージング)
        ├── gallery/
        │   ├── gallery_screen.dart
        │   └── piece_card.dart        # サムネイルカード
        ├── canvas/
        │   ├── canvas_screen.dart
        │   ├── draw_surface.dart      # CustomPainter によるレイヤー合成・ラスタライズ
        │   ├── topbar.dart            # 戻る/undo/redo/menu
        │   ├── tool_dock.dart         # ブラシ/スマッジ/消しゴム/レイヤー/カラー
        │   ├── v_slider.dart          # 縦スライダー(SIZE/OPAC)
        │   └── sheets/
        │       ├── color_sheet.dart   # HSV ピッカー・パレット・最近色
        │       ├── brush_sheet.dart   # ブラシ一覧 + プレビュー
        │       ├── layer_sheet.dart   # レイヤー一覧・追加・表示/削除
        │       └── menu_sheet.dart    # 保存/完了/レイヤー消去
        └── widgets/
            ├── brush_preview.dart     # ブラシの筆跡プレビュー
            ├── color_swatch.dart      # スウォッチ
            └── toast.dart             # トースト
```

ファイル名は実装時の目安。1 ファイルが肥大したら同じフォルダ内で分割してよいが、**フォルダの責務と依存方向は変えない**。

## テストのミラー構成

`test/` は `lib/src/` をミラーし、層ごとのフォルダに置く(`docs/test-plan.md` の対応表に従う)。

```text
test/
├── unit/
│   ├── color/            # HSV/RGB/HEX 変換
│   ├── brush/            # ストローク計画・速度→筆幅(固定 seed)
│   ├── canvas/           # レイヤー操作・undo/redo
│   └── gallery/          # 永続化の contract test(fake store)
├── widget/
│   ├── gallery/
│   └── canvas/           # ツール選択・スライダー・シート開閉・semantics
├── golden/               # ツールバー・ブラシプレビュー・カラーピッカー・レイヤー行
├── fixtures/             # 最小レイヤーセット・fake 実装(fake_clock, in_memory_gallery_store)
integration_test/
└── smoke_test.dart       # 起動→新規キャンバス→描画→保存→ギャラリー反映
```

fake は fixture と同様に共有資産として `test/fixtures/` に置き、各テストで重複定義しない。

## 依存ルールの守り方

- domain のファイルに `package:flutter` / `dart:ui` を import しない(pure Dart)。違反は `/harness-review` のレビュー観点に含まれる。
- ラスタライズ(`Canvas` 描画)は ui 層に閉じ込め、domain は「何をどこに描くか」の計画までを返す。
- ui から `data/` を import しない。必要な操作はすべて application の controller を経由する。
- ブラシの scatter / jitter や速度計算で、seed なし `Random()`・`DateTime.now()` 直叩き・`sleep` / 固定 `Future.delayed` を書かない。`Random` と `Clock` を注入する。
- 境界インターフェースにメソッドを足すときは、本番実装と `test/fixtures/` の fake の両方を同じ PR で更新する。

## このドキュメントの見直し時期

- 最初のキャンバス + ギャラリーが実装された後(構成が実態と合っているか)。
- 状態管理が `ChangeNotifier` で苦しくなったとき(Riverpod 移行判断)。
- 筆圧・共有・クラウド同期など新しい platform 要件が入るとき。
