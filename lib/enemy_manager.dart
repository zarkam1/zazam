import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'enemies.dart';
import 'boss_enemy.dart';
import 'space_shooter_game.dart';
import 'game_reference.dart';
import 'level_management.dart';
import 'powerup.dart';

class EnemyManager extends Component with HasGameRef<SpaceShooterGame> {
  final Random random = Random();
  double enemySpawnTimer = 0;
  double spawnRate = 30.0; // Enemies per minute
  double get spawnInterval => 60.0 / spawnRate; // Convert to seconds between spawns
  int maxEnemies = 5;
  double enemySpeedMultiplier = 1.0;
  List<String> availableEnemyTypes = ['basic', 'fast', 'tank'];

  @override
  void update(double dt) {
    if (gameRef.gameStateManager.state != GameState.playing)  {
    // Remove all enemies and power-ups when not playing
    gameRef.children.whereType<Enemy>().forEach((enemy) => enemy.removeFromParent());
    gameRef.children.whereType<PowerUp>().forEach((powerUp) => powerUp.removeFromParent());
    return;
  }

    enemySpawnTimer += dt;
    
    // Debug info
    if (enemySpawnTimer >= spawnInterval) {
      print('Enemy spawn check - Timer: $enemySpawnTimer, Interval: $spawnInterval');
      print('Current enemies: ${gameRef.children.query<Enemy>().length}, Max: $maxEnemies');
    }
    
    // Remove the 100 enemy limit that was causing spawning to stop
    if (enemySpawnTimer >= spawnInterval && 
        gameRef.children.query<Enemy>().length < maxEnemies) {
      spawnEnemy();
      spawnPowerUp();
      enemySpawnTimer = 0;
    }
  }

  void spawnEnemy() {
    // Get available enemy types from current level
    List<String> enemyTypes = gameRef.levelManager?.currentLevel.availableEnemyTypes ?? ['basic'];
    if (enemyTypes.isEmpty) {
      enemyTypes = ['basic']; // Fallback to basic enemy if none specified
    }
    
    // Select random enemy type from available types
    String enemyType = enemyTypes[random.nextInt(enemyTypes.length)];
    
    // Create enemy based on type
    Enemy enemy;
    switch (enemyType) {
      case 'fast':
        enemy = FastEnemy();
        break;
      case 'tank':
        enemy = TankEnemy();
        break;
      case 'basic':
      default:
        enemy = BasicEnemy();
    }
    
    // Apply level-specific speed multiplier
    enemy.speed *= enemySpeedMultiplier;
    
    // Set random position at top of screen
    enemy.position = Vector2(random.nextDouble() * gameRef.size.x, -50);
    
    // Add to game
    gameRef.add(enemy);
    gameRef.gameStateManager.enemySpawned();
  }

  void spawnPowerUp() {
    if (random.nextDouble() < 0.1) {
      // 10% chance to spawn a power-up
      PowerUp powerUp;
      int randomPowerUp = random.nextInt(4);
      switch (randomPowerUp) {
        case 0:
          powerUp = SpeedBoost(
              position: Vector2(random.nextDouble() * gameRef.size.x, -50));
          break;
        case 1:
          powerUp = ExtraLife(
              position: Vector2(random.nextDouble() * gameRef.size.x, -50));
          break;
        case 2:
          powerUp = RapidFire(
              position: Vector2(random.nextDouble() * gameRef.size.x, -50));
          break;
        case 3:
          powerUp = Shield(
              position: Vector2(random.nextDouble() * gameRef.size.x, -50));
          break;
        default:
          powerUp = SpeedBoost(
              position: Vector2(random.nextDouble() * gameRef.size.x, -50));
      }
      gameRef.add(powerUp);
    }
  }

  void reset() {
    enemySpawnTimer = 0;
    
    // Remove all existing enemies
    gameRef.children
        .whereType<Enemy>()
        .forEach((enemy) => enemy.removeFromParent());
    
    // Remove all existing power-ups
    gameRef.children
        .whereType<PowerUp>()
        .forEach((powerUp) => powerUp.removeFromParent());
    
    // Reset to current level settings
    if (gameRef.levelManager != null) {
      final currentLevel = gameRef.levelManager!.currentLevel;
      spawnRate = currentLevel.enemySpawnRate.toDouble();
      maxEnemies = currentLevel.enemyMaxOnScreen;
      enemySpeedMultiplier = currentLevel.enemySpeedMultiplier;
      availableEnemyTypes = List<String>.from(currentLevel.availableEnemyTypes);
    }
  }
  
  // Spawn a boss enemy for boss levels
  void spawnBoss() {
    try {
      print('Spawning boss enemy');
      
      // Clear any existing enemies
      gameRef.children
          .whereType<Enemy>()
          .forEach((enemy) => enemy.removeFromParent());
      
      // Create and add the boss
      final boss = BossEnemy();
      gameRef.add(boss);
      
      // Track the boss for objective completion
      gameRef.currentBoss = boss;
    } catch (e) {
      print('Error spawning boss: $e');
    }
  }
}
