import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const FTrackApp());
}

class FTrackApp extends StatelessWidget {
  const FTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'F-Track',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}