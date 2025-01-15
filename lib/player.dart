import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'dart:math' as math;
import 'enemies.dart';
import 'game_reference.dart';
import 'space_shooter_game.dart';
import 'bullets.dart';

class Player extends SpriteAnimationComponent
    with HasGameRef<SpaceShooterGame>,GameRef, CollisionCallbacks {
  Player() : super(size: Vector2(60, 80));

  bool _isInvulnerable = false;
  double _invulnerabilityTimer = 0;
  static const double invulnerabilityDuration = 1.5; // Seconds of invulnerability after hit

  Vector2 velocity = Vector2.zero();
  Vector2 acceleration = Vector2.zero();
  final double thrust = 00; // Adjust as needed
  bool isShooting = false;
  double shootCooldown = 0;
  static const shootInterval = 0.5;
  int health = 3;
  static const int maxHealth = 5;
  static const speed = 300.0;
  double speedMultiplier = 1.0;
  static const speedBoostDuration = 5.0;
  double speedBoostTimeLeft = 0.0;
  static const rapidFireDuration = 5.0;
  double rapidFireTimeLeft = 0.0;
  static const shieldDuration = 10.0;
  double shieldTimeLeft = 0.0;

  late SpriteAnimationComponent shieldAnimation;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    


  try {
      print('Player: onLoad started');
      await _initializePlayer();
      print('Player: onLoad completed');
    } catch (e, stackTrace) {
      print('Error in Player onLoad: $e');
      print('Stack trace: $stackTrace');
    }


    position = gameRef.size / 2;
    anchor = Anchor.center;
    
    

    position = gameRef.size / 2;
    anchor = Anchor.center;
    add(RectangleHitbox()..collisionType = CollisionType.active);

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
    animation = await gameRef.loadSpriteAnimation(
      'player.png',
      SpriteAnimationData.sequenced(
        amount: 3,
        stepTime: 0.2,
        textureSize: Vector2.all(32),
      ),
    );
    }   

  void resetHealth() {
    health = 3;
  }


void reset() {
  position = gameRef.size / 2;
  health = 3;
  resetPowerups();
  shootCooldown = 0;
  isShooting = false;

  _isInvulnerable = false;
  _invulnerabilityTimer = 0;
  opacity = 1.0;
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
    health = math.min(health + 1, maxHealth);
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
        takeDamage();
        _startInvulnerabilityPeriod();
        audio.playSfx('player_hit.mp3');
      }
    } else if (other is EnemyBullet) {
      if (shieldTimeLeft <= 0) {
        takeDamage();
        other.removeFromParent();
        audio.playSfx('player_hit.mp3');
      } else {
        other.removeFromParent();
        audio.playSfx('shield_hit.mp3');
      }
    }
  }

void _startInvulnerabilityPeriod() {
  _isInvulnerable = true;
  _invulnerabilityTimer = invulnerabilityDuration;
  opacity = 0.5; // Visual indicator that player is invulnerable
}
void takeDamage() {
    health = math.max(0, health - 1);
    gameRef.uiManager.updateHealth(health);
    if (health <= 0) {
      removeFromParent();
      gameState.gameOver();
    }
}
 
  }