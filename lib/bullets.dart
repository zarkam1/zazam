import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
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
  void update(double dt) {
    super.update(dt);
    position.y -= speed * dt;
    if (position.y < 0) {
      removeFromParent();
    }
  }
}

class EnemyBullet extends SpriteComponent with HasGameRef<SpaceShooterGame>, CollisionCallbacks {
  static const speed = 300.0;

  EnemyBullet({required Vector2 position}) : super(position: position, size: Vector2(10, 20));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await gameRef.loadSprite('enemy_bullet.png');
    anchor = Anchor.center;
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    if (position.y > gameRef.size.y) {
      removeFromParent();
    }
  }
}