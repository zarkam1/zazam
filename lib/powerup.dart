import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'player.dart';
import 'space_shooter_game.dart';

abstract class PowerUp extends SpriteAnimationComponent with HasGameRef<SpaceShooterGame>,CollisionCallbacks {
  PowerUp({required Vector2 position, required Vector2 size})
      : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  void applyEffect(Player player);

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player) {
      applyEffect(other);
      removeFromParent();
    }
  }
}


class SpeedBoost extends PowerUp {
  static const duration = 5.0; // Duration in seconds

  SpeedBoost({required Vector2 position})
      : super(position: position, size: Vector2(30, 30));

  @override
  Future<void> onLoad() async {
    await super.onLoad();


     await super.onLoad();
    animation = await this.gameRef.loadSpriteAnimation(
      'powerup_SpeedBoost.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: 0.2,
        textureSize: Vector2.all(32),
      ),
    );
   
  }

  @override
  void applyEffect(Player player) {
    player.applySpeedBoost(duration);
  }
}