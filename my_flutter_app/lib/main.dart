import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'view/welcome_screen.dart';
import 'services/crud_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase for all platforms using generated options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Ensure we have an authenticated user (anonymous is fine for testing)
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      print('Signed in anonymously for Firestore access');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const ChatApp());
}

Future<void> testFirebaseConnection() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final ref = firestore.collection('AppDiagnostics').doc('main_test');

    // Try to write a test value
    await ref.set({
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'message': 'Firestore connection test',
    });
    print('✅ Firestore write test successful');

    // Try to read the test value
    final snapshot = await ref.get();
    if (snapshot.exists) {
      print('✅ Firestore read test successful: ${snapshot.data()}');
    } else {
      print('❌ Firestore read test failed: no data');
    }
  } catch (e) {
    print('❌ Firestore connection test failed: $e');
  }
}

// UI-friendly tester that writes to 'users' with auto id and shows SnackBars
Future<void> testFirebaseConnectionUI(BuildContext context) async {
  final crudServices = CrudServices();
  final id = await crudServices.insertUserAuto(
    name: 'Test User ${DateTime.now().millisecondsSinceEpoch}',
  );
  if (!context.mounted) return;
  if (id != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Firebase OK! User inserted: $id'),
        backgroundColor: Colors.green,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Firebase connection failed!'),
        backgroundColor: Colors.red,
      ),
    );
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
