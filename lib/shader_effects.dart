import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// A simple shield effect component that renders a glowing shield around a game object
class ShieldEffect extends PositionComponent {
  final Color color;
  final double radius;
  double _time = 0.0;
  double _intensity = 0.5;
  final Paint _paint = Paint();
  
  ShieldEffect({
    required Vector2 position,
    required this.radius,
    this.color = Colors.blue,
    Vector2? size,
  }) : super(
    position: position,
    size: size ?? Vector2.all(radius * 2),
    anchor: Anchor.center,
  ) {
    _paint.color = color.withOpacity(0.3);
    _paint.style = PaintingStyle.stroke;
    _paint.strokeWidth = 2.0;
  }
  
  void hit() {
    _intensity = 1.0;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    
    // Gradually reduce intensity after hit
    if (_intensity > 0.3) {
      _intensity *= 0.95;
      if (_intensity < 0.3) _intensity = 0.3;
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Pulsing effect
    final pulse = 0.7 + math.sin(_time * 3) * 0.3;
    
    // Inner glow
    final innerPaint = Paint()
      ..color = color.withOpacity(0.1 * _intensity * pulse)
      ..style = PaintingStyle.fill;
    
    // Outer ring
    final outerPaint = Paint()
      ..color = color.withOpacity(0.5 * _intensity * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + (_intensity * 2.0);
    
    // Draw inner glow
    canvas.drawCircle(
      Offset.zero,
      radius * 0.95,
      innerPaint,
    );
    
    // Draw outer ring
    canvas.drawCircle(
      Offset.zero,
      radius,
      outerPaint,
    );
    
    // Draw ripple effect when hit
    if (_intensity > 0.4) {
      final rippleRadius = radius * (1 + (_intensity - 0.3) * 0.5);
      final ripplePaint = Paint()
        ..color = color.withOpacity((_intensity - 0.3) * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawCircle(
        Offset.zero,
        rippleRadius,
        ripplePaint,
      );
    }
  }
}

/// A thruster effect that renders behind a ship
class ThrusterEffect extends PositionComponent {
  final Color color;
  double _time = 0.0;
  final Paint _paint = Paint();
  
  ThrusterEffect({
    required Vector2 position,
    required Vector2 size,
    this.color = Colors.blue,
  }) : super(
    position: position,
    size: size,
  ) {
    _paint.color = color;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Flicker effect
    final flicker = 0.7 + math.sin(_time * 10) * 0.3;
    
    // Create a path for the flame shape
    final path = Path();
    path.moveTo(size.x / 2, size.y);
    path.lineTo(0, 0);
    path.lineTo(size.x, 0);
    path.close();
    
    // Create a gradient for the flame
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.0),
        color.withOpacity(0.7 * flicker),
      ],
    );
    
    _paint.shader = gradient.createShader(rect);
    
    // Draw the flame
    canvas.drawPath(path, _paint);
  }
}

/// A laser beam effect
class LaserBeamEffect extends PositionComponent {
  final Color color;
  final Vector2 endPoint;
  double _time = 0.0;
  final Paint _paint = Paint();
  
  LaserBeamEffect({
    required Vector2 position,
    required this.endPoint,
    this.color = Colors.red,
    double width = 3.0,
  }) : super(
    position: position,
  ) {
    _paint.color = color;
    _paint.strokeWidth = width;
    _paint.strokeCap = StrokeCap.round;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Pulsing effect
    final pulse = 0.8 + math.sin(_time * 15) * 0.2;
    
    // Outer glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3 * pulse)
      ..strokeWidth = _paint.strokeWidth * 2.5
      ..strokeCap = StrokeCap.round;
    
    // Core beam
    final corePaint = Paint()
      ..color = color.withOpacity(0.8 * pulse)
      ..strokeWidth = _paint.strokeWidth
      ..strokeCap = StrokeCap.round;
    
    // Draw the beam
    canvas.drawLine(Offset.zero, endPoint.toOffset() - position.toOffset(), glowPaint);
    canvas.drawLine(Offset.zero, endPoint.toOffset() - position.toOffset(), corePaint);
  }
}
