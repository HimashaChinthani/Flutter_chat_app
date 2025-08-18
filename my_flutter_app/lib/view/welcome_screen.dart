import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/user_service.dart' as user_svc;
import '../services/invite_service.dart';
import '../services/notification_service.dart';
import '../view/chat_screen.dart';
import '../view/notifications_screen.dart';
import 'dart:async';
import 'qr_generator.dart';
import 'qr_scanner.dart';
import 'chat_history.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _displayName;
  bool _prompted = false; // prevent duplicate dialogs
  int _selectedNav = 0;
  String? _currentUid; // Store current user UID for notifications

  @override
  void initState() {
    super.initState();
    // Defer UI work (dialogs) until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNameFlow());
    // Start listening for incoming invites for this device/user.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startInviteListener());
    // Fallback: if nothing happened within 1200ms, ensure we prompt
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_displayName == null && !_prompted) {
        _ensureNamePrompt();
      }
    });
  }

  StreamSubscription? _inviteSub;

  Future<void> _startInviteListener() async {
    try {
      final auth = fb_auth.FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
      final uid = auth.currentUser?.uid;
      if (uid == null) return;

      // Store the UID for notifications
      _currentUid = uid;

      // Listen for pending invites addressed to this UID.
      _inviteSub = InviteService.streamPendingFor(uid).listen((snap) async {
        if (snap.docs.isEmpty) return;
        for (final doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final sessionId = (data['sessionId'] as String?);
          final fromName = (data['fromName'] as String?) ?? 'Someone';
          if (sessionId == null) continue;

          // Only show alert notification - no immediate popup
          NotificationService.showAlert(
            context,
            'New Chat Request',
            '$fromName wants to chat with you',
            onTap: () {
              // Navigate to notifications tab
              setState(() => _selectedNav = 4);
            },
          );

          // Note: We removed the immediate popup dialog here
          // Users should go to notifications page to accept/reject
        }
      });
    } catch (e) {
      // ignore for now
    }
  }

  Future<void> _initNameFlow() async {
    try {
      // 1) Check local storage first
      final prefs = await SharedPreferences.getInstance();
      final localName = prefs.getString('displayName');
      if (localName != null && localName.trim().isNotEmpty) {
        setState(() => _displayName = localName.trim());

        // Ensure the name exists in Firestore under the saved UID if possible.
        try {
          final savedUid = prefs.getString('savedUid');
          if (savedUid != null && savedUid.isNotEmpty) {
            final existing = await user_svc.UserService.getUser(savedUid);
            if (existing == null || existing.name.trim().isEmpty) {
              await user_svc.UserService.createUser(
                name: localName.trim(),
                uid: savedUid,
              );
            }
          }
        } catch (_) {}

        return;
      }

      // 2) Determine UID to use. Prefer savedUid to avoid new anonymous sign-ins
      String? uidToUse;
      try {
        uidToUse = prefs.getString('savedUid');
      } catch (_) {}

      final auth = fb_auth.FirebaseAuth.instance;
      if (uidToUse == null) {
        if (auth.currentUser != null) {
          uidToUse = auth.currentUser!.uid;
          try {
            await prefs.setString('savedUid', uidToUse);
          } catch (_) {}
        } else {
          // No saved UID and no active auth: create anon and persist it
          final cred = await auth.signInAnonymously();
          uidToUse = cred.user?.uid;
          if (uidToUse != null) {
            try {
              await prefs.setString('savedUid', uidToUse);
            } catch (_) {}
          }
        }
      }

      if (uidToUse == null) return;

      // 3) Try to load existing user profile from Firestore for this UID
      final existing = await user_svc.UserService.getUser(uidToUse);
      if (!mounted) return;
      if (existing != null && existing.name.trim().isNotEmpty) {
        final name = existing.name.trim();
        // Save to local for future fast loads
        await prefs.setString('displayName', name);
        setState(() => _displayName = name);
        return;
      }

      // Check per-UID prompted flag so we don't repeatedly ask the same Firebase user
      final promptedKey = 'displayNamePrompted_$uidToUse';
      final alreadyPromptedForUid = prefs.getBool(promptedKey) ?? false;
      if (alreadyPromptedForUid) return;

      // First time – prompt for name
      await _ensureNamePrompt();
    } catch (e) {
      if (!mounted) return;
      // Show a brief warning but still prompt for the name
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile check issue, please set your name. ($e)'),
        ),
      );
      await _ensureNamePrompt();
    }
  }

  @override
  void dispose() {
    try {
      _inviteSub?.cancel();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _ensureNamePrompt() async {
    if (_prompted || !mounted) return;
    _prompted = true;
    final prefs = await SharedPreferences.getInstance();
    // Determine current auth uid to store a per-UID prompted flag.
    String? currentUid = prefs.getString('savedUid');
    try {
      final auth = fb_auth.FirebaseAuth.instance;
      if (auth.currentUser != null) {
        currentUid = auth.currentUser!.uid;
      } else if (currentUid == null) {
        final cred = await auth.signInAnonymously();
        currentUid = cred.user?.uid;
        if (currentUid != null) {
          try {
            await prefs.setString('savedUid', currentUid);
          } catch (_) {}
        }
      }
    } catch (_) {}
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set your display name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the name others will see:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'e.g. Alex',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.of(ctx).pop(value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (name == null || name.trim().isEmpty) {
      // User skipped; we marked as prompted so we won't show again
      setState(() => _displayName = null);
      return;
    }

    // Persist to local storage first, then Firestore
    try {
      final trimmed = name.trim();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('displayName', trimmed);
      // Persist prompted flag for this UID so we don't ask again
      final currentUid = prefs.getString('savedUid');
      if (currentUid != null) {
        try {
          await prefs.setBool('displayNamePrompted_$currentUid', true);
        } catch (_) {}
      }
      // Firestore write (not blocking the local save). Use savedUid when available
      late final String savedName;
      try {
        if (currentUid != null) {
          final created = await user_svc.UserService.createUser(
            name: trimmed,
            uid: currentUid,
          );
          savedName = created.name;
        } else {
          final created = await user_svc.UserService.createUser(name: trimmed);
          savedName = created.name;
        }
      } catch (e) {
        // Keep local storage value; notify but don't fail the flow
        savedName = trimmed;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved locally. Firestore sync pending: $e'),
            ),
          );
        }
      }
      if (!mounted) return;
      setState(() => _displayName = savedName);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Welcome, $savedName!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save name: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const navCount = 5; // Home, Generate, Scan, History, Notifications
    final displayIndex = (_selectedNav >= navCount) ? 0 : _selectedNav;
    return WillPopScope(
      onWillPop: () async {
        // If we're not on the Home tab, go back to Home instead of popping the route.
        if (_selectedNav != 0) {
          setState(() => _selectedNav = 0);
          return false; // prevent route pop
        }
        return true; // allow route pop (exit app or previous route)
      },
      child: Scaffold(
        body: IndexedStack(
          index: displayIndex,
          children: [
            // 0 - Home (welcome content)
            _welcomeBody(),
            // 1 - QR Generator
            QRGeneratorScreen(
              onBackToHome: () => setState(() => _selectedNav = 0),
            ),
            // 2 - QR Scanner
            QRScannerScreen(
              onBackToHome: () => setState(() => _selectedNav = 0),
            ),
            // 3 - Chat History
            ChatHistoryScreen(
              onBackToHome: () => setState(() => _selectedNav = 0),
            ),
            // 4 - Notifications
            NotificationsScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // Show all tabs
          currentIndex: displayIndex,
          selectedItemColor: AppTheme.primaryPurple,
          unselectedItemColor: Colors.black54,
          onTap: (idx) => _handleNavTap(idx),
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code),
              label: 'Generate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: _buildNotificationIcon(),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeBody() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryPurple, AppTheme.lightPurple],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 720;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top header
                      Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setState(() => _selectedNav = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _selectedNav == 0
                                      ? [Colors.white, Colors.white70]
                                      : [Colors.white24, Colors.white12],
                                ),
                                boxShadow: _selectedNav == 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.qr_code,
                                  color: _selectedNav == 0
                                      ? AppTheme.primaryPurple
                                      : Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ChatterQR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              if (_displayName != null)
                                Text(
                                  'Welcome, ${_displayName!}',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 22),

                      // Main area
                      Flexible(
                        child: isWide
                            ? Row(
                                children: [
                                  Expanded(child: _buildFeatureCards(context)),
                                  SizedBox(width: 20),
                                  Expanded(child: _buildOverviewCard(context)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildOverviewCard(context),
                                  SizedBox(height: 18),
                                  _buildFeatureCards(context),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleNavTap(int idx) async {
    setState(() => _selectedNav = idx);
  }

  Widget _buildNotificationIcon() {
    if (_currentUid == null) {
      return Icon(Icons.notifications);
    }

    return StreamBuilder<int>(
      stream: NotificationService.streamUnreadCountFor(_currentUid!),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        if (unreadCount == 0) {
          return Icon(Icons.notifications);
        }

        return Stack(
          children: [
            Icon(Icons.notifications),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: TextStyle(color: Colors.white, fontSize: 8),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.chat_bubble_outline, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName != null
                            ? 'Welcome back, ${_displayName!}'
                            : 'Welcome back',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Connect instantly with anyone through QR codes. Start chatting with strangers in seconds!',
              style: TextStyle(color: Colors.black87, height: 1.4),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCards(BuildContext context) {
    return Column(
      children: [
        _featureCard(
          context,
          color: Color(0xFF1EAD57),
          icon: Icons.qr_code_scanner,
          title: 'QR Scanner',
          subtitle: 'Scan QR codes using your device camera for quick access.',
          onPressed: () {
            setState(() => _selectedNav = 2);
          },
        ),
        SizedBox(height: 14),
        _featureCard(
          context,
          color: Color(0xFFF29A2E),
          icon: Icons.qr_code,
          title: 'QR Generator',
          subtitle: 'Create custom QR codes for chat rooms and share them.',
          onPressed: () {
            setState(() => _selectedNav = 1);
          },
        ),
        SizedBox(height: 14),
        _featureCard(
          context,
          color: Color(0xFF7C4DFF),
          icon: Icons.history,
          title: 'Recent Conversations',
          subtitle: 'Continue where you left off with your chat history.',
          onPressed: () {
            setState(() => _selectedNav = 3);
          },
        ),
      ],
    );
  }

  Widget _featureCard(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      color: Colors.white,
      elevation: 10,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(subtitle, style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              TextButton(
                onPressed: onPressed,
                child: Row(
                  children: [
                    Text(
                      'Get started',
                      style: TextStyle(
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.primaryPurple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
