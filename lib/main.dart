import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- 1. Add this import
import 'screens/main_screen.dart';

// 2. Make main() async
Future<void> main() async {
  // 3. Ensure Flutter is initialized before loading .env
  WidgetsFlutterBinding.ensureInitialized();
  
  // 4. Load the .env file BEFORE the app runs
  await dotenv.load(fileName: ".env");
  
  runApp(const ColorPickerApp());
}

class ColorPickerApp extends StatelessWidget {
  const ColorPickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MyWidget(),
    );
  }
}