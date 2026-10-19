import 'package:audioplayers/audioplayers.dart';

import '../persist/save.dart';

class GroveAudio {
  GroveAudio(this.save);

  final GroveSave save;
  final List<AudioPlayer> _sfx = List.generate(4, (_) => AudioPlayer());
  final AudioPlayer _music = AudioPlayer();
  int _cursor = 0;
  bool _musicOn = false;

  Future<void> play(String name) async {
    if (!save.sfx) return;
    final player = _sfx[_cursor];
    _cursor = (_cursor + 1) % _sfx.length;
    try {
      await player.stop();
      await player.play(AssetSource('sfx/$name.wav'));
    } catch (_) {}
  }

  Future<void> syncMusic() async {
    try {
      if (save.music && !_musicOn) {
        await _music.setReleaseMode(ReleaseMode.loop);
        await _music.setVolume(0.28);
        await _music.play(AssetSource('sfx/pad.wav'));
        _musicOn = true;
      } else if (!save.music && _musicOn) {
        await _music.stop();
        _musicOn = false;
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    for (final player in _sfx) {
      await player.dispose();
    }
    await _music.dispose();
  }
}
