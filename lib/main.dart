import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'space_shooter_game.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: GameWidget<SpaceShooterGame>(
          game: SpaceShooterGame(),
          initialActiveOverlays: const ['initial_overlay'],
          overlayBuilderMap: {
            'initial_overlay': (_, SpaceShooterGame game) {
              return const Center(
                child: Text('Loading...', style: TextStyle(color: Colors.white, fontSize: 24)),
              );
            },
          },
          loadingBuilder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
          errorBuilder: (context, ex) {
            print('Error during game initialization: $ex');
            return Center(
              child: Text('Error: ${ex.toString()}', style: TextStyle(color: Colors.red, fontSize: 24)),
            );
          },
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Space Shooter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: SpaceShooterGame(),
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (context, error) => Center(
          child: Text('An error occurred: $error'),
        ),
        overlayBuilderMap: {
          'pause_menu': (context, game) => const PauseMenu(),
        },
      ),
    );
  }
}

class PauseMenu extends StatelessWidget {
  const PauseMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.black54,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paused', style: TextStyle(fontSize: 24, color: Colors.white)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Resume game logic here
              },
              child: const Text('Resume'),
            ),
          ],
        ),
      ),
    );
  }
}