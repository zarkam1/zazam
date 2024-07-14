import 'package:flame/components.dart';

import 'space_shooter_game.dart';

class GameStateManager extends Component with HasGameRef<SpaceShooterGame> {
  GameState _state = GameState.menu;
  int _enemiesPassed = 0;
  int _enemiesSpawned = 0;
  int _score = 0;
  static const int maxEnemiesPassed = 5;

  GameState get state => _state;
  int get enemiesPassed => _enemiesPassed;
  int get enemiesSpawned => _enemiesSpawned;
  int get score => _score;

  set state(GameState newState) {
    if (_state != newState) {
      print('Game State changed from $_state to $newState');
      _state = newState;
      _handleStateChange();
    }
  }

  void _handleStateChange() {
    switch (_state) {
      case GameState.menu:
      print('GameStateManager: Attempting to add MenuComponent');
      gameRef.add(MenuComponent());
      print('GameStateManager: MenuComponent added');
        break;
      case GameState.playing:
        gameRef.children.whereType<MenuComponent>().forEach((menu) => menu.removeFromParent());
        gameRef.uiManager.initializeGameUI();
        break;
      case GameState.gameOver:
        gameRef.add(GameOverComponent(score: _score));
        break;
    }
  }

   void startGame() {
    print('Starting game');
    _enemiesPassed = 0;
    _enemiesSpawned = 0;
    _score = 0;
    state = GameState.playing;
    if (isMounted) {
      gameRef.audioManager.playBackgroundMusic();
      gameRef.enemyManager.reset();
      gameRef.player.reset();
      gameRef.uiManager.reset();
    }
    print('Game started');
  }


  void gameOver() {
  print('Game over');
  state = GameState.gameOver;
  gameRef.audioManager.stopBackgroundMusic();
  gameRef.audioManager.playSfx('game_over.mp3');
  //gameRef.pauseEngine();  // This will pause the game
   gameRef.add(GameOverComponent(score: _score));
}
 void resetGame() {
  print('GameStateManager: Resetting game');
  _enemiesPassed = 0;
  _enemiesSpawned = 0;
  _score = 0;
  state = GameState.playing;  // Set the state before resetting the game
  gameRef.resetGame();
  //gameRef.audioManager.playBackgroundMusic();
  print('GameStateManager: Game reset and started');
}

 void enemyPassed() {
  _enemiesPassed++;
  print('Enemy passed. Total: $_enemiesPassed');
  gameRef.uiManager.updateEnemiesPassed(_enemiesPassed);
  gameRef.audioManager.updateMusicSpeed();
  if (_enemiesPassed >= maxEnemiesPassed) {
    gameOver();
  }
}

  void enemySpawned() {
    _enemiesSpawned++;
    print('Enemy spawned. Total: $_enemiesSpawned');
  }

  void increaseScore(int points) {
    _score += points;
    print('Score increased. New score: $_score');
    gameRef.uiManager.updateScore(_score);
  }
}