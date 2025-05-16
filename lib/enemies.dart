import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'game_reference.dart';
import 'particle_explosion.dart';
import 'player.dart';
import 'space_shooter_game.dart';
import 'bullets.dart';
import 'currency_system.dart';

class HealthBarComponent extends PositionComponent {
  final int maxHealth;
  int currentHealth;
  static const double barHeight = 5.0;
  static const double borderWidth = 1.0;

  HealthBarComponent({
    required this.maxHealth,
    required this.currentHealth,
    required Vector2 size,
  }) : super(
    size: Vector2(size.x, barHeight),
  );

  @override
  void render(Canvas canvas) {
    // Draw border
    canvas.drawRect(
      size.toRect(),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
    );

    // Draw health fill
    final healthPercentage = currentHealth / maxHealth;
    canvas.drawRect(
      Rect.fromLTWH(borderWidth, borderWidth, 
        (size.x - 2 * borderWidth) * healthPercentage, 
        size.y - 2 * borderWidth),
      Paint()
        ..color = _getHealthColor(healthPercentage)
        ..style = PaintingStyle.fill
    );
  }

  Color _getHealthColor(double percentage) {
    if (percentage > 0.6) return Colors.green;
    if (percentage > 0.3) return Colors.yellow;
    return Colors.red;
  }

  void updateHealth(int newHealth) {
    currentHealth = newHealth;
  }
}

abstract class Enemy extends SpriteAnimationComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks, GameRef {
  double speed;
  bool countsAsPassed = false;
  int health;
  int scoreValue;
  double shootInterval;
  double shootCooldown = 0;
  bool hasPassedScreen = false;
  bool hasShield = false;
  late HealthBarComponent healthBar;
  SpriteAnimationComponent? shieldEffect;
  double _hitFlashTimer = 0;
  static const double flashDuration = 0.1;
  double _shieldPulseTimer = 0;
  final random = Random();
  
  // Add maxHealth property for boss health percentage calculation
  double get maxHealth => health.toDouble();

  Enemy({
    required this.speed,
    required this.health,
    required this.scoreValue,
    required this.shootInterval,
    required Vector2 size,
  }) : super(size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.passive);
    
    // Add health bar to all enemies
    healthBar = HealthBarComponent(
      maxHealth: health,
      currentHealth: health,
      size: Vector2(size.x * 0.8, 3), // Smaller than tank's health bar
    );
    healthBar.position = Vector2(size.x * 0.1, -8);
    add(healthBar);

    // Add shield if enemy has one
    if (hasShield) {
      final shieldAnimation = await gameRef.loadSpriteAnimation(
        'shield_animation.png',
        SpriteAnimationData.sequenced(
          amount: 6,
          stepTime: 0.1,
          textureSize: Vector2.all(32),
          loop: true,
        ),
      );

      shieldEffect = SpriteAnimationComponent(
        animation: shieldAnimation,
        size: Vector2(size.x * 1.2, size.y * 1.2),
      );
      shieldEffect!.anchor = Anchor.center;
      shieldEffect!.position = size / 2;
      shieldEffect!.opacity = 0.3;
      add(shieldEffect!);
    }

    _shieldPulseTimer = random.nextDouble() * 2 * pi;
  }

  void update(double dt) {
    if (gameRef.gameStateManager.state != GameState.playing) return;
    super.update(dt);
    
    // Handle hit flash effect
    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
      opacity = (_hitFlashTimer > flashDuration / 2) ? 0.7 : 1.0;
    }
    
    // Handle shield pulse if enemy has shield
    if (hasShield && shieldEffect != null) {
      _shieldPulseTimer += dt * 2;
      shieldEffect!.opacity = 0.2 + (sin(_shieldPulseTimer) + 1) * 0.1;
    }
    
    position.y += speed * dt;
    if (position.y > gameRef.size.y && !hasPassedScreen) {
      hasPassedScreen = true;
      if (countsAsPassed) {
        gameState.enemyPassed();
      }
    }
    if (position.y > gameRef.size.y + size.y) {
      removeFromParent();
    }
    shootCooldown -= dt;
    if (shootCooldown <= 0) {
      shoot();
      shootCooldown = shootInterval;
    }
  }

  void shoot() {
    gameRef.add(EnemyBullet(position: position.clone() + Vector2(0, height / 2)));
    try {
      audio.playSfx('enemy_laser.mp3');
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void takeDamage(int damage) {
    // Visual hit effect
    _hitFlashTimer = flashDuration;
    
    // Scale effect
    scale = Vector2.all(1.1); // Smaller scale effect for regular enemies
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.2),
      ),
    );

    if (hasShield && shieldEffect != null) {
      shieldEffect!.opacity = 0.5; // Bright flash
      _shieldPulseTimer = 0;
    }
    
    // Add hit particles
    gameRef.add(
      ParticleExplosion(
        position: position,
        size: size,
        color: hasShield ? Colors.blue.withOpacity(0.5) : Colors.yellow.withOpacity(0.5),
      )
    );

    // Actual damage
    health -= damage;
    healthBar.updateHealth(health);
    
    if (health <= 0) {
      // Add explosion effect
      gameRef.add(
        ParticleExplosion(
          position: position,
          size: size,
          color: Colors.orange,
        )
      );
      
      // Add score
      gameState.increaseScore(scoreValue);
      
      // Drop scrap currency
      _dropScrap();
      
      // Play sound
      audio.playSfx('explosion.mp3');
      
      // Remove from game
      removeFromParent();
    }
  }
  
  // Drop scrap currency when enemy is destroyed
  void _dropScrap() {
    try {
      final random = Random();
      
      // Base amount of scrap to drop
      int baseScrap = max(1, (scoreValue / 10).ceil());
      
      // Add some randomness (±20%)
      int randomVariation = baseScrap > 1 ? random.nextInt(max(1, baseScrap ~/ 2)) : 0;
      int scrapAmount = baseScrap + randomVariation - (baseScrap ~/ 4);
      scrapAmount = max(1, scrapAmount.clamp(1, 10)); // Ensure at least 1 scrap, max 10
      
      // Determine if we drop multiple pieces or one larger piece
      bool dropMultiple = random.nextBool() && scrapAmount > 1;
      
      if (dropMultiple) {
        // Drop 2-3 pieces of scrap
        int pieces = min(3, scrapAmount);
        int valuePerPiece = max(1, (scrapAmount / pieces).ceil());
        
        for (int i = 0; i < pieces; i++) {
          // Scatter the scrap around the enemy position
          Vector2 offset = Vector2(
            (random.nextDouble() - 0.5) * size.x * 1.2,
            (random.nextDouble() - 0.5) * size.y * 1.2,
          );
          
          gameRef.add(ScrapComponent(
            position: position + offset,
            value: valuePerPiece,
          ));
        }
      } else {
        // Drop a single piece of scrap
        gameRef.add(ScrapComponent(
          position: position.clone(),
          value: scrapAmount,
        ));
      }
    } catch (e) {
      print('Error in _dropScrap: $e');
      // Fallback: drop a single piece of scrap with value 1
      try {
        gameRef.add(ScrapComponent(
          position: position.clone(),
          value: 1,
        ));
      } catch (e) {
        print('Failed to drop fallback scrap: $e');
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Bullet) {
      takeDamage(1);
      other.removeFromParent();
    } else if (other is Player) {
      if (!(this is TankEnemy)) {
        removeFromParent();
      }
    }
  }
}

class BasicEnemy extends Enemy {
  BasicEnemy({bool withShield = false, int healthPoints = 1})
      : super(
            speed: 100,
            health: healthPoints,
            scoreValue: 10 + (healthPoints - 1) * 5 + (withShield ? 10 : 0),
            shootInterval: 3.0,
            size: Vector2(50, 50)) {
    hasShield = withShield;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      print('BasicEnemy: Loading sprite...');
      
      // First try to load directly as a Sprite
      try {
        final sprite = await Sprite.load('basic_enemy.png');
        animation = SpriteAnimation.spriteList(
          [sprite],
          stepTime: 1,
        );
        print('BasicEnemy: Successfully loaded sprite directly');
      } catch (spriteError) {
        print('BasicEnemy: Direct sprite loading failed: $spriteError');
        
        // Fallback to animation loading
        try {
          animation = SpriteAnimation.fromFrameData(
            await gameRef.images.load('basic_enemy.png'),
            SpriteAnimationData.sequenced(
              amount: 1,
              stepTime: 1,
              textureSize: Vector2.all(64),
            ),
          );
          print('BasicEnemy: Successfully loaded via animation');
        } catch (animError) {
          print('BasicEnemy: Animation loading also failed: $animError');
          throw animError; // Re-throw to be caught by outer try-catch
        }
      }
      
      // Set anchor to center for better positioning
      anchor = Anchor.center;
      print('BasicEnemy: Sprite loaded successfully');
    } catch (e) {
      print('Error loading basic enemy sprite: $e');
      // Create a fallback colored rectangle
      final paint = Paint()..color = Colors.red;
      final renderRect = RectangleComponent(
        size: size,
        paint: paint,
      );
      add(renderRect);
    }
  }
}

class FastEnemy extends Enemy {
  FastEnemy({bool withShield = false, int healthPoints = 1})
      : super(
            speed: 150,
            health: healthPoints,
            scoreValue: 15 + (healthPoints - 1) * 8 + (withShield ? 15 : 0),
            shootInterval: 2.5,
            size: Vector2(40, 40)) {
    hasShield = withShield;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      // Load as a single sprite instead of animation
      animation = SpriteAnimation.fromFrameData(
        await gameRef.images.load('fast_enemy.png'),
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: 1,
          textureSize: Vector2.all(64),
        ),
      );
      
      // Set anchor to center for better positioning
      anchor = Anchor.center;
    } catch (e) {
      print('Error loading fast enemy sprite: $e');
    }
  }
}

class TankEnemy extends Enemy {
  late HealthBarComponent healthBar;
  SpriteAnimationComponent? shieldEffect;
  double _hitFlashTimer = 0;
  static const double flashDuration = 0.1;
  double _shieldPulseTimer = 0;
  final random = Random();

  TankEnemy()
      : super(
            speed: 50,
            health: 3,
            scoreValue: 30,
            shootInterval: 4.0,
            size: Vector2(60, 60)) {
    _shieldPulseTimer = random.nextDouble() * 2 * pi;
    countsAsPassed = true;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    try {
      // Load as a single sprite instead of animation
      animation = SpriteAnimation.fromFrameData(
        await gameRef.images.load('tank_enemy.png'),
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: 1,
          textureSize: Vector2.all(64),
        ),
      );
      
      // Set anchor to center for better positioning
      anchor = Anchor.center;
      
      // Create a simple shield effect
      final shieldAnimation = SpriteAnimation.fromFrameData(
        await gameRef.images.load('shield_animation.png'),
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: 0.1,
          textureSize: Vector2.all(64),
          loop: true,
        ),
      );
      
      shieldEffect = SpriteAnimationComponent(
        animation: shieldAnimation,
        size: Vector2(size.x * 1.2, size.y * 1.2),
      );
      
      shieldEffect?.anchor = Anchor.center;
      shieldEffect?.position = size / 2;
      
      if (shieldEffect != null) {
        add(shieldEffect!);
      }
    } catch (e) {
      print('Error loading tank enemy sprite: $e');
    }

    // Health bar
    healthBar = HealthBarComponent(
      maxHealth: health,
      currentHealth: health,
      size: Vector2(size.x * 0.8, 5),
    );
    healthBar.position = Vector2(size.x * 0.1, -10);
    add(healthBar);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Handle hit flash effect
    if (_hitFlashTimer > 0) {
      _hitFlashTimer -= dt;
      opacity = (_hitFlashTimer > flashDuration / 2) ? 0.7 : 1.0;
    }
    
    // Pulsing shield effect
    _shieldPulseTimer += dt * 2;
    if (shieldEffect != null) {
      shieldEffect!.opacity = 0.2 + (sin(_shieldPulseTimer) + 1) * 0.1;
    }
  }

  @override
  void takeDamage(int damage) {
    // Flash effect
    _hitFlashTimer = flashDuration;
    
    // Shield pulse effect
    shieldEffect!.opacity = 0.6;
    _shieldPulseTimer = 0;
    
    // Slight scale effect
    scale = Vector2.all(1.2);
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.2),
      ),
    );
    
    // Add particle effects for shield hit
    gameRef.add(
      ParticleExplosion(
        position: position,
        size: size,
        color: Colors.blue.withOpacity(0.5),
      )
    );

    // Update health bar and handle actual damage
    super.takeDamage(damage);
    healthBar.updateHealth(health);
  }
}