import 'package:flutter/material.dart';
import 'package:homehunt/pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HomeHunt',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        textSelectionTheme: TextSelectionThemeData(cursorColor: Colors.grey),
      ),
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
