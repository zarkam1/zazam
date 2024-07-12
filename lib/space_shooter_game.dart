import 'dart:math';
import 'dart:async' as dart_async;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'player.dart';
import 'enemies.dart';
import 'bullets.dart';
import 'input_handler.dart';
import 'powerup.dart';

enum GameState { menu, playing, gameOver }

class SpaceShooterGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapDetector {
  late Player player;
  JoystickComponent? joystick;
  ButtonComponent? shootButton;
  late InputHandler inputHandler;
  int score = 0;
  GameState state = GameState.menu;
  Random random = Random();
  dart_async.Timer? powerUpTimer;
  int enemiesPassed = 0;
  // Timers for enemy spawning and debug info
  double enemySpawnTimer = 0;
  double debugInfoTimer = 0;
  TextComponent? healthText;

  static const int maxEnemies = 5;
  int enemiesSpawned = 0;
  Map<String, AudioPool> soundPools = {};
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await images.loadAll([
      'player.png',
      'basic_enemy.png',
      'bullet.png',
      'enemy_bullet.png',
      'button_bg.png',
    ]);

    await FlameAudio.audioCache.loadAll([
      'background_music.mp3',
      'laser.mp3',
      'explosion.mp3',
      'enemy_laser.mp3',
      'player_hit.mp3',
      'powerup.mp3',
      'game_over.mp3',
    ]);

    player = Player();
    inputHandler = InputHandler();

    add(FpsTextComponent(position: Vector2(size.x - 40, 20)));

    state = GameState.menu;
    add(MenuComponent());
    healthText = TextComponent(
      text: 'Health: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    healthText!.position = Vector2(10, 10);
  
    soundPools['laser'] = await FlameAudio.createPool('laser.mp3', maxPlayers: 5) ;
    soundPools['enemy_laser'] = await FlameAudio.createPool('enemy_laser.mp3', maxPlayers: 5);
 
 AudioPool audioPool = await FlameAudio.createPool('explosion.mp3', maxPlayers: 2);
audioPool.start();
 
  }

  @override
  void update(double dt) {
    super.update(dt);

    switch (state) {
      case GameState.menu:
        // Handle menu state
        break;
      case GameState.playing:
        if (healthText != null) {
          healthText!.text = 'Health: ${player.health}';
        }
        _spawnEnemies(dt);
        _handlePlayerMovement(dt);
        _handlePlayerShooting(dt);
        break;
      case GameState.gameOver:
        // Handle game over state
        break;
    }
  }

  void _updateDebugInfo(double dt) {
    debugInfoTimer += dt;
    if (debugInfoTimer >= 1.0) {
      // Update debug info every second
      print(
          'Bullets on screen: ${children.query<Bullet>().length + children.query<EnemyBullet>().length}');
      print('Enemies on screen: ${children.query<Enemy>().length}');
      print('Player shoot cooldown: ${player.shootCooldown}');
      debugInfoTimer = 0;
    }
  }

  void enemyPassed() {
    enemiesPassed++;
    print('Enemy passed. Total passed: $enemiesPassed');
    // You can add game logic here, like reducing player health or ending the game
    if (enemiesPassed >= 10) {
      gameOver();
    }
  }

 void _spawnEnemies(double dt) {
    enemySpawnTimer += dt;
    if (enemySpawnTimer >= 2.0 && children.query<Enemy>().length < maxEnemies && enemiesSpawned < 100) {
      final enemy = BasicEnemy()..position = Vector2(random.nextDouble() * size.x, -50);
      add(enemy);
      enemiesSpawned++;
      print('Enemy spawned at ${enemy.position}. Total spawned: $enemiesSpawned');
      enemySpawnTimer = 0;
    }
  }

  void spawnPowerUp() {
    final powerUp = SpeedBoost(
      position: Vector2(random.nextDouble() * size.x, 0),
    );
    add(powerUp);
  }

  void _handlePlayerMovement(double dt) {
    Vector2 movement = Vector2.zero();

    // Joystick input
    if (joystick != null) {
      movement += joystick!.delta / 10;
    }

    // Keyboard input
    movement += inputHandler.movement;

    if (!movement.isZero()) {
      movement.normalize();
      player.move(movement * Player.speed * dt);
    }
  }

  void _handlePlayerShooting(double dt) {
    if (inputHandler.isShooting) {
      player.shoot();
      inputHandler.isShooting = false; // Reset to prevent continuous shooting
    }
  }

  void startGame() {
    state = GameState.playing;
    add(player);
    score = 0;
    FlameAudio.bgm.play('background_music.mp3');
    //FlameAudio.loopLongAudio('music.mp3');
    children.query<MenuComponent>().forEach((component) => remove(component));
    if (healthText != null) {
      add(healthText!);
    }
void startBgmMusic() {
    FlameAudio.bgm.initialize();
    FlameAudio.bgm.play('background_music.mp3');
  }
    // Add joystick
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 15, paint: Paint()..color = Colors.white),
      background: CircleComponent(
          radius: 50, paint: Paint()..color = Colors.white.withOpacity(0.5)),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(joystick!);

    // Add shoot button
    shootButton = ButtonComponent(
      button: CircleComponent(
          radius: 30, paint: Paint()..color = Colors.red.withOpacity(0.8)),
      onPressed: () {
        player.shoot();
        print('Shoot button pressed'); // Debug print
      },
      position: Vector2(size.x - 80, size.y - 80),
      size: Vector2(60, 60),
    );
    add(shootButton!);
    add(DebugOverlay());
    add(EnemyDebugRenderer());
    // Start spawning power-ups
    powerUpTimer = dart_async.Timer.periodic(
        const Duration(seconds: 10), (_) => spawnPowerUp());
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (shootButton != null) {
      shootButton!.position = Vector2(size.x - 80, size.y - 80);
    }
  }

  void gameOver() {
    state = GameState.gameOver;
    FlameAudio.bgm.stop();
    playSfx('game_over.mp3');
    player.removeFromParent();
    joystick?.removeFromParent();
    joystick = null;
    shootButton?.removeFromParent();
    shootButton = null;
    powerUpTimer?.cancel();
    add(GameOverComponent(score: score));
  }

  void resetGame() {
    children
        .query<GameOverComponent>()
        .forEach((component) => remove(component));
    children.query<Enemy>().forEach((enemy) => remove(enemy));
    children.query<Bullet>().forEach((bullet) => remove(bullet));
    state = GameState.menu;
    healthText?.removeFromParent();
    add(MenuComponent());
  }

   void playSfx(String sfxName) {
    if (soundPools.containsKey(sfxName)) {
      soundPools[sfxName]?.start();
    } else {
      FlameAudio.play(sfxName);
    }
  }

  void stopAllSounds() {
      soundPools.values.forEach((pool) => pool.dispose);
    FlameAudio.bgm.stop();
  }
  @override
  void onRemove() {
    stopAllSounds();
    super.onRemove();
  }
  void increaseScore(int points) {
    score += points;
    // Update score display
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (state != GameState.playing) return KeyEventResult.ignored;

    // Movement
    inputHandler.movement.setZero();
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft))
      inputHandler.movement.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight))
      inputHandler.movement.x += 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp))
      inputHandler.movement.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown))
      inputHandler.movement.y += 1;

    // Shooting
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      inputHandler.isShooting = true;
    }

    return KeyEventResult.handled;
  }

  @override
  void onTapDown(TapDownInfo event) {
    if (state == GameState.menu) {
      startGame();
    }
  }
}

class MenuComponent extends PositionComponent
    with HasGameRef<SpaceShooterGame>, TapCallbacks {
  late TextComponent titleText;
  late TextComponent startText;

  @override
  Future<void> onLoad() async {
    titleText = TextComponent(
      text: 'Space Shooter',
      textRenderer: TextPaint(
        style: const TextStyle(
            fontSize: 48, color: Colors.white, fontFamily: 'SpaceFont'),
      ),
    );
    titleText.position = Vector2(gameRef.size.x / 2, gameRef.size.y / 3);
    titleText.anchor = Anchor.center;
    add(titleText);

    startText = TextComponent(
      text: 'Tap to Start',
      textRenderer: TextPaint(
        style: const TextStyle(
            fontSize: 24, color: Colors.white, fontFamily: 'SpaceFont'),
      ),
    );
    startText.position = Vector2(gameRef.size.x / 2, gameRef.size.y * 2 / 3);
    startText.anchor = Anchor.center;
    add(startText);
  }
}

class GameOverComponent extends PositionComponent
    with HasGameRef<SpaceShooterGame>, TapCallbacks {
  final int score;
  late TextComponent gameOverText;
  late TextComponent scoreText;
  late TextComponent restartText;

  GameOverComponent({required this.score});

  @override
  Future<void> onLoad() async {
    gameOverText = TextComponent(
      text: 'Game Over',
      textRenderer: TextPaint(
        style: const TextStyle(
            fontSize: 48, color: Colors.white, fontFamily: 'SpaceFont'),
      ),
    );
    gameOverText.position = Vector2(gameRef.size.x / 2, gameRef.size.y / 3);
    gameOverText.anchor = Anchor.center;
    add(gameOverText);

    scoreText = TextComponent(
      text: 'Score: $score',
      textRenderer: TextPaint(
        style: const TextStyle(
            fontSize: 24, color: Colors.white, fontFamily: 'SpaceFont'),
      ),
    );
    scoreText.position = Vector2(gameRef.size.x / 2, gameRef.size.y / 2);
    scoreText.anchor = Anchor.center;
    add(scoreText);

    restartText = TextComponent(
      text: 'Tap to Restart',
      textRenderer: TextPaint(
        style: const TextStyle(
            fontSize: 24, color: Colors.white, fontFamily: 'SpaceFont'),
      ),
    );
    restartText.position = Vector2(gameRef.size.x / 2, gameRef.size.y * 2 / 3);
    restartText.anchor = Anchor.center;
    add(restartText);
  }

  @override
  void onTapDown(TapDownEvent event) {
    gameRef.resetGame();
  }
}

class DebugOverlay extends PositionComponent with HasGameRef<SpaceShooterGame> {
  late TextComponent enemyCountText;
  late TextComponent enemiesSpawnedText;
  late TextComponent enemiesPassedText;
  late TextComponent bulletCountText;
   late TextComponent playerBulletCountText;
   late TextComponent playerShootCooldownText;

  late TextComponent enemyBulletCountText;
  @override
  Future<void> onLoad() async {


 playerBulletCountText = TextComponent(
      text: 'Player Bullets: 0',
      textRenderer: TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    playerBulletCountText.position = Vector2(10, 120);
    add(playerBulletCountText);




    enemyCountText = TextComponent(
      text: 'Enemies on screen: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    enemyCountText.position = Vector2(10, 40);
    add(enemyCountText);

    enemiesSpawnedText = TextComponent(
      text: 'Enemies spawned: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    enemiesSpawnedText.position = Vector2(10, 60);
    add(enemiesSpawnedText);

    enemiesPassedText = TextComponent(
      text: 'Enemies passed: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    enemiesPassedText.position = Vector2(10, 80);
    add(enemiesPassedText);

    bulletCountText = TextComponent(
      text: 'Bullets: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    bulletCountText.position = Vector2(10, 100);
    add(bulletCountText);


enemyBulletCountText =TextComponent(
      text: 'Bullets: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    enemyBulletCountText.position = Vector2(10, 120);
    add(enemyBulletCountText);

playerShootCooldownText=TextComponent(
      text: 'Bullets: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    playerShootCooldownText.position = Vector2(10, 140);
    add(playerShootCooldownText);


  }

  @override
  void update(double dt) {
  enemyCountText.text = 'Enemies on screen: ${gameRef.children.query<Enemy>().length}';
    enemiesSpawnedText.text = 'Enemies spawned: ${gameRef.enemiesSpawned}';
    enemiesPassedText.text = 'Enemies passed: ${gameRef.enemiesPassed}';
    playerBulletCountText.text = 'Player Bullets: ${gameRef.children.query<Bullet>().length}';
    enemyBulletCountText.text = 'Enemy Bullets: ${gameRef.children.query<EnemyBullet>().length}';
    playerShootCooldownText.text = 'Shoot Cooldown: ${gameRef.player.shootCooldown.toStringAsFixed(2)}';

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
