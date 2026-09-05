import 'package:flutter/material.dart';

import 'screens/library_screen.dart';

void main() {
  runApp(const BooknoteApp());
}

class BooknoteApp extends StatelessWidget {
  const BooknoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booknote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const LibraryScreen(),
    );
  }
}
