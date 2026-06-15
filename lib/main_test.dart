import 'package:flutter/material.dart';

import 'src/app.dart';

/// integration test 用 composition root(`docs/test-plan.md`「Integration smoke」)。
///
/// 本来は fake clock・固定 seed の `Random`・インメモリ `GalleryStore` を注入して
/// 毎回まっさらな状態で起動する。スケルトン段階では本番と同じ起動だが、
/// 境界が増えたらここで test 用実装に差し替える。
void main() {
  runApp(const RakugaApp());
}
