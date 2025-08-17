import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../main.dart';
import '../services/user_service.dart' as user_svc;
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

  @override
  void initState() {
    super.initState();
    // Defer UI work (dialogs) until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNameFlow());
    // Fallback: if nothing happened within 1200ms, ensure we prompt
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_displayName == null && !_prompted) {
        _ensureNamePrompt();
      }
    });
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryPurple, AppTheme.lightPurple],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated App Logo/Icon with gradient border (glassmorphism)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          width: 4,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.10),
                        ),
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.9, end: 1.1),
                            duration: Duration(seconds: 2),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 1 + 0.04 * (value - 1),
                                child: child,
                              );
                            },
                            onEnd: () {},
                            child: Icon(
                              Icons.chat_bubble_outline,
                              size: 60,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 12,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 28),
                    // App Title
                    Text(
                      'ChatterQR',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    if (_displayName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Welcome, ${_displayName!}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    SizedBox(height: 12),
                    Text(
                      'Connect instantly with anyone through\nQR codes. Start chatting with strangers\nin seconds!',
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white70,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),
                    // Action Buttons with glassmorphism effect
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          CustomButton(
                            text: 'Generate QR Code',
                            icon: Icons.qr_code,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QRGeneratorScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          CustomButton(
                            text: 'Scan QR Code',
                            icon: Icons.qr_code_scanner,
                            backgroundColor: AppTheme.lightPurple,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QRScannerScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          CustomButton(
                            text: 'Chat History',
                            icon: Icons.history,
                            backgroundColor: AppTheme.darkPurple,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatHistoryScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          CustomButton(
                            text: '🔥 Test Firebase',
                            icon: Icons.cloud_circle,
                            backgroundColor: AppTheme.accentPurple,
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '🔄 Testing Firebase connection...',
                                  ),
                                ),
                              );

                              await testFirebaseConnectionUI(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 36),
                    // Info Text
                    Text(
                      'Start a conversation by generating a QR code or scanning one from another device',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
