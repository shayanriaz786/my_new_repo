import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(RapidFluxApp());
}

class RapidFluxApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RapidFlux Runner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _jumpController;
  late Animation<double> _jumpAnimation;
  bool isJumping = false;
  double playerY = 0.0;
  double playerX = 50;
  double playerWidth = 50;
  double playerHeight = 50;
  double jumpHeight = 150;
  double groundLevel = 0.0;

  List<Obstacle> obstacles = [];
  double obstacleSpeed = 4.0;
  int score = 0;
  late Timer _gameLoop;

  @override
  void initState() {
    super.initState();

    // Animation controller for player jump
    _jumpController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _jumpAnimation = Tween(begin: 0.0, end: jumpHeight).animate(_jumpController)
      ..addListener(() {
        setState(() {
          playerY = -_jumpAnimation.value;
        });
      });

    // Start the game loop
    _startGameLoop();
    // Generate obstacles every 2 seconds
    _startObstacleGeneration();
  }

  void _startGameLoop() {
    _gameLoop = Timer.periodic(Duration(milliseconds: 16), (timer) {
      setState(() {
        // Move obstacles
        for (var obstacle in obstacles) {
          obstacle.x -= obstacleSpeed;
        }

        // Remove obstacles that have moved off the screen
        obstacles.removeWhere((obstacle) => obstacle.x < -obstacle.width);

        // Check for collisions
        for (var obstacle in obstacles) {
          if (obstacle.x < playerX + playerWidth &&
              obstacle.x + obstacle.width > playerX &&
              playerY == 0) {
            // Collision detected
            _gameOver();
          }
        }

        // Increase the score over time
        score++;
      });
    });
  }

  void _startObstacleGeneration() {
    Timer.periodic(Duration(seconds: 2), (timer) {
      _generateObstacle();
    });
  }

  void _generateObstacle() {
    setState(() {
      obstacles.add(Obstacle(x: 400, y: groundLevel, width: 40, height: 50));
    });
  }

  void _jump() {
    if (!isJumping) {
      _jumpController.forward(from: 0.0);
      setState(() {
        isJumping = true;
      });

      // After jump animation, return to the ground
      _jumpController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            isJumping = false;
            playerY = 0.0;
          });
        }
      });
    }
  }

  void _gameOver() {
    // Stop the game loop
    _gameLoop.cancel();
    // Navigate to the game over screen
    Timer(Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameOverScreen(score: score),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! < 0) {
            _jump();
          }
        },
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                color: Colors.blueGrey[900],
              ),
            ),

            // Obstacles
            ...obstacles.map((obstacle) {
              return Positioned(
                left: obstacle.x,
                top: obstacle.y,
                child: Container(
                  width: obstacle.width,
                  height: obstacle.height,
                  color: Colors.red,
                ),
              );
            }).toList(),

            // Player
            Positioned(
              left: playerX,
              top: playerY,
              child: Container(
                width: playerWidth,
                height: playerHeight,
                color: Colors.green,
              ),
            ),

            // Score Display
            Positioned(
              top: 40,
              left: 20,
              child: Text(
                'Score: $score',
                style: TextStyle(color: Colors.white, fontSize: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _jumpController.dispose();
    _gameLoop.cancel();
    super.dispose();
  }
}

// Obstacle class
class Obstacle {
  double x;
  double y;
  double width;
  double height;

  Obstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

// Game Over Screen
class GameOverScreen extends StatelessWidget {
  final int score;

  const GameOverScreen({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "Game Over!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 50,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Score: $score",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Restart the game
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => GameScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: TextStyle(fontSize: 20),
              ),
              child: Text("Retry"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: TextStyle(fontSize: 20),
              ),
              child: Text("Main Menu"),
            ),
          ],
        ),
      ),
    );
  }
}
