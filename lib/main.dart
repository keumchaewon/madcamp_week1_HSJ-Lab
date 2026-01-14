import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import './ui/screens/onboarding/onboarding_flow.dart';
import './ui/screens/feed_screen.dart';
import './ui/screens/login_google.dart';
import './ui/screens/my_page_screen.dart';
import 'state/app_state.dart';
import 'data/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      appState: _appState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SingASong',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routes: {
          '/home': (_) => const AppShell(),
        },
        home: const AuthGate(),
      ),
    );
  }
}

/* =========================
   AuthGate (진입 제어)
========================= */

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _authSub;
  String? _initializedUid;
  User? _currentUser;
  bool _authReady = false;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;
      setState(() {
        _authReady = true;
        _currentUser = user;
      });

      final appState = AppStateScope.of(context);
      if (user == null) {
        if (_initializedUid == null) return;
        _initializedUid = null;
        appState.clearUser();
        return;
      }

      if (_initializedUid != user.uid) {
        _initializedUid = user.uid;
        await _initializeUser(appState, user.uid);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_authReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser != null) {
      return const AppEntry();
    }

    return const LoginGoogle();
  }

  Future<void> _initializeUser(AppState appState, String uid) async {
    final service = UserService();

    await appState.setUser(uid);
    await service.ensureUserDoc(uid);
    final data = await service.getUser(uid);

    if (data != null) {
      appState.applyRemoteUser(
        username: (data['username'] as String?) ?? '',
        selectedGenres: List<String>.from(data['selectedGenres'] ?? const []),
        onboardingCompleted: data['onboardingCompleted'] == true,
      );
    } else {
      appState.applyRemoteUser(
        username: '',
        selectedGenres: const [],
        onboardingCompleted: false,
      );
    }
  }
}

/* =========================
   App Entry
========================= */

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        if (!appState.onboardingLoaded ||
            appState.onboardingUid != appState.uid) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return appState.onboardingCompleted
            ? const AppShell()
            : const OnboardingFlow();
      },
    );
  }
}

/* =========================
   App Shell
========================= */

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [FeedScreen(), MyPageScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person), label: 'My Page'),
        ],
      ),
    );
  }
}
