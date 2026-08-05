import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/download_provider.dart';
import 'services/binary_manager_service.dart';
import 'ui/app_theme.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the native binaries before the app runs
  final binaryManager = BinaryManagerService();
  await binaryManager.initBinaries();

  runApp(const FortyFetchApp());
}

class FortyFetchApp extends StatelessWidget {
  const FortyFetchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
      ],
      child: MaterialApp(
        title: 'FortyFetch',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
