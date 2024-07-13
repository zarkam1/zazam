import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:zazam/enemies.dart';
import 'game_reference.dart';
import 'space_shooter_game.dart';

class Bullet extends SpriteComponent with HasGameRef<SpaceShooterGame>, CollisionCallbacks,GameRef {
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

class EnemyBullet extends SpriteComponent with HasGameRef<SpaceShooterGame>,GameRef, CollisionCallbacks {
  static const speed = 300.0;

  EnemyBullet({required Vector2 position}) : super(position: position, size: Vector2(10, 20));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await gameRef.loadSprite('enemy_bullet.png');
    anchor = Anchor.center;
    add(RectangleHitbox()..collisionType = CollisionType.active);
    audio.playSfx('enemy_laser.mp3');
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
    if (position.y > gameRef.size.y) {
      removeFromParent();
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    // Removed sound stop code as it's not necessary
  }
}