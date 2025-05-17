import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_reference.dart';
import 'bullets.dart';
import 'powerups.dart';
import 'enemies.dart';
import 'space_shooter_game.dart';
import 'shader_effects.dart';

class Player extends SpriteAnimationComponent
    with HasGameRef<SpaceShooterGame>,GameRef, CollisionCallbacks {
  Player() : super(size: Vector2(40, 54));

  bool _isInvulnerable = false;
  double _invulnerabilityTimer = 0;
  static const double invulnerabilityDuration = 1.5; // Seconds of invulnerability after hit

  Vector2 velocity = Vector2.zero();
  Vector2 acceleration = Vector2.zero();
  final double thrust = 00; // Adjust as needed
  bool isShooting = false;
  double shootCooldown = 0;
  static const shootInterval = 0.5;
  // New health system
  double maxHealth = 100.0;
  double currentHealth = 100.0;
  int lives = 3;
  static const int maxLives = 5;
  static const speed = 300.0;
  double speedMultiplier = 1.0;
  static const speedBoostDuration = 5.0;
  double speedBoostTimeLeft = 0.0;
  static const rapidFireDuration = 5.0;
  double rapidFireTimeLeft = 0.0;
  static const shieldDuration = 10.0;
  double shieldTimeLeft = 0.0;

  double shieldEnergy = 0.0;
  static const double maxShieldEnergy = 100.0;
  static const double shieldDrainRate = 25.0; // Points per second
  static const double shieldRechargeRate = 5.0; // Points per second when not in use
  bool isShieldActive = false;

  late SpriteAnimationComponent shieldAnimation;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    try {
      print('Player: onLoad started');
      await _initializePlayer();
      print('Player: onLoad completed');
      
      // Set initial position and anchor
      position = gameRef.size / 2;
      anchor = Anchor.center;
      
      // Add collision hitbox
      add(RectangleHitbox()..collisionType = CollisionType.active);
      
      // Add thruster effect
      final thruster = ThrusterEffect(
        position: Vector2(size.x / 2, size.y - 5),
        size: Vector2(20, 30),
        color: Colors.blue,
      );
      add(thruster);
    } catch (e, stackTrace) {
      print('Error in Player onLoad: $e');
      print('Stack trace: $stackTrace');
    }

    final shieldSpriteAnimation = await gameRef.loadSpriteAnimation(
      'shield_animation.png',
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.1,
        textureSize: Vector2(32, 32),
        loop: true,
      ),
    );

    shieldAnimation = SpriteAnimationComponent(
      animation: shieldSpriteAnimation,
      size: Vector2(size.x * 1.2, size.y * 1.2),
    );
    shieldAnimation.anchor = Anchor.center;
    shieldAnimation.position = size / 2;
    shieldAnimation.opacity = 0;
    add(shieldAnimation);
  }
    Future<void> _initializePlayer() async {
      try {
        print('Player: Loading sprite...');
        
        // First try to load directly as a Sprite
        try {
          final sprite = await Sprite.load('new/player_256.png');
          animation = SpriteAnimation.spriteList(
            [sprite],
            stepTime: 1,
          );
          print('Player: Successfully loaded sprite directly');
        } catch (spriteError) {
          print('Player: Direct sprite loading failed: $spriteError');
          
          // Fallback to animation loading
          try {
            animation = SpriteAnimation.fromFrameData(
              await gameRef.images.load('new/player_256.png'),
              SpriteAnimationData.sequenced(
                amount: 1,
                stepTime: 1,
                textureSize: Vector2.all(64),
              ),
            );
            print('Player: Successfully loaded via animation');
          } catch (animError) {
            print('Player: Animation loading also failed: $animError');
            throw animError; // Re-throw to be caught by outer try-catch
          }
        }
        
        // Adjust size for the larger player sprite if needed
        size = Vector2(80, 80);
        print('Player: Sprite loaded successfully with size $size');
      } catch (e) {
        print('Error loading player sprite: $e');
        // Create a fallback colored rectangle
        final paint = Paint()..color = Colors.blue;
        final renderRect = RectangleComponent(
          size: size,
          paint: paint,
        );
        add(renderRect);
      }
    }   

  void resetHealth() {
    currentHealth = maxHealth;
    lives = 3;
  }

  // Check if player is alive
  bool get isAlive => currentHealth > 0 && lives > 0;
  
  // Take damage from enemies or projectiles
  void takeDamage([double amount = 20.0]) {
    try {
      if (_isInvulnerable) return;
      
      currentHealth = max(0, currentHealth - amount);
      gameRef.uiManager.updateHealth(currentHealth / maxHealth);
      
      if (currentHealth <= 0) {
        lives--;
        if (lives <= 0) {
          // Game over
          removeFromParent();
          gameState.gameOver();
        } else {
          // Reset health but lose a life
          currentHealth = maxHealth;
          _startInvulnerabilityPeriod();
        }
      }
    } catch (e) {
      print('Error in takeDamage: $e');
    }
  }
  
  // Heal the player
  void heal(double amount) {
    currentHealth = min(maxHealth, currentHealth + amount);
    gameRef.uiManager.updateHealth(currentHealth / maxHealth);
  }


void reset() {
  position = gameRef.size / 2;
  currentHealth = maxHealth;
  lives = 3;
  resetPowerups();
  shootCooldown = 0;
  isShooting = false;

  _isInvulnerable = false;
  _invulnerabilityTimer = 0;
  opacity = 1.0;
  
  gameRef.uiManager.updateHealth(currentHealth / maxHealth);
  gameRef.uiManager.updateLives(lives);
}

  void resetPowerups() {
    speedMultiplier = 1.0;
    speedBoostTimeLeft = 0.0;
    rapidFireTimeLeft = 0.0;
    shieldTimeLeft = 0.0;
    shieldAnimation.opacity = 0;
  }
void updatePowerUps(double dt) {
    if (speedBoostTimeLeft > 0) {
      speedBoostTimeLeft -= dt;
      if (speedBoostTimeLeft <= 0) {
        speedMultiplier = 1.0;
      }
    }
    if (rapidFireTimeLeft > 0) {
      rapidFireTimeLeft -= dt;
    }
    if (shieldTimeLeft > 0) {
      shieldTimeLeft -= dt;
    }
  }
  @override
  void update(double dt) {
    super.update(dt);
    shootCooldown -= dt;
  if (_isInvulnerable) {
    _invulnerabilityTimer -= dt;
    if (_invulnerabilityTimer <= 0) {
      _isInvulnerable = false;
      opacity = 1.0;
    } else {
      // Optional: Make the ship blink while invulnerable
      opacity = ((_invulnerabilityTimer * 10).floor() % 2 == 0) ? 0.5 : 0.8;
    }
 // Handle shield energy drain/recharge
    if (isShieldActive && shieldEnergy > 0) {
      shieldEnergy = max(0, shieldEnergy - shieldDrainRate * dt);
      if (shieldEnergy <= 0) {
        isShieldActive = false;
        shieldAnimation.opacity = 0;
      }
    } else if (!isShieldActive && shieldEnergy < maxShieldEnergy) {
      shieldEnergy = min(maxShieldEnergy, shieldEnergy + shieldRechargeRate * dt);
    }
    
    gameRef.uiManager.updateShieldEnergy(shieldEnergy);
    }

 

    if (shootCooldown <= 0) {
      isShooting = false;
    }
    updatePowerUps(dt);
    shieldAnimation.opacity = shieldTimeLeft > 0 ? 1 : 0;
  }

  

  void move(Vector2 movement) {
    position += movement * speedMultiplier;
     velocity = movement * speed;
    position.clamp(
      Vector2.zero() + size / 2,
      gameRef.size - size / 2,
    );
  }

  void shoot() {
    if (shootCooldown <= 0) {
      isShooting = true;
      gameRef.add(Bullet(position: position.clone() + Vector2(0, -height / 2)));
      audio.playSfx('laser.mp3');
      shootCooldown = rapidFireTimeLeft > 0 ? shootInterval / 2 : shootInterval;
    }
  }

  void applySpeedBoost(double duration) {
    speedMultiplier = 2.0;
    speedBoostTimeLeft = duration;
  }

  void applyRapidFire(double duration) {
    rapidFireTimeLeft = duration;
  }

  void applyShield(double duration) {
    shieldTimeLeft = duration;
    shieldAnimation.opacity = 1;
    print('Shield activated for $duration seconds');
  }

  void addLife() {
    lives = min(lives + 1, maxLives);
    gameRef.uiManager.updateLives(lives);
  }

@override
void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy && !_isInvulnerable) {
      if (shieldTimeLeft > 0) {
        // If shield is active, don't take damage
        other.removeFromParent();
        audio.playSfx('shield_hit.mp3');
      } else {
        // Take damage but don't die instantly
        takeDamage(20.0);
        _startInvulnerabilityPeriod();
        audio.playSfx('player_hit.mp3');
      }
    } else if (other is EnemyBullet) {
      if (shieldTimeLeft <= 0) {
        takeDamage(20.0);
        other.removeFromParent();
        audio.playSfx('player_hit.mp3');
      } else {
        other.removeFromParent();
        audio.playSfx('shield_hit.mp3');
      }
    }
  }
 void toggleShield() {
    if (!isShieldActive && shieldEnergy > 0) {
      isShieldActive = true;
      shieldAnimation.opacity = 1;
      audio.playSfx('shield_hit.mp3');
    } else {
      isShieldActive = false;
      shieldAnimation.opacity = 0;
    }
  }

  void addShieldEnergy(double amount) {
    shieldEnergy = (shieldEnergy + amount).clamp(0, maxShieldEnergy);
    gameRef.uiManager.updateShieldEnergy(shieldEnergy);
  }
void _startInvulnerabilityPeriod() {
  _isInvulnerable = true;
  _invulnerabilityTimer = invulnerabilityDuration;
  opacity = 0.5; // Visual indicator that player is invulnerable
}
 
  }