import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hostel_app/firebase_options.dart';
import 'package:hostel_app/home.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const HostelFinderApp());
}

class HostelFinderApp extends StatelessWidget {
  const HostelFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        // Add more providers if needed
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
      ),
    );
  }
}

class SettingsProvider with ChangeNotifier {
  bool _darkMode = false;
  bool _notifications = true;
  String _language = 'English';

  bool get darkMode => _darkMode;
  bool get notifications => _notifications;
  String get language => _language;

  void toggleDarkMode(bool value) {
    _darkMode = value;
    notifyListeners();
    // Add logic to apply dark mode throughout the app
  }

  void toggleNotifications(bool value) {
    _notifications = value;
    notifyListeners();
    // Add logic to handle notifications
  }

  void changeLanguage(String selectedLanguage) {
    _language = selectedLanguage;
    notifyListeners();
    // Add logic to change app language
  }
}
