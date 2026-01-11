import 'package:flutter/material.dart';

import 'screens/feed_screen.dart';

void main() {
  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {   //statelesswidget을 override한다.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Feed',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1DB954)),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const FeedScreen(),
    );
  }
}