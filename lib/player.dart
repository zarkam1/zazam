import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'dart:math' as math;
import 'space_shooter_game.dart';
import 'bullets.dart';

class Player extends SpriteAnimationComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks {
  Player() : super(size: Vector2(60, 80));

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
    
    animation = await gameRef.loadSpriteAnimation(
      'player.png',
      SpriteAnimationData.sequenced(
        amount: 3,
        stepTime: 0.2,
        textureSize: Vector2.all(32),
      ),
    );
    
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

  void takeDamage() {
    health = math.max(0, health - 1);
    if (health <= 0) {
      gameRef.gameOver();
    }
  }

  void resetHealth() {
    health = 3;
  }

  void resetPowerups() {
    speedMultiplier = 1.0;
    speedBoostTimeLeft = 0.0;
    rapidFireTimeLeft = 0.0;
    shieldTimeLeft = 0.0;
    shieldAnimation.opacity = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    shootCooldown -= dt;
    if (shootCooldown <= 0) {
      isShooting = false;
    }
    updatePowerUps(dt);
    shieldAnimation.opacity = shieldTimeLeft > 0 ? 1 : 0;
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

  void move(Vector2 movement) {
    position += movement * speedMultiplier;
    position.clamp(
      Vector2.zero() + size / 2,
      gameRef.size - size / 2,
    );
  }

  void shoot() {
    if (shootCooldown <= 0) {
      isShooting = true;
      gameRef.add(Bullet(position: position.clone() + Vector2(0, -height / 2)));
      gameRef.playSfx('laser.mp3');
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
    if (other is EnemyBullet) {
      if (shieldTimeLeft <= 0) {
        takeDamage();
        other.removeFromParent();
        gameRef.playSfx('player_hit.mp3');
        if (health <= 0) {
          removeFromParent();
          gameRef.gameOver();
        }
      } else {
        other.removeFromParent();
        gameRef.playSfx('shield_hit.mp3');
      }
    }
  }
}