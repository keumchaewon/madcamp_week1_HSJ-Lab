import 'package:flutter/material.dart';

import '../screens/playlists/playlists_screen.dart';
import '../../state/app_state.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  static const int _posts = 5;
  static const int _followers = 6;
  static const int _following = 87;

  @override
  Widget build(BuildContext context) {
    const double padding = 16;
    const double radius = 16;

    final AppState appState = AppStateScope.of(context);
    final String username = appState.onboarding.username.isEmpty
        ? 'guest'
        : appState.onboarding.username;
    final List<String> genres = appState.onboarding.selectedGenres;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(padding, 16, padding, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 44,
                    backgroundColor: Color(0xFFF1F3F6),
                    child: Icon(Icons.person, size: 44, color: Colors.black54),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _StatItem(label: 'posts', value: _posts),
                        _StatItem(label: 'followers', value: _followers),
                        _StatItem(label: 'following', value: _following),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '@$username',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 96,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F5F7),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: const Center(
                  child: Text(
                    'Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '좋아하는 장르',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (genres.isEmpty)
                const Text(
                  '아직 선택한 장르가 없어요.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: genres
                      .map(
                        (genre) => Chip(
                          label: Text(genre),
                          backgroundColor: const Color(0xFFF1F5F9),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 24),
              const Text(
                'Playlists',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const PlaylistsGrid(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
