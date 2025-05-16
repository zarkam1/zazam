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
import 'enemies.dart';
import 'shader_effects.dart';

class BossEnemy extends Enemy {
  // Boss-specific properties
  double _phaseTimer = 0;
  int currentPhase = 0;
  static const int maxPhases = 3;
  bool _isInvulnerable = false;
  double _invulnerabilityTimer = 0;
  static const double invulnerabilityDuration = 1.5;
  
  // Movement pattern variables
  double _movementTimer = 0;
  Vector2 _targetPosition = Vector2.zero();
  bool _isMovingToTarget = false;
  
  // Attack pattern variables
  double _attackCooldown = 0;
  int _attackPattern = 0;
  
  BossEnemy()
      : super(
          speed: 80,
          health: 30,
          scoreValue: 500,
          shootInterval: 2.0,
          size: Vector2(120, 120),
        ) {
    countsAsPassed = false;
  }

  // Add maxHealth property
  double get maxHealth => health.toDouble();
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    try {
      // Load boss sprite (single image)
      animation = SpriteAnimation.fromFrameData(
        await gameRef.images.load('boss_enemy.png'),
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: 1,
          textureSize: Vector2.all(128),
        ),
      );
      
      // Set anchor to center for better positioning
      anchor = Anchor.center;
      
      // Adjust size for the larger boss sprite
      // You may need to adjust these values based on your actual image size
      size = Vector2(150, 150); 
      
      // Set initial position at the top center of the screen
      position = Vector2(
        gameRef.size.x / 2,
        -size.y / 2,
      );
      
      // Add dramatic entrance effect
      add(
        MoveEffect.to(
          Vector2(gameRef.size.x / 2, size.y),
          EffectController(duration: 2.0, curve: Curves.easeInOut),
        ),
      );
      
      // Create a health bar that matches the boss size
      healthBar = HealthBarComponent(
        maxHealth: health,
        currentHealth: health,
        size: Vector2(size.x * 0.8, 10),
      );
      healthBar.position = Vector2(-size.x * 0.4, -size.y / 2 - 20);
      add(healthBar);
      
      // Add shader-based shield effect
      final shieldEffect = ShieldEffect(
        position: Vector2(0, 0), // Center of the boss
        radius: size.length / 2 * 1.2,
        color: Colors.blue,
      );
      add(shieldEffect);
      
      // Add hitbox for collisions
      add(
        CircleHitbox(
          radius: size.x / 2,
          anchor: Anchor.center,
          position: Vector2(size.x / 2, size.y / 2),
        )
      );
      
      hasShield = true;
      
      // Play boss entrance sound
      try {
        audio.playSfx('explosion.mp3'); // Use existing sound as fallback
      } catch (e) {
        print('Error playing boss entrance sound: $e');
      }
    } catch (e) {
      print('Error loading boss: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (gameRef.gameStateManager.state != GameState.playing) return;
    
    // Handle invulnerability
    if (_isInvulnerable) {
      _invulnerabilityTimer -= dt;
      if (_invulnerabilityTimer <= 0) {
        _isInvulnerable = false;
        opacity = 1.0;
      } else {
        // Flash effect during invulnerability
        opacity = sin(_invulnerabilityTimer * 10) > 0 ? 0.7 : 1.0;
      }
    }
    
    // Update phase timer
    _phaseTimer += dt;
    
    // Phase transition logic
    if (_phaseTimer > 15.0) { // Change phase every 15 seconds
      _phaseTimer = 0;
      currentPhase = (currentPhase + 1) % maxPhases;
      _startInvulnerabilityPeriod();
      
      // Visual effect for phase change
      add(
        ScaleEffect.by(
          Vector2.all(1.3),
          EffectController(duration: 0.3, reverseDuration: 0.3),
        ),
      );
      
      // Play phase change sound
      try {
        audio.playSfx('explosion.mp3');
      } catch (e) {
        print('Error playing phase change sound: $e');
      }
    }
    
    // Boss movement based on current phase
    _handleMovement(dt);
    
    // Boss attack patterns based on current phase
    _handleAttacks(dt);
  }

  void _handleMovement(double dt) {
    _movementTimer += dt;
    
    // Change movement pattern based on phase
    switch (currentPhase) {
      case 0: // Phase 1: Simple left-right movement
        position.x = gameRef.size.x / 2 - size.x / 2 + sin(_movementTimer) * (gameRef.size.x / 3);
        break;
        
      case 1: // Phase 2: Figure-8 pattern
        position.x = gameRef.size.x / 2 - size.x / 2 + sin(_movementTimer) * (gameRef.size.x / 3);
        position.y = size.y + sin(_movementTimer * 2) * (gameRef.size.y / 6);
        break;
        
      case 2: // Phase 3: Random target positions
        if (!_isMovingToTarget || _movementTimer > 3.0) {
          _movementTimer = 0;
          _targetPosition = Vector2(
            random.nextDouble() * (gameRef.size.x - size.x),
            random.nextDouble() * (gameRef.size.y / 2 - size.y) + size.y,
          );
          _isMovingToTarget = true;
        }
        
        if (_isMovingToTarget) {
          final direction = (_targetPosition - position).normalized();
          position += direction * speed * dt;
          
          // Check if we've reached the target
          if (position.distanceTo(_targetPosition) < 10) {
            _isMovingToTarget = false;
          }
        }
        break;
    }
  }

  void _handleAttacks(double dt) {
    _attackCooldown -= dt;
    
    if (_attackCooldown <= 0) {
      // Different attack patterns based on phase
      switch (currentPhase) {
        case 0: // Phase 1: Simple spread shot
          _fireSpreadShot(3);
          _attackCooldown = 2.0;
          break;
          
        case 1: // Phase 2: Alternating patterns
          _attackPattern = (_attackPattern + 1) % 2;
          if (_attackPattern == 0) {
            _fireSpreadShot(5);
          } else {
            _fireCircleShot(8);
          }
          _attackCooldown = 1.5;
          break;
          
        case 2: // Phase 3: Intense attacks
          _fireSpreadShot(7);
          _attackCooldown = 0.5;
          
          // Every third attack, also fire a circle
          if (random.nextInt(3) == 0) {
            _fireCircleShot(12);
          }
          break;
      }
    }
  }

  void _fireSpreadShot(int bulletCount) {
    final angleStep = pi / (bulletCount - 1);
    final startAngle = -pi / 2 - (pi / 2) * 0.5;
    
    for (int i = 0; i < bulletCount; i++) {
      final angle = startAngle + angleStep * i;
      final direction = Vector2(sin(angle), cos(angle));
      
      final bullet = EnemyBullet(
        position: position.clone() + Vector2(size.x / 2, size.y / 2),
        direction: direction,
      );
      gameRef.add(bullet);
    }
    
    try {
      audio.playSfx('enemy_laser.mp3');
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void _fireCircleShot(int bulletCount) {
    final angleStep = 2 * pi / bulletCount;
    
    for (int i = 0; i < bulletCount; i++) {
      final angle = angleStep * i;
      final direction = Vector2(sin(angle), cos(angle));
      
      final bullet = EnemyBullet(
        position: position.clone() + Vector2(size.x / 2, size.y / 2),
        direction: direction,
      );
      gameRef.add(bullet);
    }
    
    try {
      audio.playSfx('enemy_laser.mp3');
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void _startInvulnerabilityPeriod() {
    _isInvulnerable = true;
    _invulnerabilityTimer = invulnerabilityDuration;
  }

  @override
  void takeDamage(int damage) {
    if (_isInvulnerable) return;
    
    // Visual effects
    add(
      ScaleEffect.by(
        Vector2.all(1.2),
        EffectController(duration: 0.1, reverseDuration: 0.1),
      ),
    );
    
    // Add particle effects
    gameRef.add(
      ParticleExplosion(
        position: position + Vector2(size.x / 2, size.y / 2),
        size: Vector2.all(30),
        color: Colors.red.withOpacity(0.7),
      )
    );
    
    // Apply damage
    super.takeDamage(damage);
    
    // Check if phase should change based on health percentage
    final healthPercentage = health / maxHealth;
    if (healthPercentage < 0.7 && currentPhase == 0) {
      currentPhase = 1;
      _phaseTimer = 0;
      _startInvulnerabilityPeriod();
    } else if (healthPercentage < 0.3 && currentPhase == 1) {
      currentPhase = 2;
      _phaseTimer = 0;
      _startInvulnerabilityPeriod();
    }
  }

  @override
  void _dropScrap() {
    try {
      // Drop more scrap than regular enemies
      for (int i = 0; i < 10; i++) {
        final offset = Vector2(
          (random.nextDouble() - 0.5) * size.x * 1.5,
          (random.nextDouble() - 0.5) * size.y * 1.5,
        );
        
        gameRef.add(ScrapComponent(
          position: position + offset,
          value: random.nextInt(5) + 1,
        ));
      }
      
      // Add a big explosion effect
      gameRef.add(
        ParticleExplosion(
          position: position + Vector2(size.x / 2, size.y / 2),
          size: size,
          color: Colors.orange,
          // Use the count parameter instead of particleCount
          // as defined in the ParticleExplosion class
        )
      );
    } catch (e) {
      print('Error dropping boss scrap: $e');
    }
  }
}
