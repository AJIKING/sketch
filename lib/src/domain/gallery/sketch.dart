/// ギャラリーに並ぶ 1 枚のスケッチのメタ情報(pure Dart)。
///
/// 画像本体(PNG バイト列)はこのモデルに含めず、[GalleryStore] が id をキーに
/// 別管理する(ADR 0001: 合成 PNG + JSON インデックス)。
class Sketch {
  const Sketch({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });

  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sketch copyWith({String? title, DateTime? updatedAt}) => Sketch(
    id: id,
    title: title ?? this.title,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// インデックス(`index_v1.json`)用の JSON 表現。日時は ISO8601(UTC)。
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory Sketch.fromJson(Map<String, Object?> json) => Sketch(
    id: json['id']! as String,
    title: json['title'] as String?,
    createdAt: DateTime.parse(json['createdAt']! as String),
    updatedAt: DateTime.parse(json['updatedAt']! as String),
  );
}
