import 'dart:math';
import 'package:flame/components.dart';
import 'powerup.dart';
import 'space_shooter_game.dart';
import 'enemies.dart';

class EnemyManager extends Component with HasGameRef<SpaceShooterGame> {
  final Random random = Random();
  double enemySpawnTimer = 0;
  static const double spawnInterval = 2.0;
  static const int maxEnemies = 5;

  @override
  void update(double dt) {
    if (gameRef.gameStateManager.state != GameState.playing)  {
    // Remove all enemies and power-ups when not playing
    gameRef.children.whereType<Enemy>().forEach((enemy) => enemy.removeFromParent());
    gameRef.children.whereType<PowerUp>().forEach((powerUp) => powerUp.removeFromParent());
    return;
  }

    enemySpawnTimer += dt;
    if (enemySpawnTimer >= spawnInterval &&
        gameRef.children.query<Enemy>().length < maxEnemies &&
        gameRef.gameStateManager.enemiesSpawned < 100) {
      spawnEnemy();
      spawnPowerUp();
      enemySpawnTimer = 0;
    }
  }

  void spawnEnemy() {
    Enemy enemy;
    int randomEnemy = random.nextInt(3);
    switch (randomEnemy) {
      case 0:
        enemy = BasicEnemy();
        break;
      case 1:
        enemy = FastEnemy();
        break;
      case 2:
        enemy = TankEnemy();
        break;
      default:
        enemy = BasicEnemy();
    }
    enemy.position = Vector2(random.nextDouble() * gameRef.size.x, -50);
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

  }
}
