import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

class ParallaxBackground extends ParallaxComponent {
  @override
  Future<void> onLoad() async {
    try {
      parallax = await Parallax.load(
        [
          ParallaxImageData('background/space_background.png'),
          ParallaxImageData('background/stars_small.png'),
          ParallaxImageData('background/stars_medium.png'),
          ParallaxImageData('background/stars_large.png'),
        ],
        baseVelocity: Vector2(0, 20),
        velocityMultiplierDelta: Vector2(0, 0.5),
        filterQuality: FilterQuality.medium,
        repeat: ImageRepeat.repeatY,
        alignment: Alignment.bottomLeft,
        fill: LayerFill.width,
      );

      if (parallax != null) {
        parallax!.layers[0].velocityMultiplier = Vector2(0, 0.1);  // Background (slowest)
        parallax!.layers[1].velocityMultiplier = Vector2(0, 0.3);  // Small stars
        parallax!.layers[2].velocityMultiplier = Vector2(0, 0.5);  // Medium stars
        parallax!.layers[3].velocityMultiplier = Vector2(0, 0.7);  // Large stars (fastest)
      }

      print('Parallax loaded successfully with ${parallax?.layers.length} layers');
    } catch (e) {
      print('Error loading parallax: $e');
    }
  }
}