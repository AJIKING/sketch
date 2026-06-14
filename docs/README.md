# docs

| ドキュメント | 内容 |
| --- | --- |
| [product-spec.md](product-spec.md) | 今回開発するスケッチアプリ「Hatch」の仕様。プロトタイプ `prototype/hatch-sketch-app.html` から抽出 |
| [architecture.md](architecture.md) | Flutter アーキテクチャとフォルダ構成(レイヤー、差し替え境界の配置、依存ルール) |
| [test-plan.md](test-plan.md) | ハーネス方針を本アプリに適用した具体的なテスト計画 |
| [harness-engineering.md](harness-engineering.md) | ハーネスエンジニアリングの全体方針(レイヤー、品質ゲート、flaky ポリシー、CI 設計) |
| [design-docs/](design-docs/) | ADR(設計上の決定の記録)。永続化方式などの未確定事項の決定はここに残す |
| [prototype/](prototype/) | HTML プロトタイプ |

読む順序: 仕様を知りたいなら product-spec → 実装するなら architecture → テストを書くなら test-plan → 方針の根拠は harness-engineering。
