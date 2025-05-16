import 'package:flame/components.dart';
import 'space_shooter_game.dart';
import 'level_management.dart';

class GameStateManager extends Component with HasGameRef<SpaceShooterGame> {
  void pauseGame() {
    if (_state == GameState.playing && isMounted) {
      print('Pausing game');
      _state = GameState.paused;
      gameRef.pauseEngine();
      // Show pause overlay
      gameRef.overlays.add('pause_menu');
    }
  }

  void resumeGame() {
    if (_state == GameState.paused && isMounted) {
      print('Resuming game');
      _state = GameState.playing;
      gameRef.resumeEngine();
      // Hide pause overlay
      gameRef.overlays.remove('pause_menu');
    }
  }

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
      // Initialize level system
      gameRef.levelManager?.resetLevels();
      gameRef.initializeLevelSystem();
      
      // Reset game components
      gameRef.audioManager.playBackgroundMusic();
      gameRef.enemyManager.reset();
      gameRef.player.reset();
      gameRef.uiManager.reset();
      
      // Show briefing for first level
      String briefingText = gameRef.levelManager?.currentLevel.briefingText ?? "Mission started";
      print('Level briefing: $briefingText');
      // TODO: Show briefing overlay
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
    
    // Reset level system
    gameRef.levelManager?.resetLevels();
    gameRef.objectiveTimer = 0.0;
    gameRef.enemiesDestroyedInLevel = 0;
    
    state = GameState.playing;  // Set the state before resetting the game
    gameRef.resetGame();
    gameRef.audioManager.playBackgroundMusic();
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
    
    // Track enemy destroyed for level objectives
    gameRef.onEnemyDestroyed();
  }
}