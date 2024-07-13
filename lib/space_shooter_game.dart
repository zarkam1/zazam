import 'dart:math';
import 'dart:async' as dart_async;
import 'package:flame/collisions.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'powerup.dart';
import 'player.dart';
import 'enemies.dart';
import 'bullets.dart';
import 'input_handler.dart';
import 'powerupindicators.dart';

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

  double enemySpawnTimer = 0;
  TextComponent? healthText;
  late TextComponent scoreText;
  late PowerUpIndicators powerUpIndicators;

  late TextComponent passesLeftText;
  int enemiesPassed = 0;
  static const int maxEnemiesPassed = 5;

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
      'powerup_speedBoost.png',
      'powerup_extraLife.png',
      'powerup_rapidFire.png',
      'powerup_shield.png',
      'shield.png',
      'shield_animation.png'
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

    passesLeftText = TextComponent(
      text: 'Passes Left: $maxEnemiesPassed',
      textRenderer:
          TextPaint(style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
    passesLeftText.position = Vector2(10, 50); // Adjust position as needed
    add(passesLeftText);

    player = Player();
    inputHandler = InputHandler();
    powerUpIndicators = PowerUpIndicators();

    add(FpsTextComponent(position: Vector2(size.x - 40, 20)));

    healthText = TextComponent(
      text: 'Health: 0',
      textRenderer:
          TextPaint(style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
    healthText!.position = Vector2(10, 10);

    scoreText = TextComponent(
      text: 'Score: 0',
      textRenderer:
          TextPaint(style: const TextStyle(color: Colors.white, fontSize: 16)),
    );
    scoreText.position = Vector2(10, 30);
    add(scoreText);

    soundPools['laser'] =
        await FlameAudio.createPool('laser.mp3', maxPlayers: 5);
    soundPools['enemy_laser'] =
        await FlameAudio.createPool('enemy_laser.mp3', maxPlayers: 5);
    soundPools['explosion'] =
        await FlameAudio.createPool('explosion.mp3', maxPlayers: 2);

    state = GameState.menu;
    add(MenuComponent());
  }

 void enemyPassed() {
    enemiesPassed++;
    int passesLeft = maxEnemiesPassed - enemiesPassed;
    passesLeftText.text = 'Passes Left: $passesLeft';
    if (enemiesPassed >= maxEnemiesPassed) {
      gameOver();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    switch (state) {
      case GameState.menu:
        // Handle menu state
        break;
      case GameState.playing:
        _updatePlayingState(dt);
        break;
      case GameState.gameOver:
        // Game over state - do nothing
        break;
    }
  }

  void _updatePlayingState(double dt) {
    if (healthText != null) {
      healthText!.text = 'Health: ${player.health}';
    }
    scoreText.text = 'Score: $score';
    _spawnEnemies(dt);
    _handlePlayerMovement(dt);
    _handlePlayerShooting(dt);
    powerUpIndicators.updateIndicators(player);
  }

  void _spawnEnemies(double dt) {
    enemySpawnTimer += dt;
    if (enemySpawnTimer >= 2.0 &&
        children.query<Enemy>().length < maxEnemies &&
        enemiesSpawned < 100) {
      final enemy = BasicEnemy()
        ..position = Vector2(random.nextDouble() * size.x, -50);
      add(enemy);
      enemiesSpawned++;
      enemySpawnTimer = 0;
    }
  }

  void _handlePlayerMovement(double dt) {
    Vector2 movement = Vector2.zero();
    if (joystick != null) {
      movement += joystick!.delta / 10;
    }
    movement += inputHandler.movement;
    if (!movement.isZero()) {
      movement.normalize();
      player.move(movement * Player.speed * dt);
    }
  }

  void _handlePlayerShooting(double dt) {
    if (inputHandler.isShooting) {
      player.shoot();
      inputHandler.isShooting = false;
    }
  }

  void startGame() {
    state = GameState.playing;
    add(player);
    add(powerUpIndicators);
    score = 0;
    enemiesPassed = 0;
    enemiesSpawned = 0;
    player.resetPowerups();
    FlameAudio.bgm.play('background_music.mp3');
    children.query<MenuComponent>().forEach((component) => remove(component));
    if (healthText != null) {
      add(healthText!);
    }

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 15, paint: Paint()..color = Colors.white),
      background: CircleComponent(
          radius: 50, paint: Paint()..color = Colors.white.withOpacity(0.5)),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(joystick!);

    shootButton = ButtonComponent(
      button: CircleComponent(
          radius: 30, paint: Paint()..color = Colors.red.withOpacity(0.8)),
      onPressed: () => player.shoot(),
      position: Vector2(size.x - 80, size.y - 80),
      size: Vector2(60, 60),
    );
    add(shootButton!);

    powerUpTimer = dart_async.Timer.periodic(
        const Duration(seconds: 10), (_) => spawnPowerUp());
  }

  void gameOver() {
    state = GameState.gameOver;
    FlameAudio.bgm.stop();
    playSfx('game_over.mp3');
    player.removeFromParent();
    joystick?.removeFromParent();
    shootButton?.removeFromParent();
    powerUpTimer?.cancel();
    add(GameOverComponent(score: score));

    children.query<Enemy>().forEach((enemy) => enemy.removeFromParent());
    children.query<Bullet>().forEach((bullet) => bullet.removeFromParent());
    children
        .query<EnemyBullet>()
        .forEach((bullet) => bullet.removeFromParent());
    children.query<PowerUp>().forEach((powerUp) => powerUp.removeFromParent());
  }

  void resetGame() {
    print('Resetting game');
    children
        .query<GameOverComponent>()
        .forEach((component) => remove(component));
    children.query<Enemy>().forEach((enemy) => remove(enemy));
    children.query<Bullet>().forEach((bullet) => remove(bullet));
    children.query<EnemyBullet>().forEach((bullet) => remove(bullet));
    children.query<PowerUp>().forEach((powerUp) => remove(powerUp));

    player.removeFromParent();
    joystick?.removeFromParent();
    shootButton?.removeFromParent();
    powerUpIndicators.removeFromParent();

    state = GameState.menu;
    score = 0;
    enemiesPassed = 0;
    enemiesSpawned = 0;

    passesLeftText.text = 'Passes Left: $maxEnemiesPassed';
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
    soundPools.values.forEach((pool) => pool.dispose());
    FlameAudio.bgm.stop();
  }

  @override
  void onRemove() {
    stopAllSounds();
    super.onRemove();
  }

  void increaseScore(int points) {
    score += points;
    scoreText.text = 'Score: $score';
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (state != GameState.playing) return KeyEventResult.ignored;
    final bool handled = inputHandler.onKeyEvent(event, keysPressed);
    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  //bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
  @override
  void onTapDown(TapDownInfo event) {
    if (state == GameState.menu) {
      startGame();
    }
  }

  void spawnPowerUp() {
    final powerUpType = random.nextInt(4);
    PowerUp powerUp;
    switch (powerUpType) {
      case 0:
        powerUp =
            SpeedBoost(position: Vector2(random.nextDouble() * size.x, 0));
        break;
      case 1:
        powerUp = ExtraLife(position: Vector2(random.nextDouble() * size.x, 0));
        break;
      case 2:
        powerUp = RapidFire(position: Vector2(random.nextDouble() * size.x, 0));
        break;
      case 3:
      default:
        powerUp = Shield(position: Vector2(random.nextDouble() * size.x, 0));
        break;
    }
    add(powerUp);
    print('Spawned power-up: ${powerUp.runtimeType}');
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

  GameOverComponent({required this.score})
      : super(priority: 10); // High priority to ensure it's on top

  @override
  Future<void> onLoad() async {
    size = gameRef.size; // Make component cover the entire game area

    gameOverText = TextComponent(
      text: 'Game Over',
      textRenderer:
          TextPaint(style: const TextStyle(fontSize: 48, color: Colors.white)),
    )..position = Vector2(size.x / 2, size.y / 3);
    gameOverText.anchor = Anchor.center;

    scoreText = TextComponent(
      text: 'Score: $score',
      textRenderer:
          TextPaint(style: const TextStyle(fontSize: 24, color: Colors.white)),
    )..position = Vector2(size.x / 2, size.y / 2);
    scoreText.anchor = Anchor.center;

    restartText = TextComponent(
      text: 'Tap to Restart',
      textRenderer:
          TextPaint(style: const TextStyle(fontSize: 24, color: Colors.white)),
    )..position = Vector2(size.x / 2, size.y * 2 / 3);
    restartText.anchor = Anchor.center;

    addAll([gameOverText, scoreText, restartText]);
  }

  @override
  void onTapDown(TapDownEvent event) {
    print('Tap detected on GameOverComponent');
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

    enemyBulletCountText = TextComponent(
      text: 'Bullets: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    enemyBulletCountText.position = Vector2(10, 120);
    add(enemyBulletCountText);

    playerShootCooldownText = TextComponent(
      text: 'Bullets: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    playerShootCooldownText.position = Vector2(10, 140);
    add(playerShootCooldownText);

    playerBulletCountText = TextComponent(
      text: 'Player Bullets: 0',
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.white, fontSize: 16)),
    );
    playerBulletCountText.position = Vector2(10, 160);
    add(playerBulletCountText);
  }

  @override
  void update(double dt) {
    enemyCountText.text =
        'Enemies on screen: ${gameRef.children.query<Enemy>().length}';
    enemiesSpawnedText.text = 'Enemies spawned: ${gameRef.enemiesSpawned}';
    enemiesPassedText.text = 'Enemies passed: ${gameRef.enemiesPassed}';
    playerBulletCountText.text =
        'Player Bullets: ${gameRef.children.query<Bullet>().length}';
    enemyBulletCountText.text =
        'Enemy Bullets: ${gameRef.children.query<EnemyBullet>().length}';
    playerShootCooldownText.text =
        'Shoot Cooldown: ${gameRef.player.shootCooldown.toStringAsFixed(2)}';
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
