# ADR 0001: スケッチの永続化方式

- 状態: 採用(実装済み: `lib/src/data/file_gallery_store.dart`)
- 日付: 2026-06-14

## 決定

ギャラリーのスケッチは **アプリ内ストレージにファイルとして保存**する。`GalleryStore` 境界(`lib/src/domain/gallery/gallery_store.dart`)の裏に隠し、本番実装はアプリのドキュメントディレクトリ(`path_provider`)に置く。

立ち上げ scope では **保存単位を「合成 PNG + メタデータ」**とし、レイヤー構造は保持しない。

- 画像: 合成済み PNG をファイルとして保存(例: `sketches/<id>.png`)。
- メタ: id / title(任意)/ createdAt / updatedAt を JSON のインデックス(`sketches/index_v1.json`)で管理する。

## 背景

`docs/product-spec.md` の未確定事項「永続化方式(レイヤーを保持するか、合成 PNG のみか)」を決める。プロトタイプは in-memory のみで、リロードで消える。候補:

| 候補 | 評価 |
| --- | --- |
| 合成 PNG のみ + JSON インデックス | 実装が軽い。ギャラリー表示と再開(背景として読み込み)に十分。再編集でレイヤーは失われる |
| レイヤーごとに PNG を保存し復元 | 再編集でレイヤーを保てるが、保存サイズ・I/O・スキーマが重くなる |
| 独自バイナリ / DB(sqlite, hive) | 大量データ・クエリ向け。ギャラリー数百点規模まで不要。依存とロックインが増える |

## 理由

- 立ち上げ時点のユーザー価値は「描いて、残して、一覧から開き直せる」こと。合成 PNG で満たせる。
- 依存を最小にする(`docs/architecture.md`「必要になるまで複雑にしない」)。レイヤー保持・クラウド同期は要求が出てから ADR を追加する。
- `GalleryStore` 境界の裏に隠れているため、レイヤー保持や DB へ移行する場合も実装ごと差し替えられる。その時点で新しい ADR を書く。

## 結果

- スキーマは **バージョン付きファイル名**(`index_v1.json`)で管理する。変更時は新バージョンへ移行コードを書く。
- 壊れた / 読めないインデックスは例外にせず空ギャラリーとして扱い、アプリは必ず起動できるようにする。
- 実装: `FileGalleryStore` は保存先ディレクトリを `resolveDir`(関数)で受け取る。本番は path_provider の `getApplicationDocumentsDirectory()` 配下(`hatch_sketches/`)、テストは `Directory.systemTemp` の一時ディレクトリを注入する。これにより contract test を path_provider なしの実ファイル I/O で回せる(`test/unit/gallery/file_gallery_store_test.dart`)。
- テストのロジック側は `GalleryStore` のインメモリ fake(`test/fixtures/in_memory_gallery_store`)も併用し、実ファイル I/O に依存させない。
- 端末の写真ライブラリへの書き出しはこの ADR の範囲外。`ImageExporter` 境界として分離し、本番は OS の共有シート経由(`lib/src/data/share_image_exporter.dart`、share_plus)。テストは記録のみの fake。
