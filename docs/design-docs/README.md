# design-docs(ADR)

将来覆す可能性のある設計上の決定を Architecture Decision Record(ADR)として記録する。

- 1 決定 = 1 ファイル。連番 + 内容がわかるファイル名(`NNNN-topic.md`)。
- 各 ADR は「決定 / 背景(検討した候補)/ 理由 / 結果(決定がもたらす制約・運用)」を簡潔に書く。
- 決定を覆すときは、旧 ADR を書き換えるのではなく新しい ADR を追加して旧 ADR から参照する(経緯を残す)。

## 一覧

| 番号 | タイトル | 状態 |
| --- | --- | --- |
| [0001](0001-sketch-persistence.md) | スケッチの永続化方式 | 採用(実装済み) |
| [0002](0002-golden-test-operations.md) | golden test の基準 platform と baseline 運用 | 採用 |
| [0003](0003-drawing-determinism.md) | 描画の決定性(乱数 seed と時間源の注入) | 採用 |
| [0004](0004-raster-canvas-engine.md) | ラスター(ピクセル)キャンバスエンジンへの移行 | 採用 |
| [0005](0005-vector-layers.md) | ベクターレイヤー(再編集可能なオブジェクト層) | 採用(段階導入) |
| [0006](0006-fixed-resolution-document.md) | 固定解像度ドキュメント(キャンバスサイズの選択) | 採用(段階導入) |
| [0007](0007-layer-mask.md) | レイヤーマスク(非破壊の可視範囲制御) | 採用(段階導入) |
| [0008](0008-text-fonts.md) | テキストの多書体(google_fonts)とオフライン方針の緩和 | 採用 |
