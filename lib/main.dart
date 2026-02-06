import 'package:flutter/material.dart';
import 'package:iss_app/SplashScreen.dart';
import 'package:flutter/services.dart';
import 'package:iss_app/auth_page.dart';

const platform = MethodChannel("secure.screen");


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable screenshot for entire app
  await platform.invokeMethod("disableScreenshot");
  // Disable Screen Rotation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);



  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iss_app',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurpleAccent,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),

        ),
        home: AuthPage(),
      );


  }
}
