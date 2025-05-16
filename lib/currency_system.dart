import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:zazam/player.dart';
import 'space_shooter_game.dart';
import 'game_reference.dart';

// Simple class to track scrap currency
class ScrapManager {
  int _scrapAmount = 0;
  
  int get scrapAmount => _scrapAmount;
  
  void addScrap(int amount) {
    _scrapAmount += amount;
  }
  
  void reset() {
    _scrapAmount = 0;
  }
}

// Component for scrap collectibles that drop from enemies
class ScrapComponent extends SpriteAnimationComponent with HasGameRef<SpaceShooterGame>, GameRef, CollisionCallbacks {
  static const double _baseSize = 20.0;
  final double _floatSpeed = 2.0;
  final double _floatAmplitude = 5.0;
  final double _rotationSpeed = 0.5;
  final double _magnetDistance = 100.0;
  final double _magnetSpeed = 150.0;
  
  late double _initialY;
  double _timeAlive = 0.0;
  final int value;
  
  ScrapComponent({
    required Vector2 position,
    this.value = 1,
    double size = _baseSize,
  }) : super(
    position: position,
    size: Vector2.all(size),
    anchor: Anchor.center,
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load scrap animation
    try {
      animation = await gameRef.loadSpriteAnimation(
        'powerup_speedBoost.png',  // Use an existing sprite as fallback
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.1,
          textureSize: Vector2.all(32),
          loop: true,
        ),
      );
    } catch (e) {
      print('Error loading scrap animation: $e');
    }
    
    _initialY = position.y;
    
    // Add collision detection
    add(CircleHitbox()..collisionType = CollisionType.passive);
    
    // Auto-remove after 10 seconds if not collected
    add(RemoveEffect(delay: 10));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    _timeAlive += dt;
    
    // Floating animation
    position.y = _initialY + sin(_timeAlive * _floatSpeed) * _floatAmplitude;
    
    // Slow rotation
    angle += _rotationSpeed * dt;
    
    // Check for player proximity for magnet effect
    final player = gameRef.player;
    if (player != null && player.isMounted) {
      final distance = position.distanceTo(player.position);
      if (distance < _magnetDistance) {
        // Move toward player (magnet effect)
        final direction = (player.position - position).normalized();
        position += direction * _magnetSpeed * dt;
      }
    }
  }
  
  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is Player) {
      // Collect the scrap
      collectScrap();
    }
  }
  
  void collectScrap() {
    // Add scrap to player's currency
    gameRef.addScrap(value);
    
    // Play collection sound
    try {
      audio.playSfx('collect.mp3');
    } catch (e) {
      print('Error playing sound: $e');
    }
    
    // Just remove the component
    removeFromParent();
  }
}
