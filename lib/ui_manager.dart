import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:zazam/game_state_manager.dart';
import 'space_shooter_game.dart';
import 'game_reference.dart';

class UIManager extends Component with HasGameRef<SpaceShooterGame>, GameRef {
  TextComponent? healthText;
  TextComponent? scoreText;
  TextComponent? passesLeftText;
  TextComponent? enemiesPassedText;
  FpsTextComponent? fpsText;

  // Flag to check if game UI has been initialized
  bool _gameUIInitialized = false;

  @override
  Future<void> onLoad() async {
    print('UIManager: onLoad started');
    // Only add FPS text initially, as it's always visible
    fpsText = FpsTextComponent(
      position: Vector2(game.size.x - 50, 10),
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
    await add(fpsText!);
    print('UIManager: onLoad finished');
  }

  // New method to initialize game UI
  void initializeGameUI() {
    if (_gameUIInitialized) return;

    print('UIManager: Initializing game UI');
    healthText = TextComponent(
      text: 'Health: ${game.player.health}',
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 16)),
    )..position = Vector2(10, 10);

    scoreText = TextComponent(
      text: 'Score: 0',
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 16)),
    )..position = Vector2(10, 30);

    passesLeftText = TextComponent(
      text: 'Passes Left: ${GameStateManager.maxEnemiesPassed}',
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 16)),
    )..position = Vector2(10, 50);

    enemiesPassedText = TextComponent(
      text: 'Enemies Passed: 0',
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 16)),
    )..position = Vector2(10, 70);

    addAll([healthText!, scoreText!, passesLeftText!, enemiesPassedText!]);
    _gameUIInitialized = true;
    print('UIManager: Game UI initialized');
  }

  void updateHealth(int health) {
    healthText?.text = 'Health: $health';
  }

  void updateScore(int score) {
    scoreText?.text = 'Score: $score';
  }

  void updateEnemiesPassed(int enemiesPassed) {
    enemiesPassedText?.text = 'Enemies Passed: $enemiesPassed';
    passesLeftText?.text = 'Passes Left: ${GameStateManager.maxEnemiesPassed - enemiesPassed}';
  }

  @override
  void update(double dt) {
    super.update(dt);
    fpsText?.position = Vector2(game.size.x - 50, 10);
  }

  void reset() {
    if (!_gameUIInitialized) return;
    
    healthText?.text = 'Health: ${gameRef.player.health}';
    scoreText?.text = 'Score: 0';
    enemiesPassedText?.text = 'Enemies Passed: 0';
    passesLeftText?.text = 'Passes Left: ${GameStateManager.maxEnemiesPassed}';
  }
}