import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flame/parallax.dart';
import 'space_shooter_game.dart';
import 'level_management.dart';

/// Manages the game's background effects and level-specific backgrounds
class BackgroundManager extends Component with HasGameRef<SpaceShooterGame> {
  // Background layers
  late ParallaxComponent _starfieldBackground;
  SpriteComponent? _levelBackground;
  SpriteComponent? _neonOverlay;
  
  // Glow effect for neon elements
  Timer? _glowPulseTimer;
  final Random _random = Random();
  
  // Current level background
  String _currentBackgroundAsset = '';
  
  BackgroundManager();
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Load the default starfield background
    _starfieldBackground = await ParallaxComponent.load(
      [
        ParallaxImageData('background/stars_small.png'),
        ParallaxImageData('background/stars_medium.png'),
        ParallaxImageData('background/stars_large.png'),
      ],
      baseVelocity: Vector2(0, 20),
      velocityMultiplierDelta: Vector2(0, 1.5),
      repeat: ImageRepeat.repeat,
      fill: LayerFill.width,
    );
    
    add(_starfieldBackground);
    
    // Initialize glow pulse effect timer
    _glowPulseTimer = Timer(
      0.05,
      onTick: _updateGlowEffect,
      repeat: true,
    );
    _glowPulseTimer?.start();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _glowPulseTimer?.update(dt);
  }
  
  /// Updates the background based on the current level
  Future<void> setLevelBackground(LevelDefinition level) async {
    try {
      print('BackgroundManager: Setting background for level ${level.id}');
      
      // Don't reload if it's the same background
      if (_currentBackgroundAsset == level.mapAsset) {
        print('BackgroundManager: Same background, skipping reload');
        return;
      }
      
      _currentBackgroundAsset = level.mapAsset;
      
      // Remove previous level background if it exists
      _levelBackground?.removeFromParent();
      _neonOverlay?.removeFromParent();
      
      // Load the new level background
      try {
        final backgroundSprite = await Sprite.load(level.mapAsset);
        _levelBackground = SpriteComponent(
          sprite: backgroundSprite,
          position: Vector2(gameRef.size.x / 2, gameRef.size.y / 2),
          anchor: Anchor.center,
          size: gameRef.size,
        );
        
        // Add the background behind everything else
        add(_levelBackground!);
        print('BackgroundManager: Level background loaded successfully');
        
        // If this is a neon-style background, add glow effects
        if (level.mapAsset.contains('neon') || level.id == 4) { // Boss level or neon levels
          await _addNeonEffects(level);
        }
      } catch (e) {
        print('BackgroundManager: Error loading level background: $e');
        // Fallback to a color background if image loading fails
        final colorBackground = RectangleComponent(
          size: gameRef.size,
          paint: Paint()..color = Colors.black.withOpacity(0.7),
        );
        add(colorBackground);
      }
    } catch (e) {
      print('BackgroundManager: Error setting level background: $e');
    }
  }
  
  /// Adds neon glow effects to the background
  Future<void> _addNeonEffects(LevelDefinition level) async {
    try {
      // Try to load a neon overlay if it exists
      try {
        final neonOverlaySprite = await Sprite.load('background/neon_overlay.png');
        _neonOverlay = SpriteComponent(
          sprite: neonOverlaySprite,
          position: Vector2(gameRef.size.x / 2, gameRef.size.y / 2),
          anchor: Anchor.center,
          size: gameRef.size,
        );
        
        // Add a pulsing opacity effect
        _neonOverlay!.add(
          OpacityEffect.to(
            0.7,
            EffectController(
              duration: 1.5,
              reverseDuration: 1.5,
              infinite: true,
              curve: Curves.easeInOut,
            ),
          ),
        );
        
        add(_neonOverlay!);
        print('BackgroundManager: Neon overlay added');
      } catch (e) {
        print('BackgroundManager: No neon overlay found: $e');
      }
    } catch (e) {
      print('BackgroundManager: Error adding neon effects: $e');
    }
  }
  
  /// Updates the glow effect for neon elements
  void _updateGlowEffect() {
    if (_neonOverlay != null) {
      // Subtle random variations in opacity to simulate electrical flickering
      if (_random.nextDouble() < 0.1) { // 10% chance of flicker
        final flickerOpacity = 0.7 + (_random.nextDouble() * 0.3);
        _neonOverlay!.opacity = flickerOpacity;
      }
    }
  }
  
  /// Resets the background to default
  void reset() {
    _levelBackground?.removeFromParent();
    _neonOverlay?.removeFromParent();
    _levelBackground = null;
    _neonOverlay = null;
    _currentBackgroundAsset = '';
  }
}
