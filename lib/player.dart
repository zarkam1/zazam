import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'space_shooter_game.dart';
import 'bullets.dart';

class Player extends SpriteAnimationComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks {
  Player() : super(size: Vector2(60, 80));
  double shootCooldown = 0;
  static const shootInterval = 0.5;
  int health = 3;
  static const speed = 300.0;
  double speedMultiplier = 1.0;
  double speedBoostTimeLeft = 0.0;
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
  }

  @override
  void update(double dt) {
    super.update(dt);
    shootCooldown -= dt;
     if (speedBoostTimeLeft > 0) {
      speedBoostTimeLeft -= dt;
      if (speedBoostTimeLeft <= 0) {
        speedMultiplier = 1.0;
      }
    }
  }

  void move(Vector2 movement) {
    position += movement;
    position.clamp(
      Vector2.zero() + size / 2,
      gameRef.size - size / 2,
    );
  }

  void shoot() {
    if (shootCooldown <= 0) {
      gameRef.add(Bullet(position: position.clone() + Vector2(0, -height / 2)));
      gameRef.playSfx('laser.mp3');
      shootCooldown = shootInterval;
    }
  }

  void applySpeedBoost(double duration) {
    speedMultiplier = 2.0;
    speedBoostTimeLeft = duration;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is EnemyBullet) {
      health--;
      other.removeFromParent();
      gameRef.playSfx('player_hit.mp3');
      if (health <= 0) {
        removeFromParent();
        gameRef.gameOver();
      }
    }
  }
}
