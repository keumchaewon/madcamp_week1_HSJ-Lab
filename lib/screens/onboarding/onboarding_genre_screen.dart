import 'package:flutter/material.dart';

class OnboardingGenreScreen extends StatelessWidget {
  const OnboardingGenreScreen({
    super.key,
    required this.genres,
    required this.selectedGenres,
    required this.genreExamples,
    required this.isValid,
    required this.onToggleGenre,
    required this.onFinish,
  });

  final List<String> genres;
  final List<String> selectedGenres;
  final Map<String, List<String>> genreExamples;
  final bool isValid;
  final ValueChanged<String> onToggleGenre;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pick your vibe',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '최소 2개 이상 선택해주세요. (${selectedGenres.length}/2)',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genres
              .map(
                (genre) => FilterChip(
                  label: Text(genre),
                  selected: selectedGenres.contains(genre),
                  onSelected: (_) => onToggleGenre(genre),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        if (selectedGenres.isNotEmpty)
          Expanded(
            child: ListView.separated(
              itemCount: selectedGenres.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final String genre = selectedGenres[index];
                final List<String> tracks =
                    genreExamples[genre] ?? <String>[];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$genre 예시',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...tracks.map(
                        (track) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '• $track',
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text(
                '장르를 선택하면 예시 곡이 보여요.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isValid ? onFinish : null,
            child: const Text('Finish'),
          ),
        ),
      ],
    );
  }
}
