import 'dart:ui';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'space_shooter_game.dart';

/// A component that renders text with a neon glow effect
class NeonText extends PositionComponent with HasGameRef<SpaceShooterGame> {
  final String text;
  final Color color;
  final double fontSize;
  final bool animate;
  final double glowIntensity;
  final double letterSpacing;
  
  // Rendering options
  final bool useSprites;
  
  // Components
  final List<Component> _letterComponents = [];
  SpriteSheet? _fontSheet;
  
  // Animation
  Timer? _pulseTimer;
  double _pulseValue = 0.0;
  final double _pulseSpeed = 2.0;
  
  NeonText({
    required this.text,
    this.color = Colors.purpleAccent,
    this.fontSize = 24,
    this.animate = true,
    this.glowIntensity = 0.8,
    this.letterSpacing = 2.0,
    this.useSprites = false,
    Vector2? position,
    Vector2? size,
    Anchor? anchor,
  }) : super(
    position: position,
    size: size,
    anchor: anchor ?? Anchor.topLeft,
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    if (useSprites) {
      await _loadSpriteFont();
      await _createSpriteText();
    } else {
      await _createShaderText();
    }
    
    if (animate) {
      _pulseTimer = Timer(
        0.016, // ~60fps
        onTick: _updatePulse,
        repeat: true,
      );
      _pulseTimer?.start();
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer?.update(dt);
  }
  
  /// Updates the pulse animation effect
  void _updatePulse() {
    _pulseValue += 0.016 * _pulseSpeed;
    if (_pulseValue > 2 * 3.14159) {
      _pulseValue = 0;
    }
    
    // Calculate the pulse effect (0.7 to 1.0 range)
    final pulse = 0.7 + (0.3 * (0.5 + 0.5 * sin(_pulseValue)));
    
    // Apply to all letter components
    for (final component in _letterComponents) {
      if (component is SpriteComponent) {
        component.opacity = pulse;
      } else if (component is TextComponent) {
        final textPaint = component.textRenderer as TextPaint;
        final currentStyle = textPaint.style;
        component.textRenderer = TextPaint(
          style: currentStyle.copyWith(
            shadows: [
              Shadow(
                color: color.withOpacity(pulse * glowIntensity),
                blurRadius: 8 * pulse,
              ),
              Shadow(
                color: color.withOpacity(pulse * glowIntensity * 0.7),
                blurRadius: 16 * pulse,
              ),
            ],
          ),
        );
      }
    }
  }
  
  /// Loads the sprite font sheet
  Future<void> _loadSpriteFont() async {
    try {
      // Try to load the sprite font sheet
      final image = await gameRef.images.load('fonts/neon_font.png');
      _fontSheet = SpriteSheet(
        image: image,
        srcSize: Vector2(32, 32), // Adjust based on your sprite sheet
      );
    } catch (e) {
      print('NeonText: Error loading sprite font: $e');
      // We'll fall back to shader text if sprite loading fails
    }
  }
  
  /// Creates text using individual letter sprites
  Future<void> _createSpriteText() async {
    if (_fontSheet == null) {
      print('NeonText: Sprite font not loaded, falling back to shader text');
      await _createShaderText();
      return;
    }
    
    // Clear any existing components
    for (final component in _letterComponents) {
      component.removeFromParent();
    }
    _letterComponents.clear();
    
    // Define the mapping from characters to sprite indices
    const charMap = {
      'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4, 'F': 5, 'G': 6, 'H': 7,
      'I': 8, 'J': 9, 'K': 10, 'L': 11, 'M': 12, 'N': 13, 'O': 14, 'P': 15,
      'Q': 16, 'R': 17, 'S': 18, 'T': 19, 'U': 20, 'V': 21, 'W': 22, 'X': 23,
      'Y': 24, 'Z': 25, '0': 26, '1': 27, '2': 28, '3': 29, '4': 30,
      '5': 31, '6': 32, '7': 33, '8': 34, '9': 35, ':': 36, '.': 37, '!': 38,
      '?': 39, '-': 40, '+': 41, '*': 42, '/': 43, '(': 44, ')': 45, ' ': 46,
    };
    
    // Create a sprite component for each character
    double xOffset = 0;
    final upperText = text.toUpperCase(); // Sprite fonts typically only have uppercase
    
    for (int i = 0; i < upperText.length; i++) {
      final char = upperText[i];
      final spriteIndex = charMap[char] ?? 46; // Default to space if character not found
      
      if (spriteIndex == 46) { // Space character
        xOffset += fontSize * 0.5 + letterSpacing;
        continue;
      }
      
      try {
        final sprite = _fontSheet!.getSpriteById(spriteIndex);
        final letterComponent = SpriteComponent(
          sprite: sprite,
          position: Vector2(xOffset, 0),
          size: Vector2(fontSize, fontSize),
          anchor: Anchor.topLeft,
        );
        
        // Apply color tint
        letterComponent.paint.colorFilter = ColorFilter.mode(
          color,
          BlendMode.srcATop,
        );
        
        add(letterComponent);
        _letterComponents.add(letterComponent);
        
        // Add glow effect
        final glowComponent = SpriteComponent(
          sprite: sprite,
          position: Vector2(xOffset, 0),
          size: Vector2(fontSize * 1.1, fontSize * 1.1),
          anchor: Anchor.topLeft,
        );
        
        // Apply glow
        glowComponent.paint.colorFilter = ColorFilter.mode(
          color.withOpacity(0.5),
          BlendMode.srcATop,
        );
        glowComponent.paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 4);
        glowComponent.paint.imageFilter = ImageFilter.blur(sigmaX: 2, sigmaY: 2);
        
        // Add the glow behind the letter
        add(glowComponent);
        _letterComponents.add(glowComponent);
        
        // Move to next letter position
        xOffset += fontSize + letterSpacing;
      } catch (e) {
        print('NeonText: Error creating sprite for character $char: $e');
        xOffset += fontSize * 0.5 + letterSpacing;
      }
    }
    
    // Update component size based on text length
    size = Vector2(xOffset, fontSize);
  }
  
  /// Creates text using TextComponent with glow shader effects
  Future<void> _createShaderText() async {
    // Clear any existing components
    for (final component in _letterComponents) {
      component.removeFromParent();
    }
    _letterComponents.clear();
    
    // Create the text component with glow effect
    final textComponent = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: color.withOpacity(glowIntensity),
              blurRadius: 8,
            ),
            Shadow(
              color: color.withOpacity(glowIntensity * 0.7),
              blurRadius: 16,
            ),
          ],
        ),
      ),
      anchor: Anchor.topLeft,
    );
    
    add(textComponent);
    _letterComponents.add(textComponent);
    
    // Update component size based on text
    size = Vector2(textComponent.width, textComponent.height);
  }
  
  /// Updates the text content
  void setText(String newText) {
    if (text == newText) return;
    
    removeAll(_letterComponents);
    _letterComponents.clear();
    
    if (useSprites && _fontSheet != null) {
      _createSpriteText();
    } else {
      _createShaderText();
    }
  }
}
