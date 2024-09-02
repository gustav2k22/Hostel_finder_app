
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hostel_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hostel_app/home.dart';
Future<void> signOut() async {
  try {
    await FirebaseAuth.instance.signOut();
    print("User logged out successfully");

    // You may want to navigate to the login screen or perform other actions after logout.
  } catch (e) {
    print("Error signing out: $e");
  }
}


class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
    return ListView(
    children: [
    ListTile(
    title: Text('Notifications'),
    trailing: Switch(
    value:settingsProvider.notifications, // Replace with actual notification status
    onChanged: (bool value) {
      settingsProvider.toggleNotifications(value);// Update notification status
    // Add your logic here
    },
    ),
    ),
    ListTile(
    title: Text('Dark Mode'),
    trailing: Switch(
    value: settingsProvider.darkMode, // Replace with actual dark mode status
    onChanged: (bool value) {
      settingsProvider.toggleDarkMode(value);// Update dark mode status
    // Add your logic here
    },
    ),
    ),
      ListTile(
        title: const Text('Language'),
        subtitle: Text(settingsProvider.language),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          _showLanguageDialog(context, settingsProvider);
        },
      ),
    ListTile(
    title: Text('Privacy Policy'),
    trailing: Icon(Icons.arrow_forward_ios),
    onTap: () {
    // Navigate to privacy policy page
    // Add navigation logic here
    },
    ),
    ListTile(
    title: Text('About'),
    trailing: Icon(Icons.arrow_forward_ios),
    onTap: () {
    // Navigate to about page
    // Add navigation logic here
    },
    ),
    ListTile(
    title: Text('Logout'),
    onTap: () {
     signOut();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()), // Navigate to ScreenB
        );

        // Handle Logout button press
      // Perform logout action
    // Add logout logic here
    },
    ),
    ],
    );
    }
      )
    );
  }
}

void _showLanguageDialog(BuildContext context, SettingsProvider provider) { // Changed method signature here
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Select Language'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _languageOption(context, provider, 'English'),
              _languageOption(context, provider, 'Spanish'),
              // Add more languages as needed
            ],
          ),
        ),
      );
    },
  );
}

Widget _languageOption(BuildContext context, SettingsProvider provider, String language) {
  return ListTile(
    title: Text(language),
    onTap: () {
      provider.changeLanguage(language);
      Navigator.pop(context);
    },
  );
}
