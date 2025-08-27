import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/notification_service.dart';

class TestNotificationsPage extends StatefulWidget {
  @override
  _TestNotificationsPageState createState() => _TestNotificationsPageState();
}

class _TestNotificationsPageState extends State<TestNotificationsPage> {
  String? uid;

  @override
  void initState() {
    super.initState();
    _ensureAuth();
  }

  Future<void> _ensureAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    setState(() {
      uid = auth.currentUser?.uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Notifications'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Current UID: ${uid ?? "Loading..."}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: uid == null ? null : _testCreateNotification,
              child: Text('Create Test Notification'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: uid == null ? null : _testFirestore,
              child: Text('Test Basic Firestore'),
            ),
            SizedBox(height: 20),
            Text('Notifications Stream:'),
            SizedBox(height: 10),
            Expanded(
              child: uid == null
                  ? Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                      stream: NotificationService.streamNotificationsFor(uid!),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData) {
                          return Text('Loading...');
                        }
                        final docs = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              title: Text(data['title'] ?? 'No title'),
                              subtitle: Text(data['message'] ?? 'No message'),
                              trailing: Text(
                                data['read']?.toString() ?? 'false',
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testCreateNotification() async {
    try {
      await NotificationService.createChatInviteNotification(
        toUid: uid!,
        fromUid: 'test-user',
        fromName: 'Test User',
        sessionId: 'test-session-${DateTime.now().millisecondsSinceEpoch}',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Test notification created!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _testFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('test').add({
        'message': 'Hello from test!',
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Firestore test successful!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Firestore error: $e')));
    }
  }
}
