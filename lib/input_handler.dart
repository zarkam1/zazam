import 'package:flame/components.dart';

import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:zazam/space_shooter_game.dart';

class InputHandler extends Component with KeyboardHandler, HasGameRef<SpaceShooterGame> {
  final Vector2 movement = Vector2.zero();
  bool isShooting = false;

  
   @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    movement.setZero();

    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) movement.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) movement.x += 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) movement.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) movement.y += 1;
    
    // Set isShooting to true only on KeyDownEvent for space key
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      isShooting = true;
    } else if (event is KeyUpEvent && event.logicalKey == LogicalKeyboardKey.space) {
      isShooting = false;
    }
  // X key for shield toggle
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyX) {
      gameRef.player.toggleShield();
    }

    return true;
  }
  void handleJoystickInput(JoystickDirection direction) {
    movement.setZero();

    if (direction == JoystickDirection.left || direction == JoystickDirection.upLeft || direction == JoystickDirection.downLeft) {
      movement.x -= 1;
    }
    if (direction == JoystickDirection.right || direction == JoystickDirection.upRight || direction == JoystickDirection.downRight) {
      movement.x += 1;
    }
    if (direction == JoystickDirection.up || direction == JoystickDirection.upLeft || direction == JoystickDirection.upRight) {
      movement.y -= 1;
    }
    if (direction == JoystickDirection.down || direction == JoystickDirection.downLeft || direction == JoystickDirection.downRight) {
      movement.y += 1;
    }
  }
}