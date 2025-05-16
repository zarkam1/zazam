import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';

import 'space_shooter_game.dart';

class AudioManager extends Component with HasGameRef<SpaceShooterGame> {
  Map<String, AudioPool> soundPools = {};


 double _musicPlaybackRate = 1.0;
  Future<void> initialize() async {
    try {
      print('AudioManager: Initializing audio...');
      
      // List of all sound files to load
      final soundFiles = [
        'background_music.mp3',
        'laser.mp3',
        'explosion.mp3',
        'enemy_laser.mp3',
        'player_hit.mp3',
        'powerup.mp3',
        'game_over.mp3',
        'shield_hit.mp3'
      ];
      
      // Load each sound file individually with error reporting
      for (final soundFile in soundFiles) {
        try {
          await FlameAudio.audioCache.load(soundFile);
          print('Successfully loaded audio: $soundFile');
        } catch (e) {
          print('ERROR loading audio: $soundFile - $e');
          // Continue loading other files even if one fails
        }
      }
      
      // Create audio pools with error handling
      try {
        soundPools['laser'] = await FlameAudio.createPool('laser.mp3', maxPlayers: 5);
        print('Created audio pool: laser');
      } catch (e) {
        print('ERROR creating laser pool: $e');
      }
      
      try {
        soundPools['enemy_laser'] = await FlameAudio.createPool('enemy_laser.mp3', maxPlayers: 5);
        print('Created audio pool: enemy_laser');
      } catch (e) {
        print('ERROR creating enemy_laser pool: $e');
      }
      
      try {
        soundPools['explosion'] = await FlameAudio.createPool('explosion.mp3', maxPlayers: 2);
        print('Created audio pool: explosion');
      } catch (e) {
        print('ERROR creating explosion pool: $e');
      }
      
      print('AudioManager: Initialization complete');
    } catch (e) {
      print('ERROR in AudioManager initialization: $e');
    }
  }

  void playSfx(String sfxName) {
    try {
      if (soundPools.containsKey(sfxName)) {
        soundPools[sfxName]?.start();
        print('Playing sound from pool: $sfxName');
      } else {
        FlameAudio.play(sfxName);
        print('Playing sound directly: $sfxName');
      }
    } catch (e) {
      print('ERROR playing sound effect $sfxName: $e');
    }
  }

 void playBackgroundMusic() {
    FlameAudio.bgm.play('background_music.mp3', volume: 0.5);
    updateMusicSpeed();
  }
 void updateMusicSpeed() {
    if (!isMounted) return;  // Add this check
  _musicPlaybackRate = 1.0 + (gameRef.gameStateManager.enemiesPassed * 0.1).clamp(0.0, 1.0);
  FlameAudio.bgm.audioPlayer.setPlaybackRate(_musicPlaybackRate);
}
  void stopBackgroundMusic() {
    FlameAudio.bgm.stop();
  }

  void dispose() {
    soundPools.values.forEach((pool) => pool.dispose());
    FlameAudio.bgm.stop();
  }
}