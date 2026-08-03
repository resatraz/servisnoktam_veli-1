import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialization geçici olarak devre dışı
  // if (kIsWeb) {
  //   await Firebase.initializeApp(
  //     options: const FirebaseOptions(
  //       apiKey: "AIzaSyDxItT52cgscNXo_Dyj3LUZlTxV6JOm6uY",
  //       authDomain: "servis-takip-33292.firebaseapp.com",
  //       databaseURL: "https://servis-takip-33292-default-rtdb.europe-west1.firebasedatabase.app",
  //       projectId: "servis-takip-33292",
  //       storageBucket: "servis-takip-33292.firebasestorage.app",
  //       messagingSenderId: "25269850839",
  //       appId: "1:25269850839:web:05723f489f42f2fc5b5692"
  //     ),
  //   );
  // } else {
  //   await Firebase.initializeApp();
  // }
  
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
