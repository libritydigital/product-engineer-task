import 'package:flutter/material.dart';
import 'screens/book_list_screen.dart';
import 'services.dart';

final bookService = BookService();
final insightService = InsightService();

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insight Catcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1DB954),
          secondary: Color(0xFF1DB954),
          surface: Color(0xFF282828),
        ),
        useMaterial3: true,
      ),
      home: const BookListScreen(),
    );
  }
}
