# Hatch — テスト計画

`docs/harness-engineering.md` の方針を `docs/product-spec.md` の仕様に適用した具体計画。新しい機能を実装するときは、この表に対応する層のテストを同じ PR に含める。

## 差し替え境界の具体化

ハーネス方針の差し替え対象候補を、このアプリでは次のとおり具体化する。

| 境界 | このアプリでの用途 | 既定実装 / テスト実装 |
| --- | --- | --- |
| `Clock` | ストローク速度→筆幅、スケッチの保存時刻 | システム時刻 / 固定・手動進行の fake |
| `Random` | ブラシの scatter / jitter、サンプルサムネイル生成 | 非決定 seed / **seed 注入で決定的に** |
| `GalleryStore` | スケッチ一覧の永続化(サムネイル / メタ) | アプリ内ストレージ / インメモリ fake |
| `ImageExporter` | PNG エクスポート / 端末への保存 | プラットフォーム実装 / 記録のみの fake(許可拒否も再現) |

`ApiClient` は通信がないため不要。端末への画像保存で OS 権限が必要になる場合は `ImageExporter` 境界に含める(独立した `PermissionGateway` は置かない)。

ブラシの散らしと筆致はプロトタイプの `Math.random()` / `performance.now()` 直叩きを踏襲しない。`Random(seed)` と `Clock` を注入し、失敗時に seed をログへ出す。

## Unit test(`test/unit/`)

| 対象 | 守る振る舞い |
| --- | --- |
| 色変換 | HSV→RGB→HEX の往復一致 / 境界値(h=0/360, s=0, v=0/1) / HEX パース(大文字小文字・# 有無) |
| 現在色・最近色 | 色選択で最近色へ追加 / 重複は先頭へ寄せる / 最大 8 件で打ち切り |
| パレット | Studio Palette 10 色の値が仕様どおり |
| ストローク計画(ink/marker) | 2 点間を補間して線分を生成 / 速度が速いほど ink の筆幅が細る(`clamp(1.15−speed×0.9, 0.4, 1)`) |
| ストローク計画(pencil/air) | spacing 間隔でダブを配置 / ダブ数 = `max(1, floor(dist/step))` / scatter は固定 seed で再現可能 |
| ブラシプリセット | ink/pencil/marker/air の flow/soft/scatter/spacing が仕様どおり |
| レイヤー操作 | 追加で末尾に visible・opacity=1 の新レイヤー / アクティブ切替 / 非表示切替 / 削除(最後の 1 枚は不可)/ 削除後の active index 補正 |
| 合成順序 | 表示レイヤーのみを下から順、各 opacity で重ねる順序が正しい |
| undo/redo | ストローク開始でスナップショットを積む / 最大 16 件で古いものを破棄 / 新規ストロークで redo クリア / undo→redo の往復でレイヤーが復元される / 対象レイヤー index を保持 |
| サイズ / 不透明度 | SIZE 1–80・OPAC 0–100% のクランプと既定値(14 / 100%) |
| エクスポート計画 | 合成結果のサイズ(要素 × DPR, DPR は最大 2)/ ファイル名規則 |

## Widget test(`test/widget/`)

| 対象 | 守る振る舞い |
| --- | --- |
| ギャラリー | スケッチ点数表示 / 「新規キャンバス」でキャンバスへ / サムネイルタップで該当スケッチを開く / 0 点時の表示 |
| キャンバス遷移 | ギャラリー→キャンバスのスライドアップ / 戻るで保存してギャラリーへ |
| ツールドック | ブラシ/スマッジ/消しゴムの選択状態(aria-pressed 相当の semantics)/ アクティブなブラシ再タップでブラシシートが開く |
| 縦スライダー | ドラッグ / キーボードで値が変わりバブル表示が追従 / クランプ |
| カラーシート | SV・Hue 操作で HEX とチップが更新 / パレット選択 / 最近色への反映 / アクセント色追従 |
| ブラシシート | 4 ブラシの一覧表示 / 選択でチェックとツールがブラシに戻る |
| レイヤーシート | 追加でバッジ増 / 表示トグル / 削除と最後の 1 枚の保護トースト / アクティブ切替の反映 |
| メニューシート | 保存 / 完了でギャラリーへ / レイヤー消去(undo 可能)|
| undo/redo | スタックが空のとき disabled / 描画後に有効化 |
| 非表示レイヤー描画 | 非表示レイヤー選択中の描画でトースト表示・画素が変わらない |
| Semantics | スライダー・主要ボタン・スウォッチに意味ラベルがある |

widget test では animation を `pumpAndSettle` または明示 `pump` で進め、実時間 `sleep` を使わない。トーストの表示時間(約 1.6 秒)も fake 化した時間で検証する。

## Golden test(`test/golden/`)

対象:

- ツールドック(各ツールの選択状態)。
- ブラシプレビュー(ink / pencil / marker / air の筆跡。固定 seed で生成)。
- カラーピッカー(SV/Hue・パレット・チップ)。
- レイヤー行(アクティブ / 非表示 / 通常)。

固定条件: device size、text scale 1.0、locale ja、theme(アトリエ暗色固定)、カスタムフォントをテスト内でロード。基準 platform は CI(Linux)— 詳細は `docs/harness-engineering.md` の Golden 方針と ADR 0002(`docs/design-docs/0002-golden-test-operations.md`)。

**ユーザーの自由描画キャンバスは golden 対象にしない**(非決定。価値が低い)。ブラシプレビューのように固定 seed・固定入力で決定的に再生成できるものに限る。

運用: golden test は `@Tags(['golden'])` 付きで、非 Linux では自動 skip する。baseline は `.github/workflows/golden.yml` を workflow_dispatch で生成し、artifact を `test/golden/goldens/` に展開してコミットする(ADR 0002)。check.yml の `golden` job が PR / main push ごとに比較する。

## Integration smoke(`integration_test/`)

journey: 起動 → ギャラリー → 「新規キャンバス」→ 数ストローク描画 → 「完了してギャラリーへ」→ ギャラリーに点数が増えていることを確認。

- エントリーポイントは `lib/main_test.dart` を用意し、fake clock・固定 seed・インメモリ store を注入して起動する。
- 実行はエミュレータ / シミュレータが必要(`flutter test integration_test` は端末上で動く)。CI へは main branch 段階で導入し、PR では必須にしない(`.github/workflows/integration.yml`)。

## Fixture(`test/fixtures/`)

- 最小レイヤーセット(空 1 枚 / 描画済み 1 枚)。
- 既知のストローク列(2〜3 点)で固定 seed の描画計画を検証する。
- fake 実装(`fake_clock`, `in_memory_gallery_store`, `recording_image_exporter`)。命名は「複数行の…」ではなく検証したい振る舞いで付ける。

## 実装順(ハーネス先行)

1. 色変換 + ブラシ/ストローク計画 + unit test(UI なしで最初の green を作る)。
2. レイヤー / 履歴(undo/redo)+ unit test。
3. 状態管理(canvas_controller / gallery_controller)+ unit test。
4. 画面実装(ギャラリー / キャンバス / 各シート)+ widget test。
5. golden test(共有コンポーネントが安定してから)。
6. integration smoke + `main_test.dart`。
