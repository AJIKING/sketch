# sketch(Hatch — ポケットのアトリエ)

スマホ向けの軽量スケッチ/お絵描き Flutter アプリ。オフライン完結・バックエンドなし。

- プロダクト仕様: `docs/product-spec.md`(プロトタイプ `docs/prototype/hatch-sketch-app.html` 準拠)
- アーキテクチャ: `docs/architecture.md`(レイヤー構成・フォルダ構成・依存ルール。コードを置く場所はここに従う)
- テスト計画: `docs/test-plan.md`(機能 × テスト層の対応表。実装時はここに従う)
- ハーネス方針: `docs/harness-engineering.md`(品質ゲート、flaky ポリシー、CI 設計の正典)

## 環境

- Flutter SDK: **3.44.1**(`.fvmrc` で固定。CI も同バージョン)
- FVM がインストールされている環境では `fvm flutter ...` を使う。なければ `flutter` を直接使う。
- 対象プラットフォーム: Android / iOS。

## 基本コマンド

| 目的 | コマンド |
| --- | --- |
| 依存解決 | `flutter pub get` |
| フォーマットチェック | `dart format --output=none --set-exit-if-changed .` |
| フォーマット適用 | `dart format .` |
| 静的解析 | `flutter analyze` |
| 全テスト | `flutter test --reporter expanded` |
| golden 更新 | `flutter test --update-goldens` |

CI(`.github/workflows/check.yml`)は format → analyze → test の順で実行する。PR を出す前にローカルで同じ 3 つを通すこと(`/check` コマンドで一括実行できる)。

## テスト方針(要約)

- **TDD で進める**: 実装より先に失敗するテストを書く(red → green → refactor)。テストのない実装変更を完了として報告しない。バグ修正はまず再現テストを書いてから直す。
- 配置: unit は `test/unit/`、widget は `test/widget/`、golden は `test/golden/`、再利用 fixture は `test/fixtures/`。
- PR では unit / widget test が必須。golden は UI 基盤・デザイン変更時のみ。integration は main / release で実行。
- テストは実時間・前回の端末状態・外部サービスに依存させない。`Clock`、`Random`、`GalleryStore` などは差し替え可能な境界で fake にする。
- 描画(Canvas)のロジックは pure Dart の `domain` 層に寄せ、`Random(seed)` を注入して決定的にする。プロトタイプの `Math.random()` 直叩きは踏襲しない。

## Golden / flaky ポリシー(要約)

- golden test では device size / text scale / theme / locale / font loading を固定する。golden 画像は platform 依存のため、基準 platform は CI と同じ Linux。**Windows のこの環境では platform 差由来の golden 失敗を理由に `--update-goldens` しない。** golden test はタグ `golden` 付きで、Windows では自動 skip される(ADR 0002)。
- flaky はハーネスの欠陥として扱う。**理由を残さずテストを削除しない。timeout を安易に伸ばさない。sleep より明示的な同期を使う。** quarantine する場合は必ず issue link を付ける。詳細は `docs/harness-engineering.md` の「Flaky Test ポリシー」。

## コーディング規約

- lint は `analysis_options.yaml`(flutter_lints ベース)に従う。lint を黙らせる `// ignore:` は理由コメント必須。
- 生成ファイルや golden 画像以外で `flutter analyze` の warning を増やさない。

## Claude Code ハーネス

- スラッシュコマンド: `/check`(CI 相当のローカル検証)、`/golden`(golden の検証・更新)、`/flaky`(flaky test の triage)、`/harness-review`(差分をハーネス方針と照合)
- サブエージェント: `flutter-implementer`(機能実装。TDD と依存ルールを遵守)、`flutter-test-writer`(テスト作成)、`flaky-triager`(flaky 調査)、`harness-reviewer`(品質ゲートレビュー)
