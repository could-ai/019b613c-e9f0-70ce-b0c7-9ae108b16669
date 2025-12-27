import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'bird_trap_game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'فخ العصافير',
      debugShowCheckedModeBanner: false,
      // دعم اللغة العربية
      locale: const Locale('ar', 'AE'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'AE'),
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4AF37)), // لون ذهبي للقمح
        useMaterial3: true,
        fontFamily: 'Serif', // خط بديل لـ Amiri لضمان العمل بدون إنترنت
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const BirdTrapGame(),
      },
    );
  }
}
