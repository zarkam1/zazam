import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class ParticleExplosion extends ParticleSystemComponent {
  ParticleExplosion({required Vector2 position, required Vector2 size, required Color color}) : super(
    position: position + size / 2, // Center the explosion on the enemy
    particle: Particle.generate(
      count: 20,
      lifespan: 1,
      generator: (i) {
        final Random random = Random();
        final speed = Vector2(random.nextDouble() * 100 - 50, random.nextDouble() * 100 - 50);
        return AcceleratedParticle(
          acceleration: Vector2(0, 30),
          speed: speed,
          child: CircleParticle(
            paint: Paint()..color = color,
            radius: 2,
          ),
        );
      },
    ),
  );
}