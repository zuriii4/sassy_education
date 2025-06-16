import 'package:flutter/material.dart';
import 'package:sassy/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sassy',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const SplashScreen(),
    );
  }
}