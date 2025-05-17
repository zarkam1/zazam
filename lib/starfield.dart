import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum StarShape { circle, square, diamond, star }

class Starfield extends Component {
  final Random _random = Random();
  List<Star> stars = [];
  Vector2 baseVelocity = Vector2(0, 30);
  Vector2 shipVelocity = Vector2.zero();
  final int density;
  final double maxStarSize;
  bool _initialized = false;
  Vector2? _lastKnownGameSize;

  Starfield({this.density = 300, this.maxStarSize = 3.0});

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    _lastKnownGameSize = gameSize;
    if (!_initialized) {
      _initializeStars(gameSize);
      _initialized = true;
    }
  }

  void _initializeStars(Vector2 gameSize) {
    stars = List.generate(density, (_) => _createStar(gameSize));
  }

  Star _createStar(Vector2 gameSize) {
    return Star(
      position: Vector2(_random.nextDouble() * gameSize.x, _random.nextDouble() * gameSize.y),
      size: _random.nextDouble() * maxStarSize + 0.5,
      speed: _random.nextDouble() * 0.5 + 0.1,
      color: _getRandomStarColor(),
      shape: StarShape.values[_random.nextInt(StarShape.values.length)],
    );
  }

  Color _getRandomStarColor() {
    final colors = [
      Colors.white,
      Colors.blue[200]!,
      Colors.yellow[200]!,
      Colors.orange[200]!,
      Colors.red[200]!,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_initialized || _lastKnownGameSize == null) return;

    for (var star in stars) {
      double parallaxFactor = star.size / maxStarSize;
      
      // Amplify horizontal movement
      double xVelocity = -shipVelocity.x * 5 * parallaxFactor;
      double yVelocity = baseVelocity.y - shipVelocity.y * 2 * parallaxFactor;

      star.position.x += xVelocity * star.speed * dt;
      star.position.y += yVelocity * star.speed * dt;
      
      // Wrap stars around the screen
      if (star.position.y > _lastKnownGameSize!.y) {
        star.position.y = 0;
        star.position.x = _random.nextDouble() * _lastKnownGameSize!.x;
      } else if (star.position.y < 0) {
        star.position.y = _lastKnownGameSize!.y;
        star.position.x = _random.nextDouble() * _lastKnownGameSize!.x;
      }
      
      if (star.position.x > _lastKnownGameSize!.x) {
        star.position.x = 0;
      } else if (star.position.x < 0) {
        star.position.x = _lastKnownGameSize!.x;
      }
    }

    // Debug output
   // print('Starfield update: Ship velocity = $shipVelocity');
  }

  @override
  void render(Canvas canvas) {
    if (!_initialized || _lastKnownGameSize == null) return;

    // Draw solid black background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _lastKnownGameSize!.x, _lastKnownGameSize!.y),
      Paint()..color = Colors.black,
    );

    for (var star in stars) {
      final paint = Paint()
        ..color = star.color.withOpacity(star.speed)
        ..style = PaintingStyle.fill;
      
      switch (star.shape) {
        case StarShape.circle:
          canvas.drawCircle(star.position.toOffset(), star.size, paint);
          break;
        case StarShape.square:
          canvas.drawRect(
            Rect.fromCenter(center: star.position.toOffset(), width: star.size * 2, height: star.size * 2),
            paint
          );
          break;
        case StarShape.diamond:
          final path = Path()
            ..moveTo(star.position.x, star.position.y - star.size)
            ..lineTo(star.position.x + star.size, star.position.y)
            ..lineTo(star.position.x, star.position.y + star.size)
            ..lineTo(star.position.x - star.size, star.position.y)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case StarShape.star:
          _drawStar(canvas, star.position.toOffset(), 5, star.size, star.size / 2, paint);
          break;
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, int points, double outerRadius, double innerRadius, Paint paint) {
    final path = Path();
    final angleStep = (2 * pi) / points;
    final halfAngleStep = angleStep / 2;

    path.moveTo(center.dx, center.dy - outerRadius);

    for (int i = 1; i < points * 2; i++) {
      final radius = i.isOdd ? innerRadius : outerRadius;
      final angle = halfAngleStep * i - pi / 2;
      path.lineTo(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  void updateShipMovement(Vector2 velocity) {
    shipVelocity = velocity;
    // Debug output
   // print('Starfield updateShipMovement: New velocity = $velocity');
  }
}

class Star {
  Vector2 position;
  double size;
  double speed;
  Color color;
  StarShape shape;

  Star({
    required this.position,
    required this.size,
    required this.speed,
    required this.color,
    required this.shape,
  });
}