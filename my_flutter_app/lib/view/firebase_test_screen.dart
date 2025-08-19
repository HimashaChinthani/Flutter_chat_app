import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Testing Firebase...';
  bool _isLoading = true;
  String _testData = '';

  @override
  void initState() {
    super.initState();
    _testFirebase();
  }

  Future<void> _testFirebase() async {
    try {
      setState(() {
        _status = 'Initializing Firebase connection...';
        _isLoading = true;
      });

      final firestore = FirebaseFirestore.instance;
      final ref = firestore.collection('AppDiagnostics').doc('firebase_test');

      // Test write
      setState(() {
        _status = 'Testing Firebase write...';
      });

      await ref.set({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'message': 'Firestore connection test from Flutter app',
        'status': 'active',
      });

      setState(() {
        _status = 'Write successful! Testing read...';
      });

      // Test read
      final snapshot = await ref.get();
      if (snapshot.exists) {
        setState(() {
          _status = '✅ Firestore is working perfectly!';
          _testData = snapshot.data()!.toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = '❌ Write successful but read failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Firestore test failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: BackButton(), title: const Text('Firebase Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _status,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_testData.isNotEmpty) ...[
              const Text(
                'Test Data Retrieved:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _testData,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _testFirebase,
              child: const Text('Test Again'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Welcome'),
            ),
          ],
        ),
      ),
    );
  }
}
