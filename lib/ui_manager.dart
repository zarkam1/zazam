import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:zazam/game_state_manager.dart';
import 'package:zazam/player.dart';
import 'space_shooter_game.dart';
import 'game_reference.dart';
import 'level_management.dart';
import 'workaround.dart'; // Use workaround for SimpleNeonText
import 'font_renderer.dart';

class UIManager extends Component with HasGameRef<SpaceShooterGame>, GameRef {
  // UI Components
  TextComponent? healthText;
  TextComponent? scoreText;
  Component? passesLeftText;
  Component? enemiesPassedText;
  Component? livesText;
  Component? objectiveText;
  FpsTextComponent? fpsText;
  TextComponent? shieldEnergyText;
  RectangleComponent? healthBar;
  RectangleComponent? healthBackground;
  RectangleComponent? shieldEnergyBar;
  RectangleComponent? shieldEnergyBackground;
  bool _gameUIInitialized = false;
  
  // Level briefing components
  RectangleComponent? _briefingBackground;
  TextComponent? _levelTitleText;
  TextComponent? _briefingText;
  Timer? _briefingTimer;
  bool _showingBriefing = false;
  static const double briefingDuration = 5.0; // seconds to show briefing

  @override
  Future<void> onLoad() async {
    print('UIManager: onLoad started');
    fpsText = FpsTextComponent(
      position: Vector2(game.size.x - 50, 10),
      textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
    await add(fpsText!);
    print('UIManager: onLoad finished');
  }

  void initializeGameUI() {
    if (_gameUIInitialized) return;

    print('UIManager: Initializing game UI');
    
    // Create stylized UI bars with neon glow effects
    
    // Health bar background with neon border
    healthBackground = RectangleComponent(
      size: Vector2(100, 10),
      position: Vector2(10, 10),
      paint: Paint()..color = Colors.black.withOpacity(0.5),
    );
    
    // Add neon border to health background
    final healthBorder = RectangleComponent(
      size: Vector2(100, 10),
      position: Vector2.zero(),
      paint: Paint()
        ..color = Colors.greenAccent.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    healthBackground!.add(healthBorder);
    
    // Health bar with gradient
    final healthGradient = LinearGradient(
      colors: [
        Colors.green.shade300,
        Colors.greenAccent.shade200,
      ],
      stops: const [0.0, 1.0],
    );
    
    healthBar = RectangleComponent(
      size: Vector2(100, 8),
      position: Vector2(1, 1),
      paint: Paint()..shader = healthGradient.createShader(
        Rect.fromLTWH(0, 0, 100, 8),
      ),
    );
    
    // Use SimpleNeonText for health label
    final healthLabel = SimpleNeonText(
      text: 'HEALTH',
      color: Colors.greenAccent,
      fontSize: 16,
      
      
      position: Vector2(120, 8),
    );
    
    // Lives display with neon styling
    livesText = StylizedTextRenderer.createPulsingText(
      text: 'LIVES: ${game.player.lives}',
      style: StylizedTextRenderer.hudStyle,
      position: Vector2(10, 30),
      pulseMin: 0.8,
      pulseMax: 1.0,
    );

    // Score with neon styling
    scoreText = SimpleNeonText(
      text: 'SCORE: 0',
      color: Colors.purpleAccent,
      fontSize: 16,
      
      
      position: Vector2(10, 50),
    );
    
    // Objective text with neon styling
    objectiveText = StylizedTextRenderer.createPulsingText(
      text: 'OBJECTIVE: SURVIVE',
      style: StylizedTextRenderer.subtitleStyle,
      position: Vector2(10, 70),
    );

    // Passes left with neon styling
    passesLeftText = StylizedTextRenderer.createPulsingText(
      text: 'PASSES LEFT: ${GameStateManager.maxEnemiesPassed}',
      style: StylizedTextRenderer.hudStyle,
      position: Vector2(10, 90),
    );

    // Enemies passed with neon styling
    enemiesPassedText = StylizedTextRenderer.createPulsingText(
      text: 'ENEMIES PASSED: 0',
      style: StylizedTextRenderer.hudStyle,
      position: Vector2(10, 110),
    );

    // Shield energy bar with neon styling
    shieldEnergyBackground = RectangleComponent(
      size: Vector2(100, 10),
      position: Vector2(10, 130),
      paint: Paint()..color = Colors.black.withOpacity(0.5),
    );
    
    // Add neon border to shield background
    final shieldBorder = RectangleComponent(
      size: Vector2(100, 10),
      position: Vector2.zero(),
      paint: Paint()
        ..color = Colors.blueAccent.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    shieldEnergyBackground!.add(shieldBorder);

    // Shield bar with gradient
    final shieldGradient = LinearGradient(
      colors: [
        Colors.blue.shade300,
        Colors.blueAccent.shade200,
      ],
      stops: const [0.0, 1.0],
    );
    
    shieldEnergyBar = RectangleComponent(
      size: Vector2(0, 8),
      position: Vector2(1, 1),
      paint: Paint()..shader = shieldGradient.createShader(
        Rect.fromLTWH(0, 0, 100, 8),
      ),
    );

    // Shield text with neon styling
    shieldEnergyText = SimpleNeonText(
      text: 'SHIELD: 0%',
      color: Colors.blueAccent,
      fontSize: 16,
      
      
      position: Vector2(120, 128),
    );

    // Add components safely with null checks
    if (healthBackground != null) add(healthBackground!);
    if (healthBar != null) healthBackground!.add(healthBar!);
    add(healthLabel);
    if (livesText != null) add(livesText!);
    if (scoreText != null) add(scoreText!);
    if (objectiveText != null) add(objectiveText!);
    if (passesLeftText != null) add(passesLeftText!);
    if (enemiesPassedText != null) add(enemiesPassedText!);
    if (shieldEnergyBackground != null) add(shieldEnergyBackground!);
    if (shieldEnergyBar != null) shieldEnergyBackground!.add(shieldEnergyBar!);
    if (shieldEnergyText != null) add(shieldEnergyText!);
    
    _gameUIInitialized = true;
    print('UIManager: Game UI initialized with neon styling');
  }

  void updateHealth(double healthPercentage) {
    if (healthBar != null) {
      healthBar!.size.x = 98 * healthPercentage;
      
      // Change color based on health percentage
      final Paint paint = healthBar!.paint;
      final LinearGradient gradient;
      
      if (healthPercentage > 0.6) {
        gradient = LinearGradient(
          colors: [Colors.green.shade300, Colors.greenAccent.shade200],
          stops: const [0.0, 1.0],
        );
      } else if (healthPercentage > 0.3) {
        gradient = LinearGradient(
          colors: [Colors.yellow.shade300, Colors.yellowAccent.shade200],
          stops: const [0.0, 1.0],
        );
      } else {
        gradient = LinearGradient(
          colors: [Colors.red.shade300, Colors.redAccent.shade200],
          stops: const [0.0, 1.0],
        );
      }
      
      paint.shader = gradient.createShader(
        Rect.fromLTWH(0, 0, 98 * healthPercentage, 8),
      );
    }
  }
  
  void updateLives(int lives) {
    if (livesText is TextComponent) {
      (livesText as TextComponent).text = 'LIVES: $lives';
    } else if (livesText is SimpleNeonText) {
      (livesText as SimpleNeonText).setText('LIVES: $lives');
    }
  }
  
  void updateObjective(String objective, double progress) {
    final progressPercent = (progress * 100).toInt();
    if (objectiveText is TextComponent) {
      (objectiveText as TextComponent).text = 'OBJECTIVE: $objective - $progressPercent%';
    } else if (objectiveText is SimpleNeonText) {
      (objectiveText as SimpleNeonText).setText('OBJECTIVE: $objective - $progressPercent%');
    }
  }

  void updateScore(int score) {
    if (scoreText is SimpleNeonText) {
      (scoreText as SimpleNeonText).setText('SCORE: $score');
    } else if (scoreText is TextComponent) {
      (scoreText as TextComponent).text = 'SCORE: $score';
    }
  }

  void updateEnemiesPassed(int enemiesPassed) {
    if (enemiesPassedText is TextComponent) {
      (enemiesPassedText as TextComponent).text = 'ENEMIES PASSED: $enemiesPassed';
    } else if (enemiesPassedText is SimpleNeonText) {
      (enemiesPassedText as SimpleNeonText).setText('ENEMIES PASSED: $enemiesPassed');
    }

    final passesLeft = GameStateManager.maxEnemiesPassed - enemiesPassed;
    if (passesLeftText is TextComponent) {
      (passesLeftText as TextComponent).text = 'PASSES LEFT: $passesLeft';
    } else if (passesLeftText is SimpleNeonText) {
      (passesLeftText as SimpleNeonText).setText('PASSES LEFT: $passesLeft');
    }
  }

  void updateShieldEnergy(double energy) {
    final percentage = (energy / Player.maxShieldEnergy * 100).round();
    
    if (shieldEnergyText is SimpleNeonText) {
      (shieldEnergyText as SimpleNeonText).setText('SHIELD: $percentage%');
    } else if (shieldEnergyText is TextComponent) {
      (shieldEnergyText as TextComponent).text = 'SHIELD: $percentage%';
    }
    
    if (shieldEnergyBar != null) {
      shieldEnergyBar!.size.x = 98 * (energy / Player.maxShieldEnergy);
    }
  }

  @override
  void render(Canvas canvas) {
    final opacity = gameRef.gameStateManager.state == GameState.playing ? 1.0 : 0.0;
    setUIOpacity(opacity);
    super.render(canvas);
  }

  /// Shows a level briefing overlay with the given text
  void showLevelBriefing(String briefingText, int levelNumber) {
    print('UIManager: Showing level briefing for level $levelNumber');
    
    // Remove any existing briefing components
    _briefingBackground?.removeFromParent();
    _levelTitleText?.removeFromParent();
    _briefingText?.removeFromParent();
    
    // Create a semi-transparent background with neon border
    _briefingBackground = RectangleComponent(
      size: Vector2(gameRef.size.x * 0.8, gameRef.size.y * 0.3),
      position: Vector2(gameRef.size.x * 0.1, gameRef.size.y * 0.35),
      paint: Paint()..color = Colors.black.withOpacity(0.8),
    );
    
    // Add a glowing border to the background
    final borderPaint = Paint()
      ..color = Colors.purpleAccent.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final borderComponent = RectangleComponent(
      size: Vector2(gameRef.size.x * 0.8, gameRef.size.y * 0.3),
      position: Vector2.zero(),
      paint: borderPaint,
    );
    
    // Add pulsing effect to the border
    borderComponent.add(
      ColorEffect(
        Colors.purpleAccent.withOpacity(0.3),
        EffectController(
          duration: 1.5,
          reverseDuration: 1.5,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
    
    _briefingBackground!.add(borderComponent);
    
    // Option 1: Use SimpleNeonText component for title
    final neonTitle = SimpleNeonText(
      text: 'LEVEL $levelNumber',
      color: Colors.purpleAccent,
      fontSize: 32,
      
      
      position: Vector2(gameRef.size.x * 0.4, 10),
      anchor: Anchor.topCenter,
    );
    
    // Option 2: Use StylizedTextRenderer for briefing text
    final typingBriefing = StylizedTextRenderer.createTypingText(
      text: briefingText,
      style: StylizedTextRenderer.bodyStyle,
      position: Vector2(20, 60),
      charDelay: 0.03, // Type each character with a slight delay
    );
    
    // Add components to the game
    add(_briefingBackground!);
    _briefingBackground!.add(neonTitle);
    _briefingBackground!.add(typingBriefing);
    
    // Set up timer to hide the briefing after a delay
    _briefingTimer?.stop();
    _briefingTimer = Timer(
      briefingDuration + briefingText.length * 0.03, // Add time for typing animation
      onTick: _hideBriefing,
    );
    _briefingTimer!.start();
    _showingBriefing = true;
  }
  
  /// Hides the level briefing overlay
  void _hideBriefing() {
    print('UIManager: Hiding level briefing');
    _briefingBackground?.removeFromParent();
    _levelTitleText?.removeFromParent();
    _briefingText?.removeFromParent();
    _showingBriefing = false;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update briefing timer if active
    if (_showingBriefing && _briefingTimer != null) {
      _briefingTimer!.update(dt);
    }
    
    if (gameRef.gameStateManager.state == GameState.playing) {
      if (gameRef.player != null && gameRef.player.isMounted) {
        updateHealth(gameRef.player.currentHealth / gameRef.player.maxHealth);
        updateLives(gameRef.player.lives);
      }
      updateScore(gameRef.gameStateManager.score);
      updateEnemiesPassed(gameRef.gameStateManager.enemiesPassed);
      
      // Get objective information from level manager
      try {
        if (gameRef.levelManager == null) {
          updateObjective('Survive', 0.5);
          return;
        }
        
        final currentLevel = gameRef.levelManager!.currentLevel;
        String objectiveText = 'Survive';
        double progress = 0.5;
        
        switch (currentLevel.objectiveType) {
          case ObjectiveType.SURVIVE:
            final targetTime = currentLevel.objectiveValue as int;
            objectiveText = 'Survive for ${targetTime}s';
            progress = gameRef.objectiveTimer / targetTime;
            break;
          case ObjectiveType.DESTROY_COUNT:
            final targetCount = currentLevel.objectiveValue as int;
            objectiveText = 'Destroy ${targetCount} enemies';
            progress = gameRef.enemiesDestroyedInLevel / targetCount;
            break;
          default:
            objectiveText = 'Survive';
        }
        
        updateObjective(objectiveText, progress.clamp(0.0, 1.0));
      } catch (e) {
        print('Error updating objective: $e');
        updateObjective('Survive', 0.5);
      }
    }
    fpsText?.position = Vector2(game.size.x - 50, 10);
  }

  void setUIOpacity(double opacity) {
    setTextComponentOpacity(healthText, opacity);
    if (livesText is TextComponent) setTextComponentOpacity(livesText as TextComponent, opacity);
    if (scoreText is TextComponent) setTextComponentOpacity(scoreText as TextComponent, opacity);
    if (objectiveText is TextComponent) setTextComponentOpacity(objectiveText as TextComponent, opacity);
    if (passesLeftText is TextComponent) setTextComponentOpacity(passesLeftText as TextComponent, opacity);
    if (enemiesPassedText is TextComponent) setTextComponentOpacity(enemiesPassedText as TextComponent, opacity);
    if (shieldEnergyText is TextComponent) setTextComponentOpacity(shieldEnergyText as TextComponent, opacity);

    if (healthBackground != null) {
      healthBackground!.paint.color = Colors.grey.withOpacity(opacity * 0.5);
    }
    if (shieldEnergyBackground != null) {
      shieldEnergyBackground!.paint.color = Colors.grey.withOpacity(opacity * 0.5);
    }
  }

  void setTextComponentOpacity(TextComponent? textComponent, double opacity) {
    if (textComponent != null && textComponent.textRenderer is TextPaint) {
      final TextPaint textPaint = textComponent.textRenderer as TextPaint;
      final TextStyle currentStyle = textPaint.style;
      textComponent.textRenderer = TextPaint(
        style: currentStyle.copyWith(
          color: currentStyle.color?.withOpacity(opacity),
        ),
      );
    }
  }

  void reset() {
    if (!_gameUIInitialized) return;
    
    updateHealth(1.0); // Full health
    updateLives(gameRef.player.lives);

    // Reset score
    if (scoreText is SimpleNeonText) {
      (scoreText as SimpleNeonText).setText('SCORE: 0');
    } else if (scoreText is TextComponent) {
      (scoreText as TextComponent).text = 'SCORE: 0';
    }

    // Reset enemiesPassedText
    if (enemiesPassedText is TextComponent) {
      (enemiesPassedText as TextComponent).text = 'ENEMIES PASSED: 0';
    } else if (enemiesPassedText is SimpleNeonText) {
      (enemiesPassedText as SimpleNeonText).setText('ENEMIES PASSED: 0');
    }

    // Reset passesLeftText
    if (passesLeftText is TextComponent) {
      (passesLeftText as TextComponent).text = 'PASSES LEFT: ${GameStateManager.maxEnemiesPassed}';
    } else if (passesLeftText is SimpleNeonText) {
      (passesLeftText as SimpleNeonText).setText('PASSES LEFT: ${GameStateManager.maxEnemiesPassed}');
    }

    updateObjective('Survive', 0.0);
  }
}