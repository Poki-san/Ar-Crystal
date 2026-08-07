import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class CaptureResult {
  const CaptureResult({
    required this.imagePath,
    required this.audioPath,
    required this.palette,
    required this.seed,
  });

  final String imagePath;
  final String audioPath;
  final List<Color> palette;
  final int seed;
}

class CaptureService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<CaptureResult> capture(CameraController camera) async {
    if (!await _recorder.hasPermission()) {
      throw CameraException(
        'MicrophoneAccessDenied',
        'Нет доступа к микрофону',
      );
    }
    final Directory directory = await getApplicationDocumentsDirectory();
    final Directory captures = Directory('${directory.path}/captures');
    if (!captures.existsSync()) captures.createSync(recursive: true);
    final int stamp = DateTime.now().millisecondsSinceEpoch;
    final String audioPath = '${captures.path}/echo_$stamp.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: audioPath,
    );
    final XFile shot = await camera.takePicture();
    final String imagePath = '${captures.path}/texture_$stamp.jpg';
    await File(shot.path).copy(imagePath);
    await Future<void>.delayed(const Duration(seconds: 3));
    final String? recordedPath = await _recorder.stop();
    final Uint8List bytes = await File(imagePath).readAsBytes();
    final _ImageFingerprint fingerprint = await compute(_analyzeImage, bytes);
    final Uint8List audioBytes = await File(
      recordedPath ?? audioPath,
    ).readAsBytes();
    final int audioEnergy = await compute(_analyzeAudioEnergy, audioBytes);
    return CaptureResult(
      imagePath: imagePath,
      audioPath: recordedPath ?? audioPath,
      palette: fingerprint.colors.map(Color.new).toList(),
      seed: math.max(1, (fingerprint.seed + audioEnergy) % 997),
    );
  }

  void dispose() => _recorder.dispose();
}

class _ImageFingerprint {
  const _ImageFingerprint(this.colors, this.seed);
  final List<int> colors;
  final int seed;
}

_ImageFingerprint _analyzeImage(Uint8List bytes) {
  final image_lib.Image? decoded = image_lib.decodeImage(bytes);
  if (decoded == null) {
    return const _ImageFingerprint(<int>[
      0xFFD8FF63,
      0xFF306859,
      0xFFFF6B3D,
    ], 91);
  }
  final image_lib.Image sample = image_lib.copyResize(decoded, width: 48);
  final Map<int, int> buckets = <int, int>{};
  for (int y = 0; y < sample.height; y += 2) {
    for (int x = 0; x < sample.width; x += 2) {
      final image_lib.Pixel pixel = sample.getPixel(x, y);
      final int red = (pixel.r.toInt() ~/ 48) * 48;
      final int green = (pixel.g.toInt() ~/ 48) * 48;
      final int blue = (pixel.b.toInt() ~/ 48) * 48;
      final int color = 0xFF000000 | (red << 16) | (green << 8) | blue;
      buckets[color] = (buckets[color] ?? 0) + 1;
    }
  }
  int edgeEnergy = 0;
  for (int y = 1; y < sample.height - 1; y += 2) {
    for (int x = 1; x < sample.width - 1; x += 2) {
      int luminance(int px, int py) {
        final image_lib.Pixel p = sample.getPixel(px, py);
        return (p.r.toInt() * 299 +
                p.g.toInt() * 587 +
                p.b.toInt() * 114) ~/
            1000;
      }

      final int gx =
          -luminance(x - 1, y - 1) +
          luminance(x + 1, y - 1) -
          2 * luminance(x - 1, y) +
          2 * luminance(x + 1, y) -
          luminance(x - 1, y + 1) +
          luminance(x + 1, y + 1);
      final int gy =
          -luminance(x - 1, y - 1) -
          2 * luminance(x, y - 1) -
          luminance(x + 1, y - 1) +
          luminance(x - 1, y + 1) +
          2 * luminance(x, y + 1) +
          luminance(x + 1, y + 1);
      edgeEnergy += gx.abs() + gy.abs();
    }
  }
  final List<MapEntry<int, int>> ranked = buckets.entries.toList()
    ..sort(
      (MapEntry<int, int> a, MapEntry<int, int> b) =>
          b.value.compareTo(a.value),
    );
  final List<int> colors = ranked.take(3).map((entry) => entry.key).toList();
  while (colors.length < 3) {
    colors.add(<int>[0xFFD8FF63, 0xFFFF6B3D, 0xFF5BE7E2][colors.length]);
  }
  return _ImageFingerprint(colors, math.max(1, edgeEnergy % 997));
}

int _analyzeAudioEnergy(Uint8List bytes) {
  if (bytes.length <= 44) return 0;
  int energy = 0;
  int count = 0;
  for (int offset = 44; offset + 1 < bytes.length; offset += 64) {
    int sample = bytes[offset] | (bytes[offset + 1] << 8);
    if (sample >= 0x8000) sample -= 0x10000;
    energy += sample.abs();
    count++;
  }
  return count == 0 ? 0 : (energy ~/ count) % 997;
}
