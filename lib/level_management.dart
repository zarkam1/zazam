import 'package:flutter/material.dart';

// Define the types of objectives a level can have
enum ObjectiveType { SURVIVE, DESTROY_COUNT, DESTROY_TARGETS, BOSS }

// Class to define a level's properties
class LevelDefinition {
  final int id;
  final String mapAsset;
  final ObjectiveType objectiveType;
  final dynamic objectiveValue; // e.g., int seconds, int count, String targetType
  final String briefingText;
  final int enemySpawnRate; // Enemies per minute
  final int enemyMaxOnScreen; // Maximum enemies on screen at once
  final double enemySpeedMultiplier; // Multiplier for enemy speed
  final List<String> availableEnemyTypes; // Types of enemies that can spawn in this level

  const LevelDefinition({
    required this.id,
    required this.mapAsset,
    required this.objectiveType,
    required this.objectiveValue,
    required this.briefingText,
    this.enemySpawnRate = 60, // Default: 1 enemy per second
    this.enemyMaxOnScreen = 10,
    this.enemySpeedMultiplier = 1.0,
    this.availableEnemyTypes = const ['basic'],
  });
}

// Class to manage the game's levels
class LevelManager {
  List<LevelDefinition> _levels = [];
  int _currentLevelIndex = 0;
  double _objectiveProgress = 0.0;
  bool _isLevelComplete = false;

  LevelManager() {
    _initializeLevels();
  }

  // Initialize with sample levels
  void _initializeLevels() {
    _levels = [
      LevelDefinition(
        id: 1,
        mapAsset: 'level1_background.png',
        objectiveType: ObjectiveType.SURVIVE,
        objectiveValue: 60, // Survive for 60 seconds
        briefingText: 'Survive for 60 seconds in asteroid territory.',
        enemySpawnRate: 30,
        enemyMaxOnScreen: 5,
        enemySpeedMultiplier: 1.0,
        availableEnemyTypes: ['basic'],
      ),
      LevelDefinition(
        id: 2,
        mapAsset: 'level2_background.png',
        objectiveType: ObjectiveType.DESTROY_COUNT,
        objectiveValue: 20, // Destroy 20 enemies
        briefingText: 'Destroy 20 enemy ships to clear the sector.',
        enemySpawnRate: 40,
        enemyMaxOnScreen: 7,
        enemySpeedMultiplier: 1.2,
        availableEnemyTypes: ['basic', 'fast'],
      ),
      LevelDefinition(
        id: 3,
        mapAsset: 'level3_background.png',
        objectiveType: ObjectiveType.DESTROY_COUNT,
        objectiveValue: 30, // Destroy 30 enemies
        briefingText: 'Clear the advanced enemy fleet.',
        enemySpawnRate: 50,
        enemyMaxOnScreen: 8,
        enemySpeedMultiplier: 1.5,
        availableEnemyTypes: ['basic', 'fast', 'tank'],
      ),
      LevelDefinition(
        id: 4,
        mapAsset: 'boss_background.png',
        objectiveType: ObjectiveType.BOSS,
        objectiveValue: 1, // Defeat 1 boss
        briefingText: 'Defeat the boss ship to complete your mission!',
        enemySpawnRate: 0, // No regular enemies during boss fight
        enemyMaxOnScreen: 0,
        enemySpeedMultiplier: 1.0,
        availableEnemyTypes: [],
      ),
    ];
  }

  // Getters
  LevelDefinition get currentLevel => _levels[_currentLevelIndex];
  int get currentLevelIndex => _currentLevelIndex;
  bool get hasNextLevel => _currentLevelIndex < _levels.length - 1;
  double get objectiveProgress => _objectiveProgress;
  bool get isLevelComplete => _isLevelComplete;

  // Update the objective progress
  void updateObjectiveProgress(double progress) {
    _objectiveProgress = progress;
    
    // Mark level as complete if progress reaches 100%
    if (progress >= 1.0 && !_isLevelComplete) {
      _isLevelComplete = true;
    }
  }

  // Advance to the next level if possible
  bool advanceToNextLevel() {
    if (hasNextLevel) {
      _currentLevelIndex++;
      _objectiveProgress = 0.0;
      _isLevelComplete = false;
      return true;
    }
    return false;
  }

  // Reset to the first level
  void resetLevels() {
    _currentLevelIndex = 0;
    _objectiveProgress = 0.0;
    _isLevelComplete = false;
  }
  
  // Check if current level is a boss level
  bool get isBossLevel => currentLevel.objectiveType == ObjectiveType.BOSS;
}
