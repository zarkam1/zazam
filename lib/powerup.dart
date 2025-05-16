import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'game_reference.dart';
import 'player.dart';
import 'space_shooter_game.dart';

abstract class PowerUp extends SpriteAnimationComponent with HasGameRef<SpaceShooterGame>,GameRef, CollisionCallbacks {
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
      audio.playSfx('powerup.mp3');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += 50 * dt;  // Move downwards
    if (position.y > gameRef.size.y) {
     game.removeFromParent();
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
    animation = await gameRef.loadSpriteAnimation(
      'powerup_speedBoost.png',
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

class ExtraLife extends PowerUp {
  ExtraLife({required Vector2 position})
      : super(position: position, size: Vector2(30, 30));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = await gameRef.loadSpriteAnimation(
      'powerup_extraLife.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: 0.2,
        textureSize: Vector2.all(32),
      ),
    );
  }

  @override
  void applyEffect(Player player) {
    player.addLife();
  }
}

class RapidFire extends PowerUp {
  static const duration = 5.0; // Duration in seconds

  RapidFire({required Vector2 position})
      : super(position: position, size: Vector2(30, 30));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = await gameRef.loadSpriteAnimation(
      'powerup_rapidFire.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: 0.2,
        textureSize: Vector2.all(32),
      ),
    );
  }

  @override
  void applyEffect(Player player) {
    player.applyRapidFire(duration);
  }
}

class Shield extends PowerUp {
  static const duration = 10.0; // Duration in seconds
  static const double energyAmount = 50.0; // Gives 50% of max shield energy

  Shield({required Vector2 position})
      : super(position: position, size: Vector2(30, 30));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animation = await gameRef.loadSpriteAnimation(
      'powerup_shield.png',
      SpriteAnimationData.sequenced(
        amount: 2,
        stepTime: 0.2,
        textureSize: Vector2.all(32),
      ),
    );
  }

  @override
   void applyEffect(Player player) {
    player.addShieldEnergy(energyAmount);
  }
}