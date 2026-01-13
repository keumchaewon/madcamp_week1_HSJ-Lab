import 'package:flutter/material.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final List<TimelineEntry> _items = [
    TimelineEntry(
      id: '1',
      title: 'Here Comes The Sun',
      artist: 'The Beatles',
      date: DateTime(2025, 6, 20),
      memo: '가족과 함께 떠난 제주도 여행, 아침 해변을 걸으며 들었던 곡.',
      imageUrl:
          'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=800&q=80',
    ),
    TimelineEntry(
      id: '2',
      title: 'Someone Like You',
      artist: 'Adele',
      date: DateTime(2024, 2, 14),
      memo: '작은 카페에서 혼자 들었던 밤의 기억.',
      imageUrl:
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=800&q=80',
    ),
    TimelineEntry(
      id: '3',
      title: 'Bohemian Rhapsody',
      artist: 'Queen',
      date: DateTime(2023, 7, 15),
      memo: '',
      imageUrl:
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?auto=format&fit=crop&w=800&q=80',
    ),
  ];

  List<TimelineEntry> get _sortedItems {
    final items = [..._items];
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<void> _openEntryEditor({TimelineEntry? entry}) async {
    final titleController = TextEditingController(text: entry?.title ?? '');
    final artistController = TextEditingController(text: entry?.artist ?? '');
    final memoController = TextEditingController(text: entry?.memo ?? '');
    final dateController = TextEditingController(
      text: entry?.date == null ? '' : _formatDate(entry!.date),
    );
    DateTime? selectedDate = entry?.date;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF9B5DE5), Color(0xFFFF6FAE)],
                            ),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry == null ? '타임라인에 곡 추가' : '타임라인 수정',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: '곡 제목',
                      child: TextField(
                        controller: titleController,
                        decoration: _inputDecoration('예: Bohemian Rhapsody'),
                      ),
                    ),
                    _LabeledField(
                      label: '아티스트',
                      child: TextField(
                        controller: artistController,
                        decoration: _inputDecoration('예: Queen'),
                      ),
                    ),
                    _LabeledField(
                      label: '날짜',
                      child: TextField(
                        controller: dateController,
                        readOnly: true,
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? now,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(now.year + 3),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDate = picked;
                              dateController.text = _formatDate(picked);
                            });
                          }
                        },
                        decoration: _inputDecoration('연도. 월. 일.').copyWith(
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                    _LabeledField(
                      label: '추억 메모',
                      child: TextField(
                        controller: memoController,
                        minLines: 3,
                        maxLines: 4,
                        decoration: _inputDecoration(
                          '이 곡과 함께한 특별한 순간을 기록해보세요...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (titleController.text.trim().isEmpty ||
                                  artistController.text.trim().isEmpty ||
                                  selectedDate == null) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text('제목, 아티스트, 날짜를 입력해 주세요.'),
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                if (entry == null) {
                                  _items.add(
                                    TimelineEntry(
                                      id: DateTime.now()
                                          .millisecondsSinceEpoch
                                          .toString(),
                                      title: titleController.text.trim(),
                                      artist: artistController.text.trim(),
                                      date: selectedDate!,
                                      memo: memoController.text.trim(),
                                      imageUrl:
                                          'https://images.unsplash.com/photo-1453090927415-5f45085b65c0?auto=format&fit=crop&w=800&q=80',
                                    ),
                                  );
                                } else {
                                  entry
                                    ..title = titleController.text.trim()
                                    ..artist = artistController.text.trim()
                                    ..date = selectedDate!
                                    ..memo = memoController.text.trim();
                                }
                              });
                              Navigator.of(dialogContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                              backgroundColor: const Color(0xFF7C3AED),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(entry == null ? '추가' : '저장'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    artistController.dispose();
    memoController.dispose();
    dateController.dispose();
  }

  Future<void> _openDetail(TimelineEntry entry) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Center(
                        child: Text(
                          '곡 상세 정보',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                      splashRadius: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _DetailImage(url: entry.imageUrl),
                const SizedBox(height: 16),
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _IconText(
                  icon: Icons.music_note,
                  text: entry.artist,
                ),
                const SizedBox(height: 6),
                _IconText(
                  icon: Icons.calendar_today,
                  text: _formatDate(entry.date),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EEFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '추억 메모',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.memo.isEmpty ? '메모가 없어요.' : entry.memo,
                        style: const TextStyle(color: Color(0xFF4B5563)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await _openEntryEditor(entry: entry);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('수정'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              _TimelineHeader(
                onAdd: () => _openEntryEditor(),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _sortedItems.isEmpty
                    ? const Center(
                        child: Text(
                          '아직 타임라인에 추가된 곡이 없어요.',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _sortedItems.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = _sortedItems[index];
                          return _TimelineTile(
                            entry: item,
                            onTap: () => _openDetail(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimelineEntry {
  TimelineEntry({
    required this.id,
    required this.title,
    required this.artist,
    required this.date,
    required this.memo,
    required this.imageUrl,
  });

  final String id;
  String title;
  String artist;
  DateTime date;
  String memo;
  final String imageUrl;
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '나의 음악 타임라인',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '특별한 순간과 함께한 노래들',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          _GradientButton(label: '+ 추가', onTap: onAdd),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry, required this.onTap});

  final TimelineEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight( // 핵심: Row 높이를 자식 카드 높이에 맞춤
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch, // 핵심: 왼쪽 라인이 세로로 늘어날 수 있게
        children: [
          SizedBox(
            width: 28,
            child: Stack(
              fit: StackFit.expand, // 핵심: Stack 자체가 주어진 높이를 확실히 채움
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6C6FF),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                Align(
                  // top: 18 같은 절대값 대신 상대 위치로
                  alignment: const Alignment(-0.1, -0.6),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8B5CF6),
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
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _AlbumImage(url: entry.imageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // 안정성 강화
                        children: [
                          Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _IconText(
                            icon: Icons.music_note,
                            text: entry.artist,
                            color: const Color(0xFF6B7280),
                          ),
                          const SizedBox(height: 6),
                          _IconText(
                            icon: Icons.calendar_today,
                            text: _formatDate(entry.date),
                            color: const Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return _ImagePlaceholder(width: 64, height: 64);
        },
        errorBuilder: (context, error, stackTrace) {
          return _ImagePlaceholder(width: 64, height: 64);
        },
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        url,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return const _ImagePlaceholder(width: double.infinity, height: 220);
        },
        errorBuilder: (context, error, stackTrace) {
          return const _ImagePlaceholder(width: double.infinity, height: 220);
        },
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFEDE7FF),
      child: const Icon(Icons.music_note, color: Color(0xFF9CA3AF)),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color ?? const Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF5F3FF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
    ),
  );
}

String _formatDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${date.year}.${twoDigits(date.month)}.${twoDigits(date.day)}';
}
