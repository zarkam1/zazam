// This file contains temporary workarounds for the game

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'space_shooter_game.dart';
import 'level_management.dart';
import 'enemy_manager.dart';

// ========== Extension Methods ==========

// Add the missing getCurrentLevel method to LevelManager
extension LevelManagerExtension on LevelManager {
  LevelDefinition getCurrentLevel() {
    return currentLevel;
  }
}

// Add the missing setSpawnParameters method to EnemyManager
extension EnemyManagerExtension on EnemyManager {
  void setSpawnParameters({
    required double spawnRate,
    required int maxEnemies,
    required double speedMultiplier,
    required List<String> availableTypes,
  }) {
    this.spawnRate = spawnRate;
    this.maxEnemies = maxEnemies;
    this.enemySpeedMultiplier = speedMultiplier;
    this.availableEnemyTypes = List<String>.from(availableTypes);
    
    print('EnemyManager: Updated spawn parameters - Rate: $spawnRate, Max: $maxEnemies, Speed: $enemySpeedMultiplier');
    print('EnemyManager: Available enemy types: $availableTypes');
  }
}

// ========== Simple Text Component ==========
// A simplified version of NeonText that extends TextComponent
class SimpleNeonText extends TextComponent {
  final Color color;
  final double glowIntensity;
  
  SimpleNeonText({
    required String text,
    this.color = Colors.purpleAccent,
    double fontSize = 24,
    this.glowIntensity = 0.8,
    Vector2? position,
    Vector2? size,
    Anchor? anchor,
  }) : super(
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
    position: position,
    size: size,
    anchor: anchor ?? Anchor.topLeft,
  );
  
  void setText(String newText) {
    text = newText;
  }
  
  @override
  void setOpacity(double opacity) {
    if (textRenderer is TextPaint) {
      final tp = textRenderer as TextPaint;
      final oldStyle = tp.style;
      final newStyle = oldStyle.copyWith(
        color: (oldStyle.color ?? const Color(0xFFFFFFFF)).withOpacity(opacity),
      );
      textRenderer = tp.copyWith((old) => newStyle);
    }
  }
}
