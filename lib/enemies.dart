import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'game_reference.dart';
import 'space_shooter_game.dart';
import 'bullets.dart';

abstract class Enemy extends SpriteAnimationComponent with HasGameRef<SpaceShooterGame>, 
CollisionCallbacks, GameRef {  double speed;
  int health;
  int scoreValue;
  double shootInterval;
  double shootCooldown = 0;
  bool hasPassedScreen = false;
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
  }

 @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    if (position.y > gameRef.size.y && !hasPassedScreen) {
      hasPassedScreen = true;
      gameState.enemyPassed();
      print('Enemy passed at ${position.y}');
    }
    if (position.y > gameRef.size.y + size.y) {
      removeFromParent();
      print('Enemy removed at ${position.y}');
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

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Bullet) {
      health--;
      other.removeFromParent();
      if (health <= 0) {
        removeFromParent();
        gameState.increaseScore(scoreValue);
        audio.playSfx('explosion.mp3');
      }
    }
  }
 
}

class BasicEnemy extends Enemy {
  BasicEnemy() : super(speed: 100, health: 1, scoreValue: 10, shootInterval: 3.0, size: Vector2(50, 50));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = await gameRef.loadSpriteAnimation(
      'basic_enemy.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.2,
        textureSize: Vector2.all(32),
      ),
    );
  }
}

// In enemies.dart

class FastEnemy extends Enemy {
  FastEnemy() : super(speed: 150, health: 1, scoreValue: 15, shootInterval: 2.5, size: Vector2(40, 40));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = await gameRef.loadSpriteAnimation(
      'fast_enemy.png',
      SpriteAnimationData.sequenced(
        amount: 5,
        stepTime: 0.15,
        textureSize: Vector2.all(32),
      ),
    );
  }
}

class TankEnemy extends Enemy {
  TankEnemy() : super(speed: 50, health: 3, scoreValue: 30, shootInterval: 4.0, size: Vector2(60, 60));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = await gameRef.loadSpriteAnimation(
      'tank_enemy.png',
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.3,
        textureSize: Vector2.all(32),
      ),
    );
  }
}

// In space_shooter_game.dart, update the _spawnEnemies method:

