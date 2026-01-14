import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final List<TimelineEntry> _items = [];

  List<TimelineEntry> get _sortedItems {
    final items = [..._items];
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<void> _openEntryEditor({TimelineEntry? entry}) async {
    final tracks = AppStateScope.of(context).tracks;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _TimelineEditorDialog(
          entry: entry,
          tracks: tracks,
          onSave: (selectedTrack, date, memo) {
            setState(() {
              if (entry == null) {
                _items.add(
                  TimelineEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    trackId: selectedTrack.id,
                    title: selectedTrack.title,
                    artist: selectedTrack.artist,
                    date: date,
                    memo: memo,
                    imageUrl: selectedTrack.albumImage,
                  ),
                );
              } else {
                entry
                  ..trackId = selectedTrack.id
                  ..title = selectedTrack.title
                  ..artist = selectedTrack.artist
                  ..date = date
                  ..memo = memo
                  ..imageUrl = selectedTrack.albumImage;
              }
            });
          },
        );
      },
    );
  }

  Future<void> _openDetail(TimelineEntry entry) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
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
                _IconText(icon: Icons.music_note, text: entry.artist),
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
                        entry.memo.isEmpty ? '빈 메모' : entry.memo,
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
      backgroundColor: const Color(0xFFF8F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              _TimelineHeader(onAdd: () => _openEntryEditor()),
              const SizedBox(height: 20),
              Expanded(
                child: _sortedItems.isEmpty
                    ? const Center(
                        child: Text(
                          '나만의 음악 추가하기',
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _sortedItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
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
    required this.trackId,
    required this.title,
    required this.artist,
    required this.date,
    required this.memo,
    required this.imageUrl,
  });

  final String id;
  String? trackId;
  String title;
  String artist;
  DateTime date;
  String memo;
  String imageUrl;
}

class _TimelineEditorDialog extends StatefulWidget {
  const _TimelineEditorDialog({
    this.entry,
    required this.tracks,
    required this.onSave,
  });

  final TimelineEntry? entry;
  final List<Track> tracks;
  final void Function(Track track, DateTime date, String memo) onSave;

  @override
  State<_TimelineEditorDialog> createState() => _TimelineEditorDialogState();
}

class _TimelineEditorDialogState extends State<_TimelineEditorDialog> {
  late final TextEditingController memoController;
  late final TextEditingController dateController;
  DateTime? selectedDate;
  Track? selectedTrack;

  @override
  void initState() {
    super.initState();
    memoController = TextEditingController(text: widget.entry?.memo ?? '');
    selectedDate = widget.entry?.date;
    dateController = TextEditingController(
      text: selectedDate == null ? '' : _formatDate(selectedDate!),
    );
    if (widget.entry?.trackId != null) {
      for (final track in widget.tracks) {
        if (track.id == widget.entry!.trackId) {
          selectedTrack = track;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    memoController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final size = MediaQuery.of(context).size;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: size.height * 0.85),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + viewInsets.bottom),
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
                      color: Color(0xFFE7D8FF),
                    ),
                    child: const Icon(Icons.add, color: Color(0xFF6D28D9)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry == null ? '곡 정보 추가' : '곡 정보 수정',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: '곡 선택',
                child: _TrackSelector(
                  track: selectedTrack,
                  onTap: () async {
                    final picked = await showModalBottomSheet<Track>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _TrackPickerSheet(
                        tracks: widget.tracks,
                        selectedId: selectedTrack?.id,
                      ),
                    );
                    if (picked == null) return;
                    setState(() {
                      selectedTrack = picked;
                    });
                  },
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
                      setState(() {
                        selectedDate = picked;
                        dateController.text = _formatDate(picked);
                      });
                    }
                  },
                  decoration: _inputDecoration(
                    'YYYY.MM.DD',
                  ).copyWith(suffixIcon: const Icon(Icons.calendar_today)),
                ),
              ),
              _LabeledField(
                label: '추억 메모',
                child: TextField(
                  controller: memoController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: _inputDecoration('이 곡과 함께한 특별한 순간을 기록해보세요.'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        foregroundColor: const Color(0xFF1F2937),
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                        if (selectedTrack == null || selectedDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '곡과 날짜를 선택해주세요',
                              ),
                            ),
                          );
                          return;
                        }
                        widget.onSave(
                          selectedTrack!,
                          selectedDate!,
                          memoController.text.trim(),
                        );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
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
      ),
    );
  }
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
              color: Color(0xFFE7D8FF),
            ),
            child: const Icon(
              Icons.music_note,
              color: Color(0xFF6D28D9),
              size: 28,
            ),
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
                    color: Color(0xFF5B21B6),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '특별한 순간과 함께한 노래들',
                ),
              ],
            ),
          ),
          _GradientButton(label: '추가', onTap: onAdd),
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
    return IntrinsicHeight(
      // ?듭떖: Row ?믪씠瑜??먯떇 移대뱶 ?믪씠??留욎땄
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // ?듭떖: ?쇱そ ?쇱씤???몃줈濡??섏뼱?????덇쾶
        children: [
          SizedBox(
            width: 28,
            child: Stack(
              fit: StackFit.expand, // ?듭떖: Stack ?먯껜媛 二쇱뼱吏??믪씠瑜??뺤떎??梨꾩?
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
                  // top: 18 媛숈? ?덈?媛?????곷? ?꾩튂濡?
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
                        mainAxisSize: MainAxisSize.min,
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
        color: const Color(0xFF7C3AED),
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
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

class _TrackSelector extends StatelessWidget {
  const _TrackSelector({required this.track, required this.onTap});

  final Track? track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.music_note,
                color: Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: track == null
                  ? const Text(
                      '곡을 선택해주세요',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track!.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.search, color: Color(0xFF7C3AED)),
          ],
        ),
      ),
    );
  }
}

class _TrackPickerSheet extends StatefulWidget {
  const _TrackPickerSheet({
    required this.tracks,
    required this.selectedId,
  });

  final List<Track> tracks;
  final String? selectedId;

  @override
  State<_TrackPickerSheet> createState() => _TrackPickerSheetState();
}

class _TrackPickerSheetState extends State<_TrackPickerSheet> {
  final TextEditingController _controller = TextEditingController();
  List<Track> _results = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleQueryChanged);
    _results = widget.tracks;
  }

  @override
  void dispose() {
    _controller.removeListener(_handleQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    final query = _controller.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _results = widget.tracks;
      } else {
        _results = widget.tracks.where((track) {
          return track.title.toLowerCase().contains(query) ||
              track.artist.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: '곡 또는 아티스트 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_results.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '검색 결과가 없어요',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final track = _results[index];
                    final bool isSelected = track.id == widget.selectedId;
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          track.albumImage,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(track.title),
                      subtitle: Text(track.artist),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF7C3AED))
                          : null,
                      onTap: () => Navigator.of(context).pop(track),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
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
