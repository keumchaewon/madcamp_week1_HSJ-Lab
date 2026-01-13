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
    _appState = AppState(); // App 전체에서 단일 인스턴스
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
        home: const AuthGate(),
      ),
    );
  }
}

/* =========================
   AuthGate (핵심 수정)
========================= */

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _initializedUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          final appState = AppStateScope.of(context);

          // UID가 바뀔 때만 초기화 (중복 실행 방지)
          if (_initializedUid != user.uid) {
            _initializedUid = user.uid;
            _initializeUser(appState, user.uid);
          }

          return const AppEntry();
        }

        _initializedUid = null;
        return const LoginGoogle();
      },
    );
  }

  Future<void> _initializeUser(AppState appState, String uid) async {
    final service = UserService();

    await appState.setUser(uid);
    await service.ensureUserDoc(uid);
    final data = await service.getUser(uid);

    if (data != null && data['username'] != null) {
      appState.applyRemoteUser(
        username: data['username'],
        selectedGenres: List<String>.from(data['selectedGenres'] ?? const []),
        onboardingCompleted: true,
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
