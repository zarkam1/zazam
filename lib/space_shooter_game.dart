import 'dart:math';
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

enum GameState { menu, playing, gameOver }

class SpaceShooterGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  late Player player;
  JoystickComponent? joystick;
  ButtonComponent? shootButton;
  late InputHandler inputHandler;
  int score = 0;
  GameState state = GameState.menu;
  Random random = Random();
  
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
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (state) {
      case GameState.menu:
        // Handle menu state
        break;
      case GameState.playing:
        _spawnEnemies();
        _handlePlayerMovement(dt);
        _handlePlayerShooting(dt);
        break;
      case GameState.gameOver:
        // Handle game over state
        break;
    }
  }

  void _spawnEnemies() {
    if (children.query<Enemy>().length < 5) {
      add(BasicEnemy()..position = Vector2(random.nextDouble() * size.x, 0));
    }
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
    children.query<MenuComponent>().forEach((component) => remove(component));
    
    // Add joystick
    joystick = JoystickComponent(
      knob: CircleComponent(radius: 15, paint: Paint()..color = Colors.white),
      background: CircleComponent(radius: 50, paint: Paint()..color = Colors.white.withOpacity(0.5)),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(joystick!);
    
    // Add shoot button
    shootButton = ButtonComponent(
      button: CircleComponent(radius: 25, paint: Paint()..color = Colors.red),
      onPressed: () => player.shoot(),
      position: Vector2(size.x - 60, size.y - 60),
      anchor: Anchor.center,
    );
    add(shootButton!);
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
    add(GameOverComponent(score: score));
  }

  void resetGame() {
    children.query<GameOverComponent>().forEach((component) => remove(component));
    children.query<Enemy>().forEach((enemy) => remove(enemy));
    children.query<Bullet>().forEach((bullet) => remove(bullet));
    state = GameState.menu;
    add(MenuComponent());
  }

  void playSfx(String sfxName) {
    FlameAudio.play(sfxName);
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
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) inputHandler.movement.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) inputHandler.movement.x += 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) inputHandler.movement.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) inputHandler.movement.y += 1;

    // Shooting
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      inputHandler.isShooting = true;
    }

    return KeyEventResult.handled;
  }
}

class MenuComponent extends PositionComponent with HasGameRef<SpaceShooterGame>, TapCallbacks {
  late ButtonComponent startButton;

  @override
  Future<void> onLoad() async {
    final titleText = TextComponent(
      text: 'Space Shooter',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 48, color: Colors.white, fontFamily: 'SpaceFont'),
      ),
    );
    titleText.position = Vector2(gameRef.size.x / 2, gameRef.size.y / 3);
    titleText.anchor = Anchor.center;
    add(titleText);

    startButton = ButtonComponent(
      button: RectangleComponent(
        size: Vector2(200, 50),
        paint: Paint()..color = Colors.blue,
      ),
      onPressed: () => gameRef.startGame(),
      position: Vector2(gameRef.size.x / 2, gameRef.size.y * 2 / 3),
      anchor: Anchor.center,
    );
    add(startButton);

    final startText = TextComponent(
      text: 'Start Game',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 24, color: Colors.white, fontFamily: 'SpaceFont'),
      ),
    );
    startText.position = startButton.position;
    startText.anchor = Anchor.center;
    add(startText);
  }
}

class GameOverComponent extends PositionComponent with HasGameRef<SpaceShooterGame>, TapCallbacks {
  final int score;
  late ButtonComponent restartButton;

  GameOverComponent({required this.score});

  @override
  Future<void> onLoad() async {
    final gameOverText = TextComponent(
      text: 'Game Over',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 48, color: Colors.white, fontFamily: 'SpaceFont'),
      ),
    );
    gameOverText.position = Vector2(gameRef.size.x / 2, gameRef.size.y / 3);
    gameOverText.anchor = Anchor.center;
    add(gameOverText);

    final scoreText = TextComponent(
      text: 'Score: $score',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 24, color: Colors.white, fontFamily: 'SpaceFont'),
      ),
    );
    scoreText.position = Vector2(gameRef.size.x / 2, gameRef.size.y / 2);
    scoreText.anchor = Anchor.center;
    add(scoreText);

    restartButton = ButtonComponent(
      button: RectangleComponent(
        size: Vector2(200, 50),
        paint: Paint()..color = Colors.blue,
      ),
      onPressed: () => gameRef.resetGame(),
      position: Vector2(gameRef.size.x / 2, gameRef.size.y * 2 / 3),
      anchor: Anchor.center,
    );
    add(restartButton);

    final restartText = TextComponent(
      text: 'Restart',
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 24, color: Colors.white, fontFamily: 'SpaceFont'),
      ),
    );
    restartText.position = restartButton.position;
    restartText.anchor = Anchor.center;
    add(restartText);
  }
}