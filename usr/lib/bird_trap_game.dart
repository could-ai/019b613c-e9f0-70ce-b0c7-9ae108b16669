import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class BirdTrapGame extends StatefulWidget {
  const BirdTrapGame({super.key});

  @override
  State<BirdTrapGame> createState() => _BirdTrapGameState();
}

class _BirdTrapGameState extends State<BirdTrapGame> with TickerProviderStateMixin {
  // Game State
  final List<String> _targetWord = ['الـ', 'قـ', 'مـ', 'ح']; // The word "Al-Qamh" (Wheat)
  List<String> _collectedParts = [];
  List<Bird> _birds = [];
  bool _isTrapClosed = false;
  bool _gameWon = false;
  int _score = 0;
  
  // Animation & Loop
  late Timer _gameLoop;
  late AnimationController _trapController;
  final Random _random = Random();
  final double _groundHeight = 100.0;

  @override
  void initState() {
    super.initState();
    _trapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _startGame();
  }

  void _startGame() {
    _collectedParts = [];
    _birds = [];
    _isTrapClosed = false;
    _gameWon = false;
    _trapController.reset();
    
    // Start Game Loop
    _gameLoop = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      _updateGame();
    });

    // Spawn birds periodically
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_gameWon || !mounted) {
        timer.cancel();
        return;
      }
      _spawnBird();
    });
  }

  void _spawnBird() {
    if (_gameWon) return;
    
    // Decide which part to carry (mostly the next needed part, but sometimes random)
    String text;
    String nextNeeded = _targetWord[_collectedParts.length];
    
    if (_random.nextDouble() < 0.6) {
      text = nextNeeded; // 60% chance to spawn the needed part
    } else {
      // Random part from the word
      text = _targetWord[_random.nextInt(_targetWord.length)];
    }

    setState(() {
      _birds.add(Bird(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        x: -50, // Start off-screen left
        y: 50 + _random.nextDouble() * 200, // Random height
        speed: 2 + _random.nextDouble() * 2,
      ));
    });
  }

  void _updateGame() {
    if (!mounted) return;
    
    setState(() {
      // Move birds
      for (var bird in _birds) {
        bird.x += bird.speed;
        // Add a little sine wave bobbing
        bird.y += sin(bird.x / 50) * 1.5;
      }

      // Remove off-screen birds
      _birds.removeWhere((bird) => bird.x > MediaQuery.of(context).size.width + 50);
    });
  }

  void _onBirdTap(Bird bird) {
    if (_gameWon || _isTrapClosed) return;

    String nextNeeded = _targetWord[_collectedParts.length];

    if (bird.text == nextNeeded) {
      // Correct part!
      setState(() {
        _collectedParts.add(bird.text);
        _birds.remove(bird);
        _score += 10;
        
        // Visual feedback (could add sound here)
        
        // Check win
        if (_collectedParts.length == _targetWord.length) {
          _triggerWin();
        }
      });
    } else {
      // Wrong part
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ابحث عن: $nextNeeded', style: const TextStyle(fontSize: 20)),
          duration: const Duration(milliseconds: 500),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _triggerWin() {
    _gameWon = true;
    _gameLoop.cancel();
    _isTrapClosed = true;
    _trapController.forward(); // Close the trap
    
    // Show success dialog
    Future.delayed(const Duration(seconds: 1), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('أحسنت!'),
          content: const Text('لقد جمعت كلمة "القمح" واصطدت العصافير!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startGame();
              },
              child: const Text('العب مرة أخرى'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _gameLoop.cancel();
    _trapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background (Sky, Sun, Hills, Wheat)
          Positioned.fill(
            child: CustomPaint(
              painter: CountrysidePainter(),
            ),
          ),

          // 2. The Trap (Center Bottom)
          Positioned(
            bottom: _groundHeight - 20,
            left: size.width / 2 - 60,
            child: AnimatedBuilder(
              animation: _trapController,
              builder: (context, child) {
                // Rotate the box to close it
                // 0.0 = Open (propped up), 1.0 = Closed (flat)
                double angle = (1.0 - _trapController.value) * (-pi / 6); // -30 degrees open
                double yOffset = _trapController.value * 20; // Move down slightly when closing

                return Transform.translate(
                  offset: Offset(0, yOffset),
                  child: Transform.rotate(
                    angle: angle,
                    alignment: Alignment.bottomRight,
                    child: CustomPaint(
                      size: const Size(120, 100),
                      painter: TrapPainter(),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Stick holding the trap (Disappears when closed)
          if (!_isTrapClosed)
            Positioned(
              bottom: _groundHeight + 10,
              left: size.width / 2 - 10,
              child: Container(
                width: 5,
                height: 70,
                color: Colors.brown[800],
              ),
            ),

          // 3. Birds
          ..._birds.map((bird) {
            return Positioned(
              left: bird.x,
              top: bird.y,
              child: GestureDetector(
                onTap: () => _onBirdTap(bird),
                child: BirdWidget(text: bird.text),
              ),
            );
          }),

          // 4. UI Overlay (Score & Word Progress)
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Target Word Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.brown, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("الكلمة المطلوبة: ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                      Row(
                        children: List.generate(_targetWord.length, (index) {
                          bool isCollected = index < _collectedParts.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: isCollected ? Colors.green[100] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _targetWord[index],
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isCollected ? Colors.green[800] : Colors.grey[600],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Models ---
class Bird {
  String id;
  String text;
  double x;
  double y;
  double speed;

  Bird({required this.id, required this.text, required this.x, required this.y, required this.speed});
}

// --- Widgets ---

class BirdWidget extends StatelessWidget {
  final String text;
  const BirdWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bird Visual
        Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
            ],
          ),
          child: Stack(
            children: [
              // Body color (Goldfinch style - simplified)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Colors.brown, Colors.yellow, Colors.white],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              // Red face
              Positioned(
                right: 0,
                top: 5,
                bottom: 5,
                child: Container(
                  width: 15,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Wing
              Positioned(
                left: 10,
                top: 15,
                child: Container(
                  width: 25,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Text carried by bird
        Container(
          margin: const EdgeInsets.only(top: 5),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black12),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// --- Painters ---

class CountrysidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 1. Sky (Sunset Gradient)
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF6A1B9A), Color(0xFFFFAB00)], // Purple to Orange
    ).createShader(rect);
    canvas.drawRect(rect, paint);
    paint.shader = null;

    // 2. Sun
    paint.color = const Color(0xFFFFD740).withOpacity(0.8);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 40, paint);

    // 3. Hills (Background)
    paint.color = const Color(0xFF5D4037); // Dark Brown
    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);
    path1.quadraticBezierTo(size.width * 0.25, size.height * 0.6, size.width * 0.5, size.height * 0.7);
    path1.quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.65);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint);

    // 4. Hills (Foreground - Wheat Field Base)
    paint.color = const Color(0xFF8D6E63); // Lighter Brown
    final path2 = Path();
    path2.moveTo(0, size.height * 0.8);
    path2.quadraticBezierTo(size.width * 0.5, size.height * 0.75, size.width, size.height * 0.85);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);

    // 5. Wheat Stalks (Simple lines)
    paint.color = const Color(0xFFFFD54F); // Gold
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    
    // Draw many stalks
    final random = Random(42); // Fixed seed for consistency
    for (int i = 0; i < 100; i++) {
      double x = random.nextDouble() * size.width;
      double yBase = size.height * 0.8 + random.nextDouble() * (size.height * 0.2);
      double height = 20 + random.nextDouble() * 30;
      
      // Stalk
      canvas.drawLine(Offset(x, yBase), Offset(x, yBase - height), paint);
      
      // Wheat head (small oval/dots)
      canvas.drawOval(Rect.fromCenter(center: Offset(x, yBase - height), width: 6, height: 10), paint);
    }
    
    // 6. Cactus/Fig Tree (Silhouette)
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF33691E); // Dark Green
    
    // Simple Cactus
    double cactusX = size.width * 0.1;
    double cactusY = size.height * 0.75;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cactusX, cactusY - 60, 20, 60), const Radius.circular(10)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cactusX - 15, cactusY - 40, 15, 10), const Radius.circular(5)), paint); // Arm left
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cactusX - 15, cactusY - 50, 10, 20), const Radius.circular(5)), paint); // Arm left up
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Wooden Box Frame
    paint.color = const Color(0xFF5D4037); // Wood color
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4;
    
    // Outer box
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);
    
    // Mesh/Wire
    paint.color = Colors.black38;
    paint.strokeWidth = 1;
    // Vertical wires
    for(double i = 10; i < size.width; i+=15) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    // Horizontal wires
    for(double i = 10; i < size.height; i+=15) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
    
    // Wood Crossbars
    paint.color = const Color(0xFF5D4037);
    paint.strokeWidth = 4;
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
