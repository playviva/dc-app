import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A simple login screen that signs the user in anonymously.
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInAnonymously() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      final uid = cred.user?.uid;
      if (uid != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
        final doc = await userDoc.get();
        if (!doc.exists) {
          await userDoc.set({
            'displayName': '',
            'tags': [],
          });
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: _signInAnonymously,
                    child: const Text('Continue as Guest'),
                  ),
                ],
              ),
      ),
    );
  }
}
