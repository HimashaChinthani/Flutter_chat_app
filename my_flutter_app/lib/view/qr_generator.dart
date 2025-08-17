import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../main.dart';
import 'qr_scanner.dart';

class QRGeneratorScreen extends StatefulWidget {
  @override
  _QRGeneratorScreenState createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  String userId = '';
  bool isWaitingForConnection = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final auth = fb_auth.FirebaseAuth.instance;
    // Prefer a saved UID from prefs to avoid creating a new anonymous
    // account on the same device/browser.
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('savedUid');
      if (savedUid != null && savedUid.isNotEmpty) {
        if (!mounted) return;
        setState(() => userId = savedUid);
        return;
      }
    } catch (_) {}

    if (auth.currentUser == null) {
      final cred = await auth.signInAnonymously();
      final uid = cred.user?.uid;
      if (uid != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('savedUid', uid);
        } catch (_) {}
        if (!mounted) return;
        setState(() => userId = uid);
        return;
      }
    }

    if (!mounted) return;
    setState(() => userId = auth.currentUser!.uid);
  }

  void startWaitingForConnection() async {
    setState(() {
      isWaitingForConnection = true;
    });

    // Simulate waiting for connection
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Waiting for someone to scan your QR code...'),
            backgroundColor: const Color.fromARGB(255, 9, 10, 15),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your QR Code'),
        backgroundColor: AppTheme.primaryPurple,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomCard(
              child: Column(
                children: [
                  Text(
                    'Share this QR code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  SizedBox(height: 16),

                  // QR Code
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentPurple),
                    ),
                    child: QrImageView(
                      data: userId.isEmpty
                          ? 'loading'
                          : 'https://chatterqr.app/u/' + userId,
                      version: QrVersions.auto,
                      size: 200.0,
                      foregroundColor: const Color.fromARGB(255, 7, 7, 8),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
            SizedBox(height: 32),

            // Single Scan button that navigates to the QR scanner
            CustomButton(
              text: 'Scan QR Code',
              icon: Icons.qr_code_scanner,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QRScannerScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
