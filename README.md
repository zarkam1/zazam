# zazam

A space shooter.
Run:
flutter run -d windows





# Space Shooter Game Specification

## Current Features

### Core Mechanics
- Top-down space shooter with vertical scrolling
- Player controls: keyboard (arrow keys + space) and touch (joystick + fire button)
- Life system with 3 initial health points
- Score system based on destroying enemies
- Game ends if player loses all health or 5 enemies pass through

### Visual Elements
- Dynamic starfield background with multiple star shapes and colors
- Particle effects for explosions
- Animated player ship and enemies
- UI showing health, score, and enemies passed
- Power-up status indicators
- Parallax scrolling effect

### Enemies
1. Basic Enemy
   - Health: 1
   - Speed: Normal
   - Score: 10 points
   - Shoots every 3.0 seconds

2. Fast Enemy
   - Health: 1
   - Speed: 50% faster than basic
   - Score: 15 points
   - Shoots every 2.5 seconds

3. Tank Enemy
   - Health: 3
   - Speed: 50% slower than basic
   - Score: 30 points
   - Shoots every 4.0 seconds
   - Counts towards "enemies passed" limit

### Power-ups
1. Speed Boost
   - Duration: 5 seconds
   - Effect: 2x movement speed

2. Rapid Fire
   - Duration: 5 seconds
   - Effect: Halves shooting cooldown

3. Shield
   - Duration: 10 seconds
   - Effect: Blocks enemy shots

4. Extra Life
   - Effect: Adds one health point (max 5)

### Audio
- Background music with dynamic speed based on enemies passed
- Sound effects for:
  - Laser shots (player and enemy)
  - Explosions
  - Power-up collection
  - Shield hits
  - Player damage
  - Game over

## Current Issues
1. Ship collision is too punishing (instant game over)
2. Limited enemy variety
3. No progression system
4. No boss fights
5. Temporary power-ups don't provide lasting progression
6. Limited strategic choices during gameplay

## Technical Implementation
- Built with Flutter and Flame game engine
- Component-based architecture
- State management for game phases
- Collision detection system
- Particle system for effects
- Audio management with pooling
- UI overlay system