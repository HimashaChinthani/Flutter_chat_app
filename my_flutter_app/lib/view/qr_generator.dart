import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import '../main.dart';
import 'dart:math';

class QRGeneratorScreen extends StatefulWidget {
  @override
  _QRGeneratorScreenState createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  String sessionId = '';
  bool isWaitingForConnection = false;

  @override
  void initState() {
    super.initState();
    generateSessionId();
  }

  void generateSessionId() {
    final random = Random();
    sessionId = 'chat_${random.nextInt(999999).toString().padLeft(6, '0')}';
  }

  void startWaitingForConnection() {
    setState(() {
      isWaitingForConnection = true;
    });
    
    // Simulate waiting for connection
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Waiting for someone to scan your QR code...'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate QR Code'),
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
                      color: AppTheme.primaryPurple,
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
                      data: sessionId,
                      version: QrVersions.auto,
                      size: 200.0,
                      foregroundColor: AppTheme.primaryPurple,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  Text(
                    'Session ID: $sessionId',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            
            if (!isWaitingForConnection) ...[
              CustomButton(
                text: 'Start Waiting for Connection',
                icon: Icons.wifi_tethering,
                onPressed: startWaitingForConnection,
              ),
            ] else ...[
              LoadingWidget(message: 'Waiting for connection...'),
              SizedBox(height: 16),
              CustomButton(
                text: 'Stop Waiting',
                backgroundColor: Colors.red,
                onPressed: () {
                  setState(() {
                    isWaitingForConnection = false;
                  });
                },
              ),
            ],
            
            SizedBox(height: 16),
            CustomButton(
              text: 'Generate New QR Code',
              backgroundColor: AppTheme.lightPurple,
              onPressed: () {
                generateSessionId();
                setState(() {
                  isWaitingForConnection = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
