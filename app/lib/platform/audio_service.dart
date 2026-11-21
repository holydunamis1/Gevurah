import 'package:flame_audio/flame_audio.dart';

import '../core/ports/audio_port.dart';
import '../core/ports/log_port.dart';

/// The calls the service needs from an audio engine.
abstract class AudioDriver {
  Future<void> load(List<String> paths);

  Future<void> play(String path, double volume);

  Future<void> startLoop(String path, double volume);

  Future<void> stopLoop();
}

/// flame_audio underneath. Assets are addressed by their full path.
class FlameAudioDriver implements AudioDriver {
  FlameAudioDriver() {
    FlameAudio.audioCache.prefix = '';
  }

  @override
  Future<void> load(List<String> paths) async {
    await FlameAudio.audioCache.loadAll(paths);
  }

  @override
  Future<void> play(String path, double volume) async {
    await FlameAudio.play(path, volume: volume);
  }

  @override
  Future<void> startLoop(String path, double volume) async {
    await FlameAudio.bgm.play(path, volume: volume);
  }

  @override
  Future<void> stopLoop() async {
    await FlameAudio.bgm.stop();
  }
}

/// Effects and one menu loop. A missing file or a failing engine is logged
/// and ignored: sound is never worth a crash.
class AudioService implements AudioPort {
  AudioService({AudioDriver? driver, this.log, this.basePath = 'assets/audio/', this.extension = '.wav'})
      : _driver = driver ?? FlameAudioDriver();

  final AudioDriver _driver;
  final LogPort? log;
  final String basePath;
  final String extension;

  bool _muted = false;

  String _path(String id) => '$basePath$id$extension';

  Future<void> _safe(String what, Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e) {
      log?.log(LogLevel.warning, 'Audio $what failed', error: e);
    }
  }

  @override
  Future<void> preload(List<String> ids) => _safe('preload', () => _driver.load(ids.map(_path).toList()));

  @override
  Future<void> play(String id, {double volume = 1}) async {
    if (_muted) {
      return;
    }
    await _safe('play $id', () => _driver.play(_path(id), volume.clamp(0.0, 1.0)));
  }

  @override
  Future<void> startLoop(String id, {double volume = 0.5}) async {
    if (_muted) {
      return;
    }
    await _safe('loop $id', () => _driver.startLoop(_path(id), volume.clamp(0.0, 1.0)));
  }

  @override
  Future<void> stopLoop() => _safe('stop loop', _driver.stopLoop);

  @override
  void setMuted(bool muted) {
    _muted = muted;
    if (muted) {
      _safe('stop loop', _driver.stopLoop);
    }
  }
}
