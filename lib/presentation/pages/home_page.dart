import 'package:flutter/material.dart';
import 'package:vision_guide/presentation/pages/navigation_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                header: true,
                child: const Text(
                  'Vision Guide',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Semantics(
                button: true,
                label:
                    'Start Vision Guide. Double tap to activate camera and start detecting obstacles',
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NavigationPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 7, 137, 243),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: const Text('START GUIDE'),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                liveRegion: true,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'This app will use your camera to detect obstacles and read text aloud. Make sure to hold your phone facing forward.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
