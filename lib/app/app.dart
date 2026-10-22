import 'package:flutter/material.dart';

import '../features/game/game_screen.dart';
import 'theme.dart';

class MergeEmpireApp extends StatelessWidget {
  const MergeEmpireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merge Empire',
      debugShowCheckedModeBanner: false,
      theme: MergeEmpireTheme.light(),
      home: const GameScreen(),
    );
  }
}
