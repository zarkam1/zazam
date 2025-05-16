import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:zazam/enemies.dart';
import 'game_reference.dart';
import 'space_shooter_game.dart';

class Bullet extends SpriteComponent with HasGameRef<SpaceShooterGame>, CollisionCallbacks, GameRef {
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
    if (gameRef.gameStateManager.state != GameState.playing) {
      opacity = 0;
      return;
    }
    opacity = 1;
    super.update(dt);
    position.y -= speed * dt;
    if (position.y < 0) {
      removeFromParent();
      print('Bullet removed (off-screen)');
    }
  }
}

class EnemyBullet extends SpriteComponent with HasGameRef<SpaceShooterGame>, GameRef, CollisionCallbacks {
  static const double defaultSpeed = 300.0;
  final double speed;
  final Vector2 direction;

  EnemyBullet({
    required Vector2 position,
    Vector2? direction,
    double? speed,
  }) : direction = direction?.normalized() ?? Vector2(0, 1),
       speed = speed ?? defaultSpeed,
       super(position: position, size: Vector2(10, 20));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      sprite = await gameRef.loadSprite('enemy_bullet.png');
      anchor = Anchor.center;
      
      // Rotate the bullet to match its direction
      if (direction.y != 1 || direction.x != 0) {
        angle = direction.screenAngle();
      }
      
      add(RectangleHitbox()..collisionType = CollisionType.active);
      
      try {
        audio.playSfx('enemy_laser.mp3');
      } catch (e) {
        print('Error playing sound: $e');
      }
    } catch (e) {
      print('Error loading bullet: $e');
    }
  }

  @override
  void update(double dt) {
    if (gameRef.gameStateManager.state != GameState.playing) {
      opacity = 0;
      return;
    }
    opacity = 1;
    super.update(dt);
    
    // Move in the specified direction
    position += direction * speed * dt;
    
    // Remove if out of bounds
    if (position.y > gameRef.size.y || 
        position.y < -50 || 
        position.x < -50 || 
        position.x > gameRef.size.x + 50) {
      removeFromParent();
    }
  }
}