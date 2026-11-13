import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../core/store.dart';
import '../firebase_options.dart';

class AppUser {
  const AppUser({required this.id, required this.name, required this.email});
  final String id, name, email;
}

/// Firebase configured ho to real auth, warna local (offline) auth.
class AuthController extends ChangeNotifier {
  AppUser? user;
  String? error;
  bool ready = false;
  bool useFirebase = false;
  StreamSubscription<fb.User?>? _sub;

  Future<void> init() async {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      useFirebase = true;
    } catch (_) {
      useFirebase = false;
    }

    if (useFirebase) {
      _sub = fb.FirebaseAuth.instance.authStateChanges().listen((u) {
        if (u != null) {
          user = _fromFb(u);
        } else if (user?.id != 'guest') {
          user = null;
        }
        ready = true;
        notifyListeners();
      });
    } else {
      final s = Store.read('session');
      if (s != null) {
        final j = jsonDecode(s);
        user = AppUser(id: j['id'], name: j['name'], email: j['email']);
      }
      ready = true;
      notifyListeners();
    }
  }

  AppUser _fromFb(fb.User u) {
    final email = u.email ?? '';
    final name = (u.displayName?.trim().isNotEmpty ?? false)
        ? u.displayName!
        : (email.isNotEmpty ? email.split('@').first : 'User');
    return AppUser(id: u.uid, name: name, email: email);
  }

  // ---------- Firebase helpers ----------
  String _msg(String c) => switch (c) {
    'email-already-in-use' => 'Yeh email pehle se registered hai',
    'invalid-email' => 'Email sahi nahi hai',
    'weak-password' => 'Password kamzor hai (min 6)',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' =>
    'Email ya password ghalat hai',
    'too-many-requests' => 'Bohat attempts, thori der baad try karein',
    'network-request-failed' => 'Internet check karein',
    _ => 'Login fail ($c)',
  };

  Future<bool> _fb(Future<void> Function() fn) async {
    try {
      await fn();
      error = null;
      return true;
    } on fb.FirebaseAuthException catch (e) {
      error = _msg(e.code);
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
    return false;
  }

  // ---------- Local helpers ----------
  Map<String, dynamic> _users() {
    final raw = Store.read('users');
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw));
  }

  String _hash(String e, String p) =>
      sha256.convert(utf8.encode('$e:$p')).toString();

  Future<void> _start(AppUser u) async {
    user = u;
    error = null;
    await Store.write(
        'session', jsonEncode({'id': u.id, 'name': u.name, 'email': u.email}));
    notifyListeners();
  }

  // ---------- Public API ----------
  Future<bool> signUp(String name, String email, String pass) async {
    if (useFirebase) {
      return _fb(() async {
        final c = await fb.FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email.trim(), password: pass);
        await c.user?.updateDisplayName(name.trim());
        await c.user?.reload();
        final u = fb.FirebaseAuth.instance.currentUser;
        if (u != null) {
          user = _fromFb(u);
          notifyListeners();
        }
      });
    }
    email = email.trim().toLowerCase();
    final users = _users();
    if (users.containsKey(email)) {
      error = 'Yeh email pehle se registered hai';
      notifyListeners();
      return false;
    }
    users[email] = {'name': name.trim(), 'hash': _hash(email, pass)};
    await Store.write('users', jsonEncode(users));
    await _start(AppUser(id: email, name: name.trim(), email: email));
    return true;
  }

  Future<bool> signIn(String email, String pass) async {
    if (useFirebase) {
      return _fb(() => fb.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: pass));
    }
    email = email.trim().toLowerCase();
    final u = _users()[email];
    if (u == null || u['hash'] != _hash(email, pass)) {
      error = 'Email ya password ghalat hai';
      notifyListeners();
      return false;
    }
    await _start(AppUser(id: email, name: u['name'], email: email));
    return true;
  }

  Future<bool> signInWithGoogle() {
    if (!useFirebase) {
      error = 'Google login ke liye pehle Firebase configure karein';
      notifyListeners();
      return Future.value(false);
    }
    return _fb(() async {
      final p = fb.GoogleAuthProvider();
      if (kIsWeb) {
        await fb.FirebaseAuth.instance.signInWithPopup(p);
      } else {
        await fb.FirebaseAuth.instance.signInWithProvider(p);
      }
    });
  }

  Future<bool> resetPassword(String email, {String? newPass}) async {
    if (useFirebase) {
      return _fb(() => fb.FirebaseAuth.instance
          .sendPasswordResetEmail(email: email.trim()));
    }
    email = email.trim().toLowerCase();
    final users = _users();
    if (!users.containsKey(email) || newPass == null) return false;
    users[email]['hash'] = _hash(email, newPass);
    await Store.write('users', jsonEncode(users));
    return true;
  }

  Future<void> guest() =>
      _start(const AppUser(id: 'guest', name: 'Guest', email: ''));

  Future<void> signOut() async {
    if (useFirebase) {
      try {
        await fb.FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    user = null;
    await Store.remove('session');
    notifyListeners();
  }

  void clearError() => error = null;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}