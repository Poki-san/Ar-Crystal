import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../crystallizer/domain/entities/wearable.dart';

class WearableRepository {
  static const String _collectionFileName = 'wearable_collection.json';
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Future<File> _collectionFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_collectionFileName');
  }

  /*
   * Коллекция хранится рядом с исходными фото и аудио. Файл подходит для
   * пользовательских данных лучше SharedPreferences и не зависит от сети.
   */
  Future<List<Wearable>> loadCollection() async {
    final File file = await _collectionFile();
    if (!await file.exists()) return DemoWearables.owned;
    try {
      final String stored = await file.readAsString();
      if (stored.isEmpty) return DemoWearables.owned;
      final List<Object?> decoded = jsonDecode(stored) as List<Object?>;
      return decoded
          .map(
            (Object? item) => Wearable.fromJson(
              Map<String, Object?>.from(item! as Map<Object?, Object?>),
            ),
          )
          .toList();
    } on Object {
      /* Повреждённый файл не должен блокировать запуск локальной галереи. */
      return DemoWearables.owned;
    }
  }

  /*
   * Сохраняет новый предмет первым в списке и заменяет запись с тем же id.
   * revision уведомляет открытый экран коллекции без глобального state manager.
   */
  Future<void> save(Wearable wearable) async {
    final List<Wearable> current = await loadCollection();
    final List<Wearable> updated = <Wearable>[
      wearable,
      ...current.where((Wearable item) => item.id != wearable.id),
    ];
    final File file = await _collectionFile();
    await file.writeAsString(
      jsonEncode(updated.map((Wearable item) => item.toJson()).toList()),
      flush: true,
    );
    revision.value++;
  }
}
