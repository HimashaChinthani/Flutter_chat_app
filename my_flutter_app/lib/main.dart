import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'theme.dart';
import 'view/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');

    // Test Firebase connection
    await testFirebaseConnection();
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const ChatApp());
}

Future<void> testFirebaseConnection() async {
  try {
    final database = FirebaseDatabase.instance;
    final ref = database.ref('test');

    // Try to write a test value
    await ref.set({
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'message': 'Firebase connection test',
    });
    print('✅ Firebase write test successful');

    // Try to read the test value
    final snapshot = await ref.get();
    if (snapshot.exists) {
      print('✅ Firebase read test successful: ${snapshot.value}');
    } else {
      print('❌ Firebase read test failed: no data');
    }
  } catch (e) {
    print('❌ Firebase connection test failed: $e');
  }
}

class ChatApp extends StatelessWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Chat App',
      theme: AppTheme.theme,
      home: WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Common Components
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppTheme.primaryPurple,
        foregroundColor: textColor ?? Colors.white,
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor ?? Colors.white),
            SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const CustomCard({
    Key? key,
    required this.child,
    this.padding,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor ?? Colors.white,
      child: Padding(padding: padding ?? EdgeInsets.all(16), child: child),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final String message;

  const LoadingWidget({Key? key, this.message = 'Loading...'})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppTheme.primaryPurple, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
