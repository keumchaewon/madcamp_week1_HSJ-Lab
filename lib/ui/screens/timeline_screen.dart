import 'package:flutter/material.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  static final List<TimelineItem> _items = [
    TimelineItem(
      title: 'Here Comes The Sun',
      artist: 'The Beatles',
      imageUrl:
          'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=300&q=80',
      date: DateTime(2025, 6, 20),
      canEdit: false,
    ),
    TimelineItem(
      title: 'Someone Like You',
      artist: 'Adele',
      imageUrl:
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=300&q=80',
      date: DateTime(2024, 2, 14),
      canEdit: true,
    ),
    TimelineItem(
      title: 'Bohemian Rhapsody',
      artist: 'Queen',
      imageUrl:
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?auto=format&fit=crop&w=300&q=80',
      date: DateTime(2023, 7, 15),
      canEdit: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F1FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              TimelineHeader(
                onAdd: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('추가')),
                  );
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TimelineList(items: _items),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimelineHeader extends StatelessWidget {
  const TimelineHeader({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF9B5DE5), Color(0xFFFF6FAE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '나의 음악 타임라인',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  '특별한 순간과 함께한 노래들',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          _GradientButton(
            label: '+ 추가',
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class TimelineList extends StatelessWidget {
  const TimelineList({super.key, required this.items});

  final List<TimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return TimelineTile(item: items[index]);
      },
    );
  }
}

class TimelineTile extends StatelessWidget {
  const TimelineTile({super.key, required this.item});

  final TimelineItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF9B5DE5), Color(0xFFFF6FAE)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                left: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9B5DE5), Color(0xFFFF6FAE)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TimelineCard(item: item),
        ),
      ],
    );
  }
}

class TimelineCard extends StatelessWidget {
  const TimelineCard({super.key, required this.item});

  final TimelineItem item;

  @override
  Widget build(BuildContext context) {
    final bool canEdit = item.canEdit;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(right: canEdit ? 56 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AlbumImage(url: item.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.music_note, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(item.date),
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (canEdit)
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('수정: ${item.title}')),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    color: const Color(0xFFEF4444),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('삭제: ${item.title}')),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AlbumImage extends StatelessWidget {
  const _AlbumImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            width: 64,
            height: 64,
            color: const Color(0xFFE5E7EB),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 64,
            height: 64,
            color: const Color(0xFFE5E7EB),
            child: const Icon(Icons.music_note, color: Color(0xFF9CA3AF)),
          );
        },
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9B5DE5), Color(0xFFFF6FAE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TimelineItem {
  const TimelineItem({
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.date,
    required this.canEdit,
  });

  final String title;
  final String artist;
  final String imageUrl;
  final DateTime date;
  final bool canEdit;
}

String _formatDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${date.year}.${twoDigits(date.month)}.${twoDigits(date.day)}';
}
