/// Sound effects and one menu loop. Ids name the bundled files.
abstract class AudioPort {
  Future<void> preload(List<String> ids);

  Future<void> play(String id, {double volume = 1});

  Future<void> startLoop(String id, {double volume = 0.5});

  Future<void> stopLoop();

  /// Mutes every effect and the loop.
  void setMuted(bool muted);
}
