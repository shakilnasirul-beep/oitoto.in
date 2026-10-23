import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/driver_theme.dart';
import 'core/services/driver_api_service.dart';
import 'screens/driver_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await DriverApiService().init();
  runApp(const OiTotoDriverApp());
}

class OiTotoDriverApp extends StatelessWidget {
  const OiTotoDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oi Toto Partner',
      debugShowCheckedModeBanner: false,
      theme: DriverTheme.lightTheme,
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
      home: const DriverSplashScreen(),
    );
  }
}
