// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/bluetooth_service.dart';
import 'screens/controller_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF070B12),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const SteadyBoiApp());
}

class SteadyBoiApp extends StatelessWidget {
  const SteadyBoiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RobotBluetoothService(),
      child: MaterialApp(
        title: 'SteadyBoi',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const ControllerScreen(),
      ),
    );
  }
}
