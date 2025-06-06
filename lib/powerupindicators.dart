import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'player.dart';
import 'space_shooter_game.dart';

class PowerUpIndicators extends PositionComponent with HasGameRef<SpaceShooterGame> {
  late PowerUpIndicator speedBoost;
  late PowerUpIndicator rapidFire;
  late PowerUpIndicator shield;

  PowerUpIndicators() : super(position: Vector2(10, 340), size: Vector2(100, 120));

  @override
  Future<void> onLoad() async {
    speedBoost = PowerUpIndicator('Speed', Vector2(0, 0), size: Vector2(100, 30));
    rapidFire = PowerUpIndicator('Rapid', Vector2(0, 50), size: Vector2(100, 30));
    shield = PowerUpIndicator('Shield', Vector2(0, 100), size: Vector2(100, 30));

    await addAll([speedBoost, rapidFire, shield]);
  }

  @override
  void render(Canvas canvas) {
    final opacity = gameRef.gameStateManager.state == GameState.playing ? 1.0 : 0.0;
    speedBoost.setOpacity(opacity);
    rapidFire.setOpacity(opacity);
    shield.setOpacity(opacity);
    super.render(canvas);
  }

  void updateIndicators(Player player) {
    speedBoost.updateProgress(player.speedBoostTimeLeft / Player.speedBoostDuration);
    rapidFire.updateProgress(player.rapidFireTimeLeft / Player.rapidFireDuration);
    shield.updateProgress(player.shieldTimeLeft / Player.shieldDuration);
  }

  void resetIndicators() {
    speedBoost.updateProgress(0);
    rapidFire.updateProgress(0);
    shield.updateProgress(0);
  }
}
class PowerUpIndicator extends PositionComponent with HasGameRef<SpaceShooterGame> {
  final String powerUpName;
  late RectangleComponent background;
  late RectangleComponent bar;
  late TextComponent label;
  double _progress = 0.0;

  PowerUpIndicator(this.powerUpName, Vector2 position, {super.size}) : super(position: position) {
    background = RectangleComponent(
      size: Vector2(size.x, size.y * 0.7),
      paint: Paint()..color = const Color.fromARGB(255, 5, 5, 5),
    );

    bar = RectangleComponent(
      size: Vector2(0, size.y * 0.7),
      paint: Paint()..color = Color.fromARGB(255, 196, 13, 13),
    );

    label = TextComponent(
      text: powerUpName,
      textRenderer: TextPaint(style: TextStyle(color: Color.fromARGB(255, 214, 204, 204), fontSize: size.y * 0.7)),
    );
  }

  @override
  Future<void> onLoad() async {
    await addAll([background, bar, label]);
    label.position = Vector2(0, size.y * 0.7);
  }

  void updateProgress(double progress) {
    _progress = progress.clamp(0.0, 1.0);
    bar.size.x = size.x * _progress;
  }

  void setOpacity(double opacity) {
    background.paint.color = background.paint.color.withOpacity(opacity);
    bar.paint.color = bar.paint.color.withOpacity(opacity);
    
    // Update the label's text color opacity
    if (label.textRenderer is TextPaint) {
      final TextPaint textPaint = label.textRenderer as TextPaint;
      final TextStyle currentStyle = textPaint.style;
      label.textRenderer = TextPaint(
        style: currentStyle.copyWith(
          color: currentStyle.color?.withOpacity(opacity),
        ),
      );
    }
  }
}