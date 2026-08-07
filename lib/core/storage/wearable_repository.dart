import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/wearable.dart';

class WearableRepository {
  WearableRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _collectionKey = 'echo_wear.collection.v1';
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  final SharedPreferencesAsync _preferences;

  Future<List<Wearable>> loadCollection() async {
    final String? stored = await _preferences.getString(_collectionKey);
    if (stored == null || stored.isEmpty) return DemoWearables.owned;
    try {
      final List<Object?> decoded = jsonDecode(stored) as List<Object?>;
      return decoded
          .map(
            (Object? item) => Wearable.fromJson(
              Map<String, Object?>.from(item! as Map<Object?, Object?>),
            ),
          )
          .toList();
    } on FormatException {
      return DemoWearables.owned;
    }
  }

  Future<void> save(Wearable wearable) async {
    final List<Wearable> current = await loadCollection();
    final List<Wearable> updated = <Wearable>[
      wearable,
      ...current.where((Wearable item) => item.id != wearable.id),
    ];
    await _preferences.setString(
      _collectionKey,
      jsonEncode(updated.map((Wearable item) => item.toJson()).toList()),
    );
    revision.value++;
  }
}
