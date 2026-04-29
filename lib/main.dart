import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'utils/theme_utils.dart';

void main() => runApp(GameVault());

class GameVault extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SteamTheme.darkBg,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(bodyColor: Colors.white),
      ),
      home: HomeScreen(),
    );
  }
}