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
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: DriverColors.primaryGreen),
              const SizedBox(height: 12),
              const Text('Oi Toto Partner', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DriverColors.deepNavy)),
              const SizedBox(height: 6),
              Text(details.exceptionAsString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: DriverColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  };
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
