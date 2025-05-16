import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'space_shooter_game.dart';

/// A component that displays performance metrics like FPS and memory usage
class GamePerformanceOverlay extends PositionComponent with HasGameRef<SpaceShooterGame> {
  // Performance tracking
  final List<double> _fpsValues = [];
  double _averageFps = 0;
  int _frameCount = 0;
  double _memoryUsage = 0;
  late TextComponent _statsText;
  
  // Settings
  final int _maxFpsHistory = 60; // Number of frames to average
  final bool showDetailedStats;
  
  GamePerformanceOverlay({
    this.showDetailedStats = true,
    Vector2? position,
    Vector2? size,
  }) : super(
    position: position,
    size: size,
  );
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Create the text component for displaying stats
    _statsText = TextComponent(
      text: 'FPS: 0 | MEM: 0 MB',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              blurRadius: 2,
              color: Colors.black,
              offset: Offset(1, 1),
            ),
          ],
        ),
      ),
    );
    
    add(_statsText);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Skip frames to avoid excessive calculations
    _frameCount++;
    if (_frameCount % 10 != 0) return;
    
    // Calculate FPS
    final fps = 1 / dt;
    _fpsValues.add(fps);
    
    // Keep only the most recent frames for averaging
    if (_fpsValues.length > _maxFpsHistory) {
      _fpsValues.removeAt(0);
    }
    
    // Calculate average FPS
    _averageFps = _fpsValues.reduce((a, b) => a + b) / _fpsValues.length;
    
    // Estimate memory usage (this is approximate)
    // In a real app, you'd use a platform-specific method to get actual memory usage
    _memoryUsage = window.physicalSize.width * window.physicalSize.height * 4 / (1024 * 1024);
    
    // Update the display text
    if (showDetailedStats) {
      _statsText.text = 'FPS: ${_averageFps.toStringAsFixed(1)} | MEM: ${_memoryUsage.toStringAsFixed(1)} MB';
    } else {
      _statsText.text = 'FPS: ${_averageFps.toStringAsFixed(0)}';
    }
  }
}
