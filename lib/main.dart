import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase geçici olarak devre dışı - initialization hatası
  // Firebase Web config gerekli
  runApp(const ServisNoktamVeliApp());
}

class ServisNoktamVeliApp extends StatelessWidget {
  const ServisNoktamVeliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ServisNoktam Veli',
      theme: AppTheme.theme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
