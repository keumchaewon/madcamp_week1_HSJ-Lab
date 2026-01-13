import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../state/app_state.dart';
import 'onboarding_genre_screen.dart';
import 'onboarding_id_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const List<String> _blockedNames = <String>['admin', 'test'];
  static final RegExp _idRegex = RegExp(r'^[a-zA-Z0-9_]{3,15}$');

  final Map<String, List<String>> _genreExamples = <String, List<String>>{
    'Pop': <String>[
      'Down Bad - Taylor Swift',
      'Levitating - Dua Lipa',
      'Flowers - Miley Cyrus',
    ],
    'Hip-hop': <String>[
      'HUMBLE. - Kendrick Lamar',
      'SICKO MODE - Travis Scott',
      'God\'s Plan - Drake',
    ],
    'R&B': <String>[
      'Love Galore - SZA',
      'Best Part - Daniel Caesar',
      'Talk - Khalid',
    ],
    'Rock': <String>[
      'Mr. Brightside - The Killers',
      'Bohemian Rhapsody - Queen',
      'Smells Like Teen Spirit - Nirvana',
    ],
    'Indie': <String>[
      'Sweater Weather - The Neighbourhood',
      'Cherry Wine - Hozier',
      'Electric Feel - MGMT',
    ],
    'EDM': <String>['Titanium - David Guetta', 'Stay - Zedd', 'Clarity - Zedd'],
    'Jazz': <String>[
      'Take Five - Dave Brubeck',
      'So What - Miles Davis',
      'My Favorite Things - John Coltrane',
    ],
    'Classical': <String>[
      'Clair de Lune - Debussy',
      'Nocturne Op.9 No.2 - Chopin',
      'Symphony No.5 - Beethoven',
    ],
    'K-pop': <String>[
      'Super Shy - NewJeans',
      'Seven - Jung Kook',
      'Ditto - NewJeans',
    ],
  };

  int _stepIndex = 0;
  String _username = '';
  final List<String> _selectedGenres = <String>[];

  bool get _isUsernameValid {
    if (!_idRegex.hasMatch(_username)) {
      return false;
    }
    return !_blockedNames.contains(_username.toLowerCase());
  }

  String? get _usernameError {
    if (_username.isEmpty) {
      return null;
    }
    if (_username.length < 3 || _username.length > 15) {
      return '3~15자 영문/숫자/언더스코어만 사용 가능해요.';
    }
    if (!_idRegex.hasMatch(_username)) {
      return '영문, 숫자, 언더스코어만 사용할 수 있어요.';
    }
    if (_blockedNames.contains(_username.toLowerCase())) {
      return '사용할 수 없는 아이디예요.';
    }
    return null;
  }

  bool get _isGenreValid => _selectedGenres.length >= 2;

  void _updateUsername(String value) {
    String nextValue = value.trim();
    if (nextValue.startsWith('@')) {
      nextValue = nextValue.substring(1);
    }
    setState(() {
      _username = nextValue;
    });
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  Future<void> _finishOnboarding() async {
    final AppState appState = AppStateScope.of(context);

    // 1. Firestore 업데이트
    await FirebaseFirestore.instance.collection('users').doc(appState.uid).set({
      'username': _username,
      'selectedGenres': _selectedGenres,
      'onboardingCompleted': true,
    }, SetOptions(merge: true));

    // 2.AppState 즉시 반영 (이게 제일 중요)
    appState.onboarding.complete(
      username: _username,
      selectedGenres: _selectedGenres,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = _stepIndex == 0 ? '아이디 설정' : '좋아하는 음악 스타일';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(title),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _stepIndex == 0
                ? OnboardingIdScreen(
                    key: const ValueKey('onboarding-id'),
                    username: _username,
                    errorText: _usernameError,
                    isValid: _isUsernameValid,
                    onChanged: _updateUsername,
                    onNext: () {
                      setState(() {
                        _stepIndex = 1;
                      });
                    },
                  )
                : OnboardingGenreScreen(
                    key: const ValueKey('onboarding-genre'),
                    genres: _genreExamples.keys.toList(),
                    selectedGenres: _selectedGenres,
                    genreExamples: _genreExamples,
                    isValid: _isGenreValid,
                    onToggleGenre: _toggleGenre,
                    onFinish: _finishOnboarding,
                  ),
          ),
        ),
      ),
    );
  }
}
