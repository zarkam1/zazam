import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:zazam/enemies.dart';
import 'space_shooter_game.dart';

class Bullet extends SpriteComponent with HasGameRef<SpaceShooterGame>, CollisionCallbacks {
  static const speed = 500.0;

  Bullet({required Vector2 position}) : super(position: position, size: Vector2(10, 20));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await gameRef.loadSprite('bullet.png');
    anchor = Anchor.center;
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }
 @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy) {
      removeFromParent();
      print('Bullet removed (hit enemy)');
    }
  }
  @override
  void update(double dt) {
    super.update(dt);
    position.y -= speed * dt;
    if (position.y < 0) {
      removeFromParent();
          print('Bullet removed (off-screen)');
    }
  }
}

class EnemyBullet extends SpriteComponent with HasGameRef<SpaceShooterGame>, CollisionCallbacks {
  static const speed = 300.0;

  EnemyBullet({required Vector2 position}) : super(position: position, size: Vector2(10, 20)){
     print('EnemyBullet created at $position');  
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await gameRef.loadSprite('enemy_bullet.png');
    anchor = Anchor.center;
    add(RectangleHitbox()..collisionType = CollisionType.active);
    gameRef.playSfx('enemy_laser.mp3');  // Play sound when bullet is created
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    if (position.y > gameRef.size.y) {
      removeFromParent();
      print('EnemyBullet removed at ${position.y}');
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    // If there's a way to stop the specific sound for this bullet, do it here
    // For now, we'll rely on the sound finishing naturally
    print('EnemyBullet removed and sound should stop');
  }
}