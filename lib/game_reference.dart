import 'package:flame/components.dart';
import 'space_shooter_game.dart';
import 'game_state_manager.dart';
import 'audio_manager.dart';

mixin GameRef on Component {
  SpaceShooterGame? _cachedGame;

  SpaceShooterGame get game {
    if (_cachedGame == null) {
      var current = parent;
      while (current != null) {
        if (current is SpaceShooterGame) {
          _cachedGame = current;
          break;
        }
        current = current.parent;
      }
    }
    return _cachedGame!;
  }

  GameStateManager get gameState => game.gameStateManager;
  AudioManager get audio => game.audioManager;
}