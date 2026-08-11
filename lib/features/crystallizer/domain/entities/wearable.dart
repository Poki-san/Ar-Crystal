import 'package:flutter/material.dart';

enum WearableKind { tshirt, hoodie, dress, sneakers }

extension WearableKindPresentation on WearableKind {
  String get label => switch (this) {
    WearableKind.tshirt => 'ФУТБОЛКА',
    WearableKind.hoodie => 'ХУДИ',
    WearableKind.dress => 'ПЛАТЬЕ',
    WearableKind.sneakers => 'КЕДЫ',
  };
}

/*
 * Локальная модель цифровой одежды. Она не зависит от UI и содержит только
 * сериализуемые метаданные и пути к файлам внутри каталога приложения.
 */
class Wearable {
  const Wearable({
    required this.id,
    required this.name,
    required this.kind,
    required this.palette,
    required this.seed,
    required this.price,
    required this.creator,
    required this.likes,
    this.isOwned = false,
    this.imagePath,
    this.audioPath,
    this.createdAt,
  });

  final String id;
  final String name;
  final WearableKind kind;
  final List<Color> palette;
  final int seed;
  final double price;
  final String creator;
  final int likes;
  final bool isOwned;
  final String? imagePath;
  final String? audioPath;
  final DateTime? createdAt;

  /* Подготавливает модель для хранения в SharedPreferences как JSON. */
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'kind': kind.name,
    'palette': palette.map((Color color) => color.toARGB32()).toList(),
    'seed': seed,
    'price': price,
    'creator': creator,
    'likes': likes,
    'isOwned': isOwned,
    'imagePath': imagePath,
    'audioPath': audioPath,
    'createdAt': createdAt?.toIso8601String(),
  };

  /* Восстанавливает локально сохранённый предмет без сетевых запросов. */
  factory Wearable.fromJson(Map<String, Object?> json) {
    final List<Object?> colors = json['palette']! as List<Object?>;
    return Wearable(
      id: json['id']! as String,
      name: json['name']! as String,
      kind: WearableKind.values.byName(json['kind']! as String),
      palette: colors.map((Object? value) => Color(value! as int)).toList(),
      seed: json['seed']! as int,
      price: (json['price']! as num).toDouble(),
      creator: json['creator']! as String,
      likes: json['likes']! as int,
      isOwned: json['isOwned']! as bool,
      imagePath: json['imagePath'] as String?,
      audioPath: json['audioPath'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt']! as String),
    );
  }
}

abstract final class DemoWearables {
  static const List<Wearable> owned = <Wearable>[
    Wearable(
      id: '01',
      name: 'EMBER SKIN',
      kind: WearableKind.hoodie,
      palette: <Color>[Color(0xFFFF7A40), Color(0xFF70291F), Color(0xFFD8FF63)],
      seed: 18,
      price: 42,
      creator: 'YOU',
      likes: 128,
      isOwned: true,
    ),
    Wearable(
      id: '02',
      name: 'GLACIER 04',
      kind: WearableKind.tshirt,
      palette: <Color>[Color(0xFF80FFF4), Color(0xFF156B78), Color(0xFF8E6CFF)],
      seed: 31,
      price: 29,
      creator: 'YOU',
      likes: 87,
      isOwned: true,
    ),
    Wearable(
      id: '03',
      name: 'NIGHT BLOOM',
      kind: WearableKind.dress,
      palette: <Color>[Color(0xFFDF6CFF), Color(0xFF42175A), Color(0xFFFF6B3D)],
      seed: 7,
      price: 68,
      creator: 'YOU',
      likes: 211,
      isOwned: true,
    ),
  ];

  static const List<Wearable> market = <Wearable>[
    Wearable(
      id: '17',
      name: 'SALT SIGNAL',
      kind: WearableKind.sneakers,
      palette: <Color>[Color(0xFFE8E7D6), Color(0xFF53605E), Color(0xFFD8FF63)],
      seed: 47,
      price: 50,
      creator: 'NORA.X',
      likes: 364,
    ),
    Wearable(
      id: '22',
      name: 'MOLTEN AIR',
      kind: WearableKind.dress,
      palette: <Color>[Color(0xFFFF6B3D), Color(0xFFFFC764), Color(0xFF5A1A24)],
      seed: 66,
      price: 74,
      creator: 'KAI.WAV',
      likes: 892,
    ),
    Wearable(
      id: '29',
      name: 'DEEP STATIC',
      kind: WearableKind.hoodie,
      palette: <Color>[Color(0xFF4B51FF), Color(0xFF141B52), Color(0xFF5BE7E2)],
      seed: 12,
      price: 38,
      creator: '0XIRIS',
      likes: 451,
    ),
    Wearable(
      id: '31',
      name: 'MOSS CODE',
      kind: WearableKind.tshirt,
      palette: <Color>[Color(0xFFBCE45A), Color(0xFF26553E), Color(0xFFFFE0A3)],
      seed: 83,
      price: 32,
      creator: 'YUMA',
      likes: 276,
    ),
  ];
}
