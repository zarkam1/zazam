import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'player.dart';

class PowerUpIndicators extends PositionComponent with HasGameRef {
  late PowerUpIndicator speedBoost;
  late PowerUpIndicator rapidFire;
  late PowerUpIndicator shield;

  PowerUpIndicators() : super(position: Vector2(10, 50), size: Vector2(100, 120));

  @override
  Future<void> onLoad() async {
    speedBoost = PowerUpIndicator('Speed', Vector2(0, 0), size: Vector2(100, 30));
    rapidFire = PowerUpIndicator('Rapid', Vector2(0, 40), size: Vector2(100, 30));
    shield = PowerUpIndicator('Shield', Vector2(0, 80), size: Vector2(100, 30));

    await addAll([speedBoost, rapidFire, shield]);
  }

  void updateIndicators(Player player) {
    speedBoost.updateProgress(player.speedBoostTimeLeft / Player.speedBoostDuration);
    rapidFire.updateProgress(player.rapidFireTimeLeft / Player.rapidFireDuration);
    shield.updateProgress(player.shieldTimeLeft / Player.shieldDuration);
  }
}

class PowerUpIndicator extends PositionComponent {
  final String powerUpName;
  late RectangleComponent background;
  late RectangleComponent bar;
  late TextComponent label;
  double _progress = 0.0;

  PowerUpIndicator(this.powerUpName, Vector2 position, {super.size}) : super(position: position) {
    background = RectangleComponent(
      size: Vector2(size.x, size.y * 0.7),
      paint: Paint()..color = Colors.grey,
    );

    bar = RectangleComponent(
      size: Vector2(0, size.y * 0.7),
      paint: Paint()..color = Colors.blue,
    );

    label = TextComponent(
      text: powerUpName,
      textRenderer: TextPaint(style: TextStyle(color: BasicPalette.white.color, fontSize: size.y * 0.3)),
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
}