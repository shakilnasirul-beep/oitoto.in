import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await ApiService().init();
  runApp(const OiTotoCustomerApp());
}

class OiTotoCustomerApp extends StatelessWidget {
  const OiTotoCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oi Toto!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('bn', ''),
        Locale('hi', ''),
      ],
      locale: const Locale('en', ''),
      home: const SplashScreen(),
    );
  }
}
