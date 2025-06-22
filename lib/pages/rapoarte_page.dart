import 'package:flutter/material.dart';

class RapoartePage extends StatefulWidget {
  const RapoartePage({super.key});

  @override
  RapoartePageState createState() => RapoartePageState();
}

class RapoartePageState extends State<RapoartePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Raport Page'),
      ),
      body: Center(
        child: Text('Content goes here'),
      ),
    );
  }
}