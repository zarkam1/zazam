import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zazam/game_reference.dart';
import 'package:zazam/starfield.dart';
import 'bullets.dart';
import 'enemies.dart';
import 'parallax_background.dart';
import 'player.dart';
import 'input_handler.dart';
import 'game_state_manager.dart';
import 'enemy_manager.dart';
import 'powerup.dart';
import 'powerupindicators.dart';
import 'styled_button.dart';
import 'ui_manager.dart';
import 'audio_manager.dart';
import 'currency_system.dart';
import 'level_management.dart';
import 'performance_overlay.dart';
import 'background_manager.dart';
import 'workaround.dart'; // Import workaround for extension methods

enum GameState { menu, playing, paused, gameOver }

class SpaceShooterGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapDetector, HasGameRef {
  late Player player;
  Starfield? starfield;
  late GameStateManager gameStateManager;
  late EnemyManager enemyManager;
  late UIManager uiManager;
  late AudioManager audioManager;
  late InputHandler inputHandler;
  late JoystickComponent joystick;
  late HudButtonComponent shootButton;
  late PowerUpIndicators powerUpIndicators;
  static const double joystickSensitivity = 0.1; // Adjust this value to change sensitivity
  late HudButtonComponent shieldButton;
  // Level management
  late LevelManager levelManager;
  late BackgroundManager backgroundManager;
  late ScrapManager scrapManager;
  double objectiveTimer = 0.0;
  int enemiesDestroyedInLevel = 0;
  Enemy? currentBoss;
  @override
  Future<void> onLoad() async {
    try {
      print('SpaceShooterGame: onLoad started');
      await super.onLoad();
      
      // Initialize currency system
      scrapManager = ScrapManager();
 // Add this line to load the parallax background
      // Add Starfield

        // Initialize Starfield last
      await _initializeStarfield();
     // var starfield = Starfield(density: 200, maxStarSize: 3.0);
   //   await add(starfield);

      // Load all game images with error handling
      try {
        print('Loading game images...');
        final imagesToLoad = [
          'player.png',
          'basic_enemy.png',
          'fast_enemy.png',
          'tank_enemy.png',
          'boss_enemy.png',
          'bullet.png',
          'enemy_bullet.png',
          'button_bg.png',
          'powerup_speedBoost.png',
          'powerup_extraLife.png',
          'powerup_rapidFire.png',
          'powerup_shield.png',
          'shield.png',
          'shield_animation.png'
        ];
        
        // Load each image individually with error reporting
        for (final imagePath in imagesToLoad) {
          try {
            await images.load(imagePath);
            print('Successfully loaded: $imagePath');
          } catch (e) {
            print('ERROR loading image: $imagePath - $e');
          }
        }
        
        print('SpaceShooterGame: Images loaded');
      } catch (e) {
        print('Error in batch image loading: $e');
      }
      player = Player();
      gameStateManager = GameStateManager();
      enemyManager = EnemyManager();
      uiManager = UIManager();
      audioManager = AudioManager();
      
      // Initialize managers
      levelManager = LevelManager();
      backgroundManager = BackgroundManager();
      scrapManager = ScrapManager();

      inputHandler = InputHandler();
      add(inputHandler);

      joystick = JoystickComponent(
        knob: CircleComponent(
            radius: 30, paint: BasicPalette.blue.withAlpha(200).paint()),
        background: CircleComponent(
            radius: 100, paint: BasicPalette.blue.withAlpha(100).paint()),
        margin: const EdgeInsets.only(left: 40, bottom: 40),
      );
      add(joystick);

      print('SpaceShooterGame: Joystick added');

      shootButton = HudButtonComponent(
        button: CircleComponent(radius: 30, paint: BasicPalette.red.paint()),
        buttonDown: CircleComponent(
            radius: 30, paint: BasicPalette.red.withAlpha(100).paint()),
        position: Vector2(size.x - 50, size.y - 50),
        onPressed: () => player.shoot(),
      );
      await add(shootButton);
      print('SpaceShooterGame: Shoot button added');

      shieldButton = HudButtonComponent(
        button: CircleComponent(radius: 30, paint: BasicPalette.blue.paint()),
        buttonDown: CircleComponent(radius: 30,paint: BasicPalette.blue.withAlpha(100).paint()),
        position: Vector2(size.x - 50, size.y - 120), // Position above shoot button
        onPressed: () => player.toggleShield(),
      );
      await add(shieldButton);

      // Add performance overlay
      final performanceOverlay = GamePerformanceOverlay(
        position: Vector2(10, size.y - 30),
        showDetailedStats: true,
      );
      await add(performanceOverlay);
      print('SpaceShooterGame: Performance overlay added');
      
      await addAll([backgroundManager, player, gameStateManager, enemyManager, uiManager]);
      print('SpaceShooterGame: Components added');
      await audioManager.initialize();
      print('SpaceShooterGame: Audio initialized');
      
      // Initialize level manager and currency system
      initializeLevelSystem();
      
      print('SpaceShooterGame: Setting initial state to menu');
      gameStateManager.state = GameState.menu;
      print('SpaceShooterGame: Initial state set to menu');
      overlays.remove('initial_overlay');
      print('powerUpIndicators: ');
      powerUpIndicators = PowerUpIndicators();
      await add(powerUpIndicators);
   
      print('SpaceShooterGame: onLoad completed');
    } catch (e, stackTrace) {
      print('Error in SpaceShooterGame onLoad: $e');
      print('Stack trace: $stackTrace');
    }
  }

 Future<void> _initializeStarfield() async {
    starfield = Starfield(density: 300, maxStarSize: 3.0);
    await add(starfield!);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameStateManager.state == GameState.menu &&
        !children.any((component) => component is MenuComponent)) {
      print('MenuComponent missing, attempting to add');
      add(MenuComponent());
      player.removeFromParent();
      joystick.removeFromParent();
      shootButton.removeFromParent();
    } else if (gameStateManager.state == GameState.playing) {
      children.whereType<MenuComponent>().forEach((menu) => menu.removeFromParent());
      if (!children.contains(player)) add(player);
      if (!children.contains(joystick)) add(joystick);
      if (!children.contains(shootButton)) add(shootButton);
      // Ensure pause button is present
      if (!children.any((c) => c is PauseButtonComponent)) {
        add(PauseButtonComponent());
      }
      enemyManager.update(dt);
      uiManager.update(dt);
      powerUpIndicators.updateIndicators(player);
      Vector2 keyboardMovement = inputHandler.movement * Player.speed * dt;
      player.move(keyboardMovement);

      // Handle joystick input
      Vector2 joystickMovement = joystick.delta * Player.speed * dt * joystickSensitivity;
      player.move(joystickMovement);

      // Update starfield based on player movement and acceleration
      if (starfield != null && player != null) {
        starfield?.updateShipMovement(player.velocity);
      }

      if (inputHandler.isShooting) {
        player.shoot();
      }
      
      // Update level objectives
      updateLevelProgress(dt);
    }
    else if (gameStateManager.state == GameState.paused) {
      // Do not update game logic when paused
      return;
    }
    else if (gameStateManager.state == GameState.gameOver) {
      player.removeFromParent();
      joystick.removeFromParent();
      shootButton.removeFromParent();
      if (!children.any((component) => component is GameOverComponent)) {
        add(GameOverComponent(score: gameStateManager.score));
      }
    }
  }

  // Update level progress based on objective type
  void updateLevelProgress(double dt) {
    try {
      if (gameStateManager.state != GameState.playing || levelManager == null) return;
      
      final currentLevel = levelManager!.currentLevel;
      double progress = 0.0;
      
      // Handle different objective types
      switch (currentLevel.objectiveType) {
        case ObjectiveType.SURVIVE:
          // Update objective timer for SURVIVE objectives
          objectiveTimer += dt;
          final targetTime = currentLevel.objectiveValue as int;
          progress = objectiveTimer / targetTime;
          
          // Check if survival time has been reached
          if (objectiveTimer >= targetTime) {
            completeLevel();
          }
          break;
          
        case ObjectiveType.DESTROY_COUNT:
          // For DESTROY_COUNT objectives, the enemiesDestroyedInLevel counter is updated
          // when enemies are destroyed, and we check here if the target has been reached
          final targetCount = currentLevel.objectiveValue as int;
          progress = enemiesDestroyedInLevel / targetCount;
          
          if (enemiesDestroyedInLevel >= targetCount) {
            completeLevel();
          }
          break;
          
        case ObjectiveType.BOSS:
          // For BOSS objectives, check if we need to spawn a boss
          if (currentBoss == null || !currentBoss!.isMounted) {
            // Only spawn boss if it doesn't exist or has been removed
            enemyManager.spawnBoss();
          } else {
            // Calculate progress based on boss health percentage
            final healthPercentage = currentBoss!.health / currentBoss!.maxHealth;
            progress = 1.0 - healthPercentage;
            
            // Check if boss is defeated
            if (currentBoss!.health <= 0) {
              completeLevel();
            }
          }
          break;
          
        default:
          // Handle other objective types if needed
          break;
      }
      
      // Update the level manager with current progress
      levelManager!.updateObjectiveProgress(progress.clamp(0.0, 1.0));
    } catch (e) {
      print('Error in updateLevelProgress: $e');
    }
    
    // Update UI
    updateLevelObjective();
  }
  
  // Handle enemy destroyed for objective tracking
  void onEnemyDestroyed() {
    enemiesDestroyedInLevel++;
  }
  
  // Complete the current level and advance to the next
  void completeLevel() {
    if (gameStateManager.state != GameState.playing || levelManager == null) return;
    
    // Mark level as complete
    print('Level ${levelManager!.currentLevel.id} completed!');
    
    // Check if there are more levels
    if (levelManager!.hasNextLevel) {
      // Advance to the next level
      levelManager!.advanceToNextLevel();
      
      // Reset level-specific variables
      objectiveTimer = 0.0;
      enemiesDestroyedInLevel = 0;
      currentBoss = null;
      
      // Get the new level settings
      final newLevel = levelManager!.currentLevel;
      enemyManager.spawnRate = newLevel.enemySpawnRate.toDouble();
      enemyManager.maxEnemies = newLevel.enemyMaxOnScreen;
      enemyManager.enemySpeedMultiplier = newLevel.enemySpeedMultiplier;
      
      // Show level briefing (could be implemented as an overlay)
      // overlays.add('level_briefing');
    } else {
      // Game completed - show victory screen or return to menu
      gameStateManager.state = GameState.menu;
    }
  }
 
  void resetGame() {
    print('SpaceShooterGame: Resetting game');
    children.whereType<Enemy>().toList().forEach((enemy) => enemy.removeFromParent());
    children.whereType<Bullet>().toList().forEach((bullet) => bullet.removeFromParent());
    children.whereType<EnemyBullet>().toList().forEach((bullet) => bullet.removeFromParent());
    children.whereType<PowerUp>().toList().forEach((powerUp) => powerUp.removeFromParent());
    children.whereType<GameOverComponent>().toList().forEach((component) => component.removeFromParent());
    
    player.reset();
    powerUpIndicators.resetIndicators();
    enemyManager.reset();
    uiManager.reset();
    
    // Reset level-related variables
    objectiveTimer = 0.0;
    enemiesDestroyedInLevel = 0;
    levelManager?.resetLevels();
    
    // Update UI with current level objective
    updateLevelObjective();
    
    // Remove these components
    player.removeFromParent();
    joystick.removeFromParent();
    shootButton.removeFromParent();

    // Add menu component
    add(MenuComponent());

    print('SpaceShooterGame: Game reset completed');
  }
  
  // Initialize level system
  void initializeLevelSystem() {
    final currentLevel = levelManager.getCurrentLevel();
    
    // Set enemy spawn parameters based on level
    enemyManager.setSpawnParameters(
      spawnRate: currentLevel.enemySpawnRate.toDouble(),
      maxEnemies: currentLevel.enemyMaxOnScreen,
      speedMultiplier: currentLevel.enemySpeedMultiplier,
      availableTypes: currentLevel.availableEnemyTypes,
    );
    
    // Set the background for this level
    backgroundManager.setLevelBackground(currentLevel);
    
    // Show level briefing
    uiManager.showLevelBriefing(currentLevel.briefingText, currentLevel.id);
  }
  
  // Update the UI with the current level objective
  void updateLevelObjective() {
    if (uiManager == null || levelManager == null) return;
    
    final currentLevel = levelManager!.currentLevel;
    String objectiveText = '';
    double progress = 0.0;
    
    switch (currentLevel.objectiveType) {
      case ObjectiveType.SURVIVE:
        final targetTime = currentLevel.objectiveValue as int;
        objectiveText = 'Survive for ${targetTime}s';
        progress = objectiveTimer / targetTime;
        break;
      case ObjectiveType.DESTROY_COUNT:
        final targetCount = currentLevel.objectiveValue as int;
        objectiveText = 'Destroy ${targetCount} enemies';
        progress = enemiesDestroyedInLevel / targetCount;
        break;
      case ObjectiveType.BOSS:
        objectiveText = 'Defeat the boss';
        progress = 0.0; // Will be updated when boss is implemented
        break;
      default:
        objectiveText = 'Unknown objective';
    }
    
    uiManager.updateObjective(objectiveText, progress.clamp(0.0, 1.0));
  }
  
  // Add scrap to the player's currency
  void addScrap(int amount) {
    scrapManager.addScrap(amount);
    
    // Update UI if needed
    // uiManager.updateScrap(scrapManager.scrapAmount);
  }
  
  @override
  void onTapDown(TapDownInfo info) {
    if (gameStateManager.state == GameState.menu) {
      gameStateManager.startGame();
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // Pause/resume with Escape or P
    if (event is RawKeyDownEvent) {
      if (gameStateManager.state == GameState.playing &&
          (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.keyP)) {
        gameStateManager.pauseGame();
        return KeyEventResult.handled;
      } else if (gameStateManager.state == GameState.paused &&
          (event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.keyP)) {
        gameStateManager.resumeGame();
        return KeyEventResult.handled;
      }
    }
    super.onKeyEvent(event, keysPressed);
    inputHandler.onKeyEvent(event, keysPressed);
    return KeyEventResult.handled;
  }
}

// ========== Pause Button Component ==========

class PauseButtonComponent extends PositionComponent with HasGameRef<SpaceShooterGame>, TapCallbacks {
  late StyledButton pauseButton;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = Vector2(60, 40);
    position = Vector2(gameRef.size.x - 80, 20);
    pauseButton = StyledButton(
      text: 'Pause',
      onPressed: () {
        gameRef.gameStateManager.pauseGame();
      },
      position: Vector2.zero(),
      size: size,
    );
    await add(pauseButton);
  }
}

// The MenuComponent, GameOverComponent, DebugOverlay, and EnemyDebugRenderer classes remain unchanged
class MenuComponent extends PositionComponent
    with HasGameRef<SpaceShooterGame>, TapCallbacks {
  late TextComponent titleText;
  late TextComponent startText;
  late StyledButton startButton;
  int _renderCount = 0;
  late Stopwatch _stopwatch;
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    print('MenuComponent: onLoad started');
    position = Vector2.zero();
    _stopwatch = Stopwatch()..start();
    try {
      size = gameRef.size;
      print('MenuComponent: size set to ${size.x}, ${size.y}');

      titleText = TextComponent(
        text: 'Space Shooter',
        textRenderer: TextPaint(
          style: const TextStyle(
              fontSize: 48, color: Colors.white, fontFamily: 'SpaceFont'),
        ),
      );
      titleText.position = size / 2;
      titleText.anchor = Anchor.center;
      await add(titleText);
      print('MenuComponent: titleText added');

      startButton = StyledButton(
        text: 'Tap to Start',
        onPressed: () => gameRef.gameStateManager.startGame(),
        position: Vector2(size.x / 2 - 100, size.y * 2 / 3),
        size: Vector2(200, 50),
      );
      await add(startButton);

      print('MenuComponent: onLoad completed');
    } catch (e, stackTrace) {
      print('Error in MenuComponent onLoad: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  void render(Canvas canvas) {
    try {
      print('MenuComponent: render called');
      super.render(canvas);
      _renderCount++;
      if (_renderCount % 60 == 0) {
        // Log every 60 renders
        double seconds = _stopwatch.elapsedMilliseconds / 1000;
        double fps = _renderCount / seconds;
        print(
            'MenuComponent: Rendered $_renderCount times in ${seconds.toStringAsFixed(2)} seconds. FPS: ${fps.toStringAsFixed(2)}');
      }
    } catch (e) {
      print('Error in MenuComponent render: $e');
    }
  }
}

class GameOverComponent extends PositionComponent with HasGameRef<SpaceShooterGame> {
  final int score;
  late TextComponent gameOverText;
  late TextComponent scoreText;
  late StyledButton restartButton;

  GameOverComponent({required this.score}) : super(priority: 10);

  @override
  Future<void> onLoad() async {
    size = gameRef.size;

    gameOverText = TextComponent(
      text: 'Game Over',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 48, color: Colors.white)),
    )..position = Vector2(size.x / 2, size.y / 3);
    gameOverText.anchor = Anchor.center;
    await add(gameOverText);

    scoreText = TextComponent(
      text: 'Score: $score',
      textRenderer: TextPaint(style: const TextStyle(fontSize: 24, color: Colors.white)),
    )..position = Vector2(size.x / 2, size.y / 2);
    scoreText.anchor = Anchor.center;
    await add(scoreText);

    restartButton = StyledButton(
      text: 'Restart',
      onPressed: () {
        print('Restart button pressed');
        if (isMounted) {
          gameRef.gameStateManager.resetGame();
        }
      },
      position: Vector2(size.x / 2 - 100, size.y * 2 / 3),
      size: Vector2(200, 50),
    );
    await add(restartButton);

    print('GameOverComponent loaded');
  }
}

class DebugOverlay extends PositionComponent
    with HasGameRef<SpaceShooterGame>, GameRef {
  late TextComponent enemyCountText;
  late TextComponent enemiesSpawnedText;
  late TextComponent enemiesPassedText;
  late TextComponent bulletCountText;
  late TextComponent playerBulletCountText;
  late TextComponent playerShootCooldownText;
  late TextComponent enemyBulletCountText;

  @override
  Future<void> onLoad() async {
    enemyCountText = TextComponent(
      text: 'Enemies on screen: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    enemyCountText.position = Vector2(10, 200);
    add(enemyCountText);

    enemiesSpawnedText = TextComponent(
      text: 'Enemies spawned: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    enemiesSpawnedText.position = Vector2(10, 210);
    add(enemiesSpawnedText);

    enemiesPassedText = TextComponent(
      text: 'Enemies passed: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    enemiesPassedText.position = Vector2(10, 230);
    add(enemiesPassedText);

    bulletCountText = TextComponent(
      text: 'Bullets: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    bulletCountText.position = Vector2(10, 250);
    add(bulletCountText);

    enemyBulletCountText = TextComponent(
      text: 'Enemy Bullets: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    enemyBulletCountText.position = Vector2(10, 270);
    add(enemyBulletCountText);

    playerShootCooldownText = TextComponent(
      text: 'Shoot Cooldown: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    playerShootCooldownText.position = Vector2(10, 290);
    add(playerShootCooldownText);

    playerBulletCountText = TextComponent(
      text: 'Player Bullets: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    playerBulletCountText.position = Vector2(10, 310);
    add(playerBulletCountText);
  }

  @override
  void update(double dt) {
    enemyCountText.text =
        'Enemies on screen: ${gameRef.children.query<Enemy>().length}';
    enemiesSpawnedText.text = 'Enemies spawned: ${gameState.enemiesSpawned}';
    enemiesPassedText.text = 'Enemies passed: ${gameState.enemiesPassed}';
    playerBulletCountText.text =
        'Player Bullets: ${gameRef.children.query<Bullet>().length}';
    enemyBulletCountText.text =
        'Enemy Bullets: ${gameRef.children.query<EnemyBullet>().length}';
    playerShootCooldownText.text =
        'Shoot Cooldown: ${gameRef.player?.shootCooldown.toStringAsFixed(2)}';
  }
}

class EnemyDebugRenderer extends Component with HasGameRef<SpaceShooterGame> {
  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke;
    for (final enemy in gameRef.children.query<Enemy>()) {
      canvas.drawRect(enemy.toRect(), paint);
    }
  }
}
