import 'package:flutter/material.dart';

import '../features/shell/home_shell.dart';

class QRCodeProfApp extends StatelessWidget {
  const QRCodeProfApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF14213D);
    const blue = Color(0xFF2563EB);

    return MaterialApp(
      title: 'QRCODE PROF',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: navy,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE8ECF3)),
          ),
        ),
      ),
      home: const HomeShell(),
    );
  }
}
