import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  Map<String, AudioPool> soundPools = {};

  Future<void> initialize() async {
    await FlameAudio.audioCache.loadAll([
      'background_music.mp3',
      'laser.mp3',
      'explosion.mp3',
      'enemy_laser.mp3',
      'player_hit.mp3',
      'powerup.mp3',
      'game_over.mp3',
      'shield_hit.mp3'
    ]);

    soundPools['laser'] = await FlameAudio.createPool('laser.mp3', maxPlayers: 5);
    soundPools['enemy_laser'] = await FlameAudio.createPool('enemy_laser.mp3', maxPlayers: 5);
    soundPools['explosion'] = await FlameAudio.createPool('explosion.mp3', maxPlayers: 2);
  }

  void playSfx(String sfxName) {
    if (soundPools.containsKey(sfxName)) {
      soundPools[sfxName]?.start();
    } else {
      FlameAudio.play(sfxName);
    }
  }

  void playBackgroundMusic() {
    FlameAudio.bgm.play('background_music.mp3');
  }

  void stopBackgroundMusic() {
    FlameAudio.bgm.stop();
  }

  void dispose() {
    soundPools.values.forEach((pool) => pool.dispose());
    FlameAudio.bgm.stop();
  }
}