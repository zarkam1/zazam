import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class StyledButton extends PositionComponent with TapCallbacks {
  final String text;
  final VoidCallback onPressed;
  late TextComponent textComponent;
  late RectangleComponent background;

  StyledButton({
    required this.text,
    required this.onPressed,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    background = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Color.fromARGB(255, 18, 18, 19)
        ..style = PaintingStyle.fill,
    );
    add(background);

    textComponent = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontFamily: 'SpaceFont',
        ),
      ),
    );
    textComponent.anchor = Anchor.center;
    textComponent.position = size / 2;
    add(textComponent);
  }

  @override
  void onTapDown(TapDownEvent event) {
    background.paint.color = Colors.blueAccent;
    onPressed();
  }

  @override
  void onTapUp(TapUpEvent event) {
    background.paint.color = Color.fromARGB(255, 18, 18, 19);
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    background.paint.color = Color.fromARGB(255, 18, 18, 19);
  }
}