import 'package:flutter/material.dart';

import 'src/nexwall_api.dart';
import 'src/screens/categories_screen.dart';

void main() {
  runApp(NexWallApp(api: NexWallApi()));
}

class NexWallApp extends StatelessWidget {
  const NexWallApp({super.key, required this.api});

  final NexWallApi api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexWall Wallpapers',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: CategoriesScreen(api: api),
    );
  }
}
