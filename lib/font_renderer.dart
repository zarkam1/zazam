import 'dart:ui';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'space_shooter_game.dart';

/// A component that renders stylized text for the game
class StylizedTextRenderer extends Component with HasGameRef<SpaceShooterGame> {
  // Text styles for different game elements
  static const TextStyle titleStyle = TextStyle(
    fontFamily: 'SpaceFont',
    fontSize: 32,
    color: Colors.purpleAccent,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        color: Colors.purpleAccent,
        blurRadius: 15,
        offset: Offset(0, 0),
      ),
      Shadow(
        color: Colors.purple,
        blurRadius: 8,
        offset: Offset(0, 0),
      ),
    ],
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontFamily: 'SpaceFont',
    fontSize: 24,
    color: Colors.cyanAccent,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        color: Colors.cyanAccent,
        blurRadius: 12,
        offset: Offset(0, 0),
      ),
    ],
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontFamily: 'SpaceFont',
    fontSize: 18,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Colors.purpleAccent,
        blurRadius: 4,
        offset: Offset(0, 0),
      ),
    ],
  );
  
  static const TextStyle hudStyle = TextStyle(
    fontFamily: 'SpaceFont',
    fontSize: 16,
    color: Colors.greenAccent,
    shadows: [
      Shadow(
        color: Colors.greenAccent,
        blurRadius: 4,
        offset: Offset(0, 0),
      ),
    ],
  );
  
  static const TextStyle warningStyle = TextStyle(
    fontFamily: 'SpaceFont',
    fontSize: 20,
    color: Colors.redAccent,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        color: Colors.redAccent,
        blurRadius: 10,
        offset: Offset(0, 0),
      ),
    ],
  );
  
  /// Creates a text component with a pulsing neon effect
  static Component createPulsingText({
    required String text,
    required TextStyle style,
    required Vector2 position,
    Anchor anchor = Anchor.topLeft,
    double pulseMin = 0.7,
    double pulseMax = 1.0,
    double pulseDuration = 1.5,
  }) {
    final textComponent = TextComponent(
      text: text,
      textRenderer: TextPaint(style: style),
      anchor: anchor,
    );

    // Fallback for missing OpacityComponent: use PositionComponent and animate opacity manually
    final pulsingWrapper = _PulsingOpacityWrapper(
      child: textComponent,
      position: position,
      anchor: anchor,
      pulseMin: pulseMin,
      pulseMax: pulseMax,
      pulseDuration: pulseDuration,
      textStyle: style, // Pass the original style
    );
    return pulsingWrapper;
  }
  
  /// Creates a text component with a typing animation effect
  static TextComponent createTypingText({
    required String text,
    required TextStyle style,
    required Vector2 position,
    Anchor anchor = Anchor.topLeft,
    double charDelay = 0.05,
  }) {
    final textComponent = TextComponent(
      text: '',
      textRenderer: TextPaint(style: style),
      position: position,
      anchor: anchor,
    );
    
    // Add a custom effect for typing animation
    final typingEffect = _TypingEffect(
      text: text,
      charDelay: charDelay,
    );
    typingEffect.target = textComponent;
    textComponent.add(typingEffect);
    
    return textComponent;
  }
}

/// A wrapper component that pulses its child's opacity between two values
class _PulsingOpacityWrapper extends PositionComponent {
  final Component child;
  final double pulseMin;
  final double pulseMax;
  final double pulseDuration;
  final TextStyle textStyle; // Store the original text style
  double _elapsed = 0;

  _PulsingOpacityWrapper({
    required this.child,
    required Vector2 position,
    required this.textStyle, // Add this parameter
    Anchor anchor = Anchor.topLeft,
    this.pulseMin = 0.7,
    this.pulseMax = 1.0,
    this.pulseDuration = 1.5,
  }) : super(position: position, anchor: anchor) {
    add(child);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final t = (_elapsed % pulseDuration) / pulseDuration;
    // Pulsate between min and max using a sine wave
    final pulse = pulseMin + (pulseMax - pulseMin) * (0.5 + 0.5 * sin(2 * pi * t));
    
    if (child is TextComponent) {
      final textComp = child as TextComponent;
      // Get the color from our stored textStyle instead of from textRenderer.style
      final origColor = textStyle.color ?? const Color(0xFFFFFFFF);
      
      // Clamp pulse to [0,1]
      final clamped = pulse.clamp(0.0, 1.0);
      
      // Create a new TextPaint with the updated style
      textComp.textRenderer = TextPaint(
        style: textStyle.copyWith(
          color: origColor.withOpacity(clamped),
        ),
      );
    }
    // For other component types, add support as needed.
  }
}

/// Custom effect for typing animation
class _TypingEffect extends Effect {
  late Component target;
  final String text;
  final double charDelay;
  int _currentChar = 0;
  double _timeSinceLastChar = 0;
  
  _TypingEffect({
    required this.text,
    this.charDelay = 0.05,
  }) : super(EffectController(duration: text.length * charDelay));
  
  @override
  void onMount() {
    super.onMount();
    // Make sure the target is a TextComponent
    assert(target is TextComponent, 'TypingEffect can only be applied to TextComponent');
  }
  
  @override
  void apply(double progress) {
    final textComponent = target as TextComponent;
    final targetCharCount = (text.length * progress).floor();
    
    if (targetCharCount > _currentChar) {
      _currentChar = targetCharCount;
      textComponent.text = text.substring(0, _currentChar);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // For manual timing control if needed
    _timeSinceLastChar += dt;
    if (_timeSinceLastChar >= charDelay && _currentChar < text.length) {
      _timeSinceLastChar = 0;
      _currentChar++;
      (target as TextComponent).text = text.substring(0, _currentChar);
    }
  }
}