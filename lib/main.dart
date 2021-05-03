import 'package:flutter/material.dart';
import 'MainScreen.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      initialRoute: MainScreen.id,
      routes: {
        MainScreen.id:(context) => MainScreen(),
      },);
  }
}