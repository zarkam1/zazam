import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'player.dart';
import 'game_reference.dart';
import 'space_shooter_game.dart';

enum PowerUpType {
  speedBoost,
  rapidFire,
  shield,
  extraLife,
}

class PowerUp extends SpriteComponent with HasGameRef<SpaceShooterGame>, GameRef, CollisionCallbacks {
  final PowerUpType type;
  final double _rotationSpeed = 1.0;
  
  PowerUp({
    required this.type,
    required Vector2 position,
  }) : super(
    position: position,
    size: Vector2.all(30),
    anchor: Anchor.center,
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load appropriate sprite based on type
    String assetPath;
    switch (type) {
      case PowerUpType.speedBoost:
        assetPath = 'speed_powerup.png';
        break;
      case PowerUpType.rapidFire:
        assetPath = 'rapid_fire_powerup.png';
        break;
      case PowerUpType.shield:
        assetPath = 'shield_powerup.png';
        break;
      case PowerUpType.extraLife:
        assetPath = 'life_powerup.png';
        break;
    }
    
    try {
      sprite = await gameRef.loadSprite(assetPath);
    } catch (e) {
      // Fallback to a colored rectangle if sprite can't be loaded
      final paint = Paint();
      switch (type) {
        case PowerUpType.speedBoost:
          paint.color = Colors.yellow;
          break;
        case PowerUpType.rapidFire:
          paint.color = Colors.red;
          break;
        case PowerUpType.shield:
          paint.color = Colors.blue;
          break;
        case PowerUpType.extraLife:
          paint.color = Colors.green;
          break;
      }
      
      final renderRect = RectangleComponent(
        size: size,
        paint: paint,
      );
      add(renderRect);
    }
    
    // Add collision detection
    add(CircleHitbox()..collisionType = CollisionType.passive);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Rotate the powerup
    angle += _rotationSpeed * dt;
    
    // Move downward
    position.y += 50 * dt;
    
    // Remove if off screen
    if (position.y > gameRef.size.y + size.y) {
      removeFromParent();
    }
  }
  
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    
    if (other is Player) {
      // Apply powerup effect
      switch (type) {
        case PowerUpType.speedBoost:
          other.applySpeedBoost(5.0);
          break;
        case PowerUpType.rapidFire:
          other.applyRapidFire(5.0);
          break;
        case PowerUpType.shield:
          other.applyShield(10.0);
          break;
        case PowerUpType.extraLife:
          other.addLife();
          break;
      }
      
      // Remove the powerup
      removeFromParent();
      
      // Play sound effect
      gameRef.audioManager.playSfx('powerup.mp3');
    }
  }
}
