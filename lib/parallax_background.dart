import 'package:flame/components.dart';
import 'package:flame/parallax.dart';

import 'space_shooter_game.dart';

class ParallaxBackground extends ParallaxComponent<SpaceShooterGame> {
  final SpaceShooterGame gameRef;

  ParallaxBackground(this.gameRef);
  @override
  Future<void> onLoad() async {
    parallax = await gameRef.loadParallax(
      [
        ParallaxImageData('background/stars_far.png'),
        ParallaxImageData('background/stars_middle.png'),
        ParallaxImageData('background/stars_close.png'),
       // ParallaxImageData('background/planets.png'),  // New layer
      ],
      baseVelocity: Vector2(0, 20),
      velocityMultiplierDelta: Vector2(0, 1.8),
    );
  }
}